import "dart:convert";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocalizationService {
  static const String _languageKey = "selected_language";
  static const String _defaultLanguage = "en";
  
  Map<String, dynamic> _localizedStrings = {};
  String _currentLanguage = _defaultLanguage;
  VoidCallback? _onLanguageChanged;
  
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  void setOnLanguageChangedCallback(VoidCallback? callback) {
    _onLanguageChanged = callback;
  }

  String get currentLanguage => _currentLanguage;

  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedLanguage = prefs.getString(_languageKey);
    final String languageToLoad = savedLanguage ?? _defaultLanguage;
    await loadLanguage(languageToLoad);
  }

  Future<void> loadLanguage(String languageCode) async {
    try {
      final String jsonString = await rootBundle.loadString(
        "assets/translations/$languageCode.json",
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      
      _localizedStrings = jsonMap;
      _currentLanguage = languageCode;
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      if (_onLanguageChanged != null) {
        _onLanguageChanged!();
      }
    } catch (e) {
      debugPrint("Error loading language file: $e");
      if (languageCode != _defaultLanguage) {
        await loadLanguage(_defaultLanguage);
      }
    }
  }
  
  String translate(String key) {
    if (_localizedStrings.isEmpty) {
      return key;
    }
    
    final List<String> keys = key.split(".");
    dynamic value = _localizedStrings;
    
    for (final String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }
    
    if (value is String) {
      return value;
    }
    
    return key;
  }

  String translateWithParams(String key, Map<String, String> params) {
    String translated = translate(key);
    
    params.forEach((String paramKey, String paramValue) {
      translated = translated.replaceAll("{{$paramKey}}", paramValue);
    });
    
    return translated;
  }
}

extension LocalizationExtension on String {
  String get tr => LocalizationService().translate(this);
}
