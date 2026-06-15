import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../login/pages/login_page.dart';
import '../../../screens/home_screen.dart';

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
        Get.offAll(() => HomeScreen(token: token));
      } else {
        Get.offAll(() => const LoginPage());
      }
    });
  }
}
