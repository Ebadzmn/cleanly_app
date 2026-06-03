import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restart_app/restart_app.dart';
import '../../../../services/localization_service.dart';

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
      return;
    }

    await LocalizationService().loadLanguage(languageCode);
    
    currentLanguage.value = languageCode;
    
    Get.snackbar(
      "Success",
      languageCode == "en"
          ? "Language changed to English"
          : "Idioma cambiado a Español",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    Restart.restartApp();
  }
}
