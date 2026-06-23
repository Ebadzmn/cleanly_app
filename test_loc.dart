import 'dart:convert';
import 'dart:io';

void main() {
  final jsonString = File('assets/translations/en.json').readAsStringSync();
  final _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;

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

  print("home.jobs: " + translate("home.jobs"));
  print("home.goodMorning: " + translate("home.goodMorning"));
  print("jobs.date: " + translate("jobs.date"));
}
