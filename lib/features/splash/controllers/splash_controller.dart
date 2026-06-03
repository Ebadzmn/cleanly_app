import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      if (token != null && token.isNotEmpty) {
        Get.offAll(() => HomeScreen(token: token));
      } else {
        Get.offAll(() => const LoginPage());
      }
    });
  }
}
