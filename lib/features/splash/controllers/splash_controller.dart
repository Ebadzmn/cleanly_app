import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../login/pages/login_page.dart';
import '../../../screens/home_screen.dart';
import '../../../config/api_config.dart';
import '../../../services/localization_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 3), () async {
      const secureStorage = FlutterSecureStorage();
      String? token = await secureStorage.read(key: "auth_token");
      
      if (token != null && token.isNotEmpty) {
        await _fetchProfileAndSetLanguage(token);
        Get.offAll(() => HomeScreen(token: token));
      } else {
        Get.offAll(() => const LoginPage());
      }
    });
  }

  Future<void> _fetchProfileAndSetLanguage(String token) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl("/api/cleaners/profile"));
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final data = responseData.containsKey("data") && responseData["data"] is Map 
            ? responseData["data"] as Map<String, dynamic> 
            : responseData;

        final cleanFlowLanguage = data["cleanFlowLanguage"]?.toString();
        if (cleanFlowLanguage != null) {
          if (cleanFlowLanguage.toLowerCase() == "spanish") {
            await LocalizationService().loadLanguage("es");
          } else if (cleanFlowLanguage.toLowerCase() == "english") {
            await LocalizationService().loadLanguage("en");
          }
        }
      }
    } catch (e) {
      print("Error fetching profile on app start: $e");
    }
  }
}
