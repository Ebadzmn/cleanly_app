import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../splash/pages/splash_page.dart';
import '../../splash/controllers/splash_controller.dart';

class LanguageController extends GetxController {
  RxString currentLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    currentLanguage.value = LocalizationService().currentLanguage;
  }

  Future<void> selectLanguage(String languageCode) async {
    if (currentLanguage.value == languageCode) {
      Get.back();
      return;
    }

    // 1. Immediately load local language strings in memory
    await LocalizationService().loadLanguage(languageCode);
    currentLanguage.value = languageCode;

    // 2. Sync to backend asynchronously in background (non-blocking)
    _syncLanguageWithBackend(languageCode);

    // 3. Immediately close language screen without waiting
    Get.back();

    // 4. Show success snackbar on the destination screen
    Get.snackbar(
      LocalizationService().translate("common.success") ?? "Success",
      languageCode == "en"
          ? "Language changed to English"
          : "Idioma cambiado a Español",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _syncLanguageWithBackend(String languageCode) async {
    try {
      const secureStorage = FlutterSecureStorage();
      String? token = await secureStorage.read(key: "auth_token");
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString("token");
      }
      if (token != null && token.isNotEmpty) {
        final url = Uri.parse(ApiConfig.buildUrl("/api/cleaners/profile"));
        await http.patch(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"cleanFlowLanguage": languageCode == "es" ? "spanish" : "english"}),
        );
      }
    } catch (e) {
      debugPrint("Error updating language on backend: $e");
    }
  }
}
