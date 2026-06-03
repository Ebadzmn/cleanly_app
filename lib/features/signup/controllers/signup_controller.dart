import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../login/pages/login_page.dart';

class SignupController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController reEnterPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  var obscurePassword = true.obs;
  var obscureReEnterPassword = true.obs;
  var isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    reEnterPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleReEnterPasswordVisibility() {
    obscureReEnterPassword.value = !obscureReEnterPassword.value;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  void handleGetStarted() {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        reEnterPasswordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty) {
      Get.snackbar(
        LocalizationService().translate("common.error") ?? "Error",
        LocalizationService().translate("login.fillAllFields") ?? "Please fill all fields",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (passwordController.text != reEnterPasswordController.text) {
      Get.snackbar(
        LocalizationService().translate("common.error") ?? "Error",
        LocalizationService().translate("signup.passwordsDoNotMatch") ?? "Passwords do not match",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!_isValidEmail(emailController.text)) {
      Get.snackbar(
        LocalizationService().translate("common.error") ?? "Error",
        LocalizationService().translate("signup.pleaseEnterValidEmail") ?? "Please enter a valid email",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _registerUser();
  }

  Future<void> _registerUser() async {
    isLoading.value = true;
    final url = Uri.parse(ApiConfig.buildUrl("/register"));

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
        },
        body: {
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "confirm_password": reEnterPasswordController.text,
          "first_name": firstNameController.text.trim(),
          "last_name": lastNameController.text.trim(),
        },
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.headers["content-type"]?.contains("application/json") != true) {
        throw Exception("Server returned non-JSON response. Status: ${response.statusCode}.");
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data.containsKey("token") && data.containsKey("user")) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", data["token"] as String);
          await prefs.setInt("id", data["user"]["id"] as int);
          await prefs.setString("role", (data["user"]["role"] ?? "").toString());
          await prefs.setString("phone", (data["user"]["phone"] ?? "").toString());
          await prefs.setString("isBusiness", (data["user"]["is_business"] ?? "").toString());

          Get.offAll(() => const LoginPage());

          Get.snackbar(
            LocalizationService().translate("common.success") ?? "Success",
            LocalizationService().translate("signup.registrationSuccessful") ?? "Registration successful!",
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            LocalizationService().translate("common.success") ?? "Success",
            data["message"]?.toString() ?? "Registration successful! Please check your email.",
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAll(() => const LoginPage());
        }
      } else if (data.containsKey("errors")) {
        String messageList;
        if (data["errors"] is Map<String, dynamic>) {
          final errors = data["errors"] as Map<String, dynamic>;
          messageList = errors.values.expand((e) => e as List<dynamic>).map((e) => e.toString()).join("\n");
        } else if (data["errors"] is List) {
          final errors = data["errors"] as List<dynamic>;
          messageList = errors.map((e) => e.toString()).join("\n");
        } else {
          messageList = data["errors"].toString();
        }
        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          messageList,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          data["message"]?.toString() ?? "Registration failed. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e, stack) {
      debugPrint("error: $e");
      debugPrint("stack: $stack");
      Get.snackbar(
        LocalizationService().translate("common.error") ?? "Error",
        LocalizationService().translate("signup.unexpectedError") ?? "An unexpected error occurred",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
