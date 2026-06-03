import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../../screens/home_screen.dart';
import '../../../services/localization_service.dart';
import '../../../services/notification_service.dart';

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
        LocalizationService().translate("login.fillAllFields") ?? "Fill all fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    final url = Uri.parse(ApiConfig.buildUrl('/login'));

    try {
      String deviceToken = NotificationService().fcmToken ?? "";
      debugPrint("Device Token: $deviceToken");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "device_token": deviceToken,
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.headers['content-type']?.contains('application/json') != true) {
        throw Exception(
          'Server returned non-JSON response. Status: ${response.statusCode}. Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data.containsKey('token')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] as String);
        await prefs.setInt('id', data['user']['id'] as int);
        await prefs.setString('role', (data['user']['role'] ?? "").toString());
        await prefs.setString('phone', (data['user']['phone'] ?? "").toString());
        await prefs.setString('device_token', deviceToken);
        await prefs.setString('isBusiness', (data['user']["is_business"] ?? "").toString());

        if (rememberMe.value) {
          await _saveCredentials();
        } else {
          await _removeCredentials();
        }

        Get.offAll(() => HomeScreen(token: data['token']));

        Get.snackbar(
          LocalizationService().translate("common.success") ?? "Success",
          LocalizationService().translate("login.loginSuccessful") ?? "Login Successful",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else if (data.containsKey('errors')) {
        String messageList;
        if (data['errors'] is Map<String, dynamic>) {
          final errors = data['errors'] as Map<String, dynamic>;
          messageList = errors.values.expand((e) => e).map((e) => e.toString()).join('\n');
        } else if (data['errors'] is List) {
          final errors = data['errors'] as List<dynamic>;
          messageList = errors.map((e) => e.toString()).join('\n');
        } else {
          messageList = data['errors'].toString();
        }

        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          messageList,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          data["message"] ?? LocalizationService().translate("login.loginFailed") ?? "Login Failed",
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
        LocalizationService().translate("login.unexpectedError") ?? "Unexpected error",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
