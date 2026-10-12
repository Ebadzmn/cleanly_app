import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/localization_service.dart';
import '../services/on_device_translation_service.dart';

class AutoTranslateText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool toUpperCase;
  final TextAlign? textAlign;

  const AutoTranslateText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.toUpperCase = false,
    this.textAlign,
  });

  @override
  State<AutoTranslateText> createState() => _AutoTranslateTextState();
}

class _AutoTranslateTextState extends State<AutoTranslateText> {
  final OnDeviceTranslationService _translationService =
      OnDeviceTranslationService();

  String? _translatedText;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = LocalizationService().currentLanguage;
    LocalizationService().addListener(_onLanguageChanged);

    if (_currentLanguage.toLowerCase() == "es") {
      _translate();
    }
  }

  @override
  void didUpdateWidget(covariant AutoTranslateText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translatedText = null;
      if (_currentLanguage.toLowerCase() == "es") {
        _translate();
      }
    }
  }

  void _onLanguageChanged() {
    final newLang = LocalizationService().currentLanguage;
    if (newLang != _currentLanguage) {
      if (mounted) {
        setState(() {
          _currentLanguage = newLang;
        });
      }
      if (newLang.toLowerCase() == "es") {
        _translate();
      }
    }
  }

  Future<void> _translate() async {
    final trimmed = widget.text.trim();
    if (trimmed.isEmpty) return;

    try {
      final res = await _translationService.translate(
        text: trimmed,
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.spanish,
      );

      if (mounted && res.isNotEmpty) {
        setState(() {
          _translatedText = res;
        });
      }
    } catch (e) {
      debugPrint("AutoTranslateText error: $e");
    }
  }

  @override
  void dispose() {
    LocalizationService().removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpanish = _currentLanguage.toLowerCase() == "es";
    String displayText =
        (isSpanish && _translatedText != null && _translatedText!.isNotEmpty)
            ? _translatedText!
            : widget.text;

    if (widget.toUpperCase) {
      displayText = displayText.toUpperCase();
    }

    return Text(
      displayText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
