import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/api_config.dart';
import '../../../screens/home_screen.dart';
import '../../../services/localization_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/network_caller.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool rememberMe = false.obs;
  final RxBool obscurePassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRememberedCredentials();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleRememberMe(bool? value) {
    bool newValue = value ?? false;
    rememberMe.value = newValue;
    if (!newValue) {
      emailController.clear();
      passwordController.clear();
      _removeCredentials();
    } else {
      _saveCredentials();
    }
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isRemembered = prefs.getBool('remember_me') ?? false;
      String? savedEmail = prefs.getString('remembered_email');
      String? savedPassword = prefs.getString('remembered_password');

      rememberMe.value = isRemembered;
      if (isRemembered && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
      }
    } catch (e) {
      debugPrint("Error loading remembered credentials: $e");
    }
  }

  Future<void> _saveCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_email', emailController.text.trim());
      await prefs.setString('remembered_password', passwordController.text);
    } catch (e) {
      debugPrint("Error saving credentials: $e");
    }
  }

  Future<void> _removeCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', false);
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
    } catch (e) {
      debugPrint("Error removing credentials: $e");
    }
  }

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        LocalizationService().translate("common.error") ?? "Error",
        LocalizationService().translate("login.fillAllFields") ??
            "Fill all fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    final url = Uri.parse(ApiConfig.buildUrl('api/auth/login'));

    try {
      String deviceToken = NotificationService().fcmToken ?? "";
      debugPrint("Device Token: $deviceToken");

      final response = await NetworkCaller.post(
        url,
        body: json.encode({
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "deviceToken": deviceToken,
        }),
      );

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final responseData = data['data'];
          final token = responseData['token'];
          final user = responseData['user'];

          // Securely store token
          const secureStorage = FlutterSecureStorage();
          await secureStorage.write(key: 'auth_token', value: token);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token); // Needed for backwards compatibility
          await prefs.setString('id', user['id'].toString());
          await prefs.setString('role', (user['role'] ?? "").toString());
          await prefs.setString('phone', (user['phone'] ?? "").toString());
          await prefs.setString('email', (user['email'] ?? "").toString());
          await prefs.setString('name', (user['name'] ?? "").toString());
          await prefs.setString('device_token', deviceToken);

          if (rememberMe.value) {
            await _saveCredentials();
          } else {
            await _removeCredentials();
          }

          Get.offAll(() => HomeScreen(token: token));

          Get.snackbar(
            LocalizationService().translate("common.success") ?? "Success",
            data['message'] ??
                LocalizationService().translate("login.loginSuccessful") ??
                "Login Successful",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            LocalizationService().translate("common.error") ?? "Error",
            data?["message"] ??
                LocalizationService().translate("login.loginFailed") ??
                "Login Failed",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          response.message ??
              LocalizationService().translate("login.loginFailed") ??
              "Login Failed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e, stack) {
      debugPrint("error: $e");
      debugPrint("stack: $stack");
      Get.snackbar(
        LocalizationService().translate("common.error") ?? "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
