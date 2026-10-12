import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:cleanly_app/services/localization_service.dart';

class OnDeviceTranslationService {
  static final OnDeviceTranslationService _instance =
      OnDeviceTranslationService._internal();
  factory OnDeviceTranslationService() => _instance;
  OnDeviceTranslationService._internal();

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  OnDeviceTranslator? _enToEsTranslator;
  OnDeviceTranslator? _esToEnTranslator;

  // In-memory cache to prevent redundant translations
  final Map<String, String> _cache = {};

  bool _isDownloadingModel = false;
  bool get isDownloadingModel => _isDownloadingModel;

  /// Check if the target language model is downloaded.
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    try {
      return await _modelManager
          .isModelDownloaded(language.bcpCode)
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (e) {
      debugPrint("Error checking ML Kit model download: $e");
      return false;
    }
  }

  /// Download the model if not already downloaded.
  Future<bool> ensureModelDownloaded(TranslateLanguage language) async {
    try {
      final isDownloaded = await isModelDownloaded(language);
      if (isDownloaded) return true;

      _isDownloadingModel = true;
      // Note: isWifiRequired MUST be false so it doesn't block on cellular/emulator
      final success = await _modelManager
          .downloadModel(language.bcpCode, isWifiRequired: false)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
      _isDownloadingModel = false;
      return success;
    } catch (e) {
      _isDownloadingModel = false;
      debugPrint("Error downloading ML Kit model for ${language.bcpCode}: $e");
      return false;
    }
  }

  /// Proactively preload/download the Spanish model in the background
  Future<void> preloadSpanishModel() async {
    try {
      final downloaded = await isModelDownloaded(TranslateLanguage.spanish);
      if (!downloaded) {
        await ensureModelDownloaded(TranslateLanguage.spanish);
      }
    } catch (e) {
      debugPrint("Failed to preload Spanish model: $e");
    }
  }

  /// Translate dynamic text according to the app's current locale.
  Future<String> translateForCurrentLanguage(String text) async {
    final currentLang = LocalizationService().currentLanguage.toLowerCase();
    if (currentLang == "es") {
      return translate(
        text: text,
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.spanish,
      );
    }
    return text;
  }

  /// High-speed cloud translator using Google's translation endpoint.
  /// Returns translated text in ~100-200ms without needing 30MB model downloads.
  Future<String?> _translateViaFastApi({
    required String text,
    required String sourceBcp,
    required String targetBcp,
  }) async {
    try {
      final uri = Uri.parse(
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceBcp&tl=$targetBcp&dt=t&q=${Uri.encodeComponent(text)}",
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final buffer = StringBuffer();
          for (final item in decoded[0]) {
            if (item is List && item.isNotEmpty && item[0] != null) {
              buffer.write(item[0].toString());
            }
          }
          final translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint("Fast API translation error (will try ML Kit fallback): $e");
    }
    return null;
  }

  /// Translate text between specified languages.
  /// 1. Instant check from cache
  /// 2. Fast cloud translation (~150ms)
  /// 3. ML Kit on-device translation fallback
  Future<String> translate({
    required String text,
    TranslateLanguage sourceLanguage = TranslateLanguage.english,
    TranslateLanguage targetLanguage = TranslateLanguage.spanish,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    if (sourceLanguage == targetLanguage) return text;

    // Cache key based on source, target, and text
    final cacheKey =
        "${sourceLanguage.bcpCode}_${targetLanguage.bcpCode}_$trimmed";
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 1. Try fast instant API translation (super fast, no 30MB wait)
    final fastResult = await _translateViaFastApi(
      text: trimmed,
      sourceBcp: sourceLanguage.bcpCode,
      targetBcp: targetLanguage.bcpCode,
    );

    if (fastResult != null && fastResult.isNotEmpty) {
      _cache[cacheKey] = fastResult;
      return fastResult;
    }

    // 2. Fallback to ML Kit on-device translation
    try {
      OnDeviceTranslator translator;
      if (sourceLanguage == TranslateLanguage.english &&
          targetLanguage == TranslateLanguage.spanish) {
        if (_enToEsTranslator == null) {
          await ensureModelDownloaded(TranslateLanguage.spanish);
          _enToEsTranslator = OnDeviceTranslator(
            sourceLanguage: TranslateLanguage.english,
            targetLanguage: TranslateLanguage.spanish,
          );
        }
        translator = _enToEsTranslator!;
      } else if (sourceLanguage == TranslateLanguage.spanish &&
          targetLanguage == TranslateLanguage.english) {
        if (_esToEnTranslator == null) {
          await ensureModelDownloaded(TranslateLanguage.english);
          _esToEnTranslator = OnDeviceTranslator(
            sourceLanguage: TranslateLanguage.spanish,
            targetLanguage: TranslateLanguage.english,
          );
        }
        translator = _esToEnTranslator!;
      } else {
        await ensureModelDownloaded(targetLanguage);
        translator = OnDeviceTranslator(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );
      }

      final result = await translator
          .translateText(trimmed)
          .timeout(const Duration(seconds: 4));

      if (result.isNotEmpty) {
        _cache[cacheKey] = result;
        return result;
      }
    } catch (e) {
      debugPrint("ML Kit translation fallback error: $e");
    }

    // Return original text if all failed
    return text;
  }

  void dispose() {
    _enToEsTranslator?.close();
    _esToEnTranslator?.close();
    _enToEsTranslator = null;
    _esToEnTranslator = null;
  }
}
