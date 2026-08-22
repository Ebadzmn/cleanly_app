import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/network_caller.dart';
import '../../../../services/notification_service.dart';
import '../../login/pages/login_page.dart';
import '../../login/controllers/login_controller.dart';

class SignupController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController reEnterPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ssnController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  var selectedLanguage = "English".obs;
  var isContractor = true.obs;

  var obscurePassword = true.obs;
  var obscureReEnterPassword = true.obs;
  var isLoading = false.obs;
  var addressPredictions = <String>[].obs;
  var isFetchingAddress = false.obs;

  void fetchAddressPredictions(String query) async {
    if (query.trim().length < 3) {
      addressPredictions.clear();
      return;
    }
    isFetchingAddress.value = true;
    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5",
      );
      final response = await NetworkCaller.get(
        uri,
        headers: {
          "User-Agent": "CleanlyApp/1.0",
        },
      );
      if (response.isSuccess && response.data is List) {
        final List list = response.data;
        final results = list
            .map((item) => item["display_name"]?.toString() ?? "")
            .where((str) => str.isNotEmpty)
            .toList();
        addressPredictions.assignAll(results);
      } else {
        addressPredictions.clear();
      }
    } catch (e) {
      debugPrint("Error fetching address predictions: $e");
      addressPredictions.clear();
    } finally {
      isFetchingAddress.value = false;
    }
  }

  void selectAddress(String address) {
    addressController.text = address;
    addressPredictions.clear();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    reEnterPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    ssnController.dispose();
    addressController.dispose();
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
        lastNameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        ssnController.text.isEmpty ||
        addressController.text.isEmpty) {
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
    final url = Uri.parse(ApiConfig.buildUrl("/api/auth/register/cleaner"));

    try {
      String deviceToken = NotificationService().fcmToken ?? "";
      String deviceType = kIsWeb
          ? "web"
          : (Platform.isAndroid
              ? "android"
              : (Platform.isIOS ? "ios" : "android"));

      final response = await NetworkCaller.post(
        url,
        body: json.encode({
          "firstName": firstNameController.text.trim(),
          "lastName": lastNameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "phone": phoneController.text.trim(),
          "username": usernameController.text.trim(),
          "cleanFlowLanguage": selectedLanguage.value,
          "ssn": ssnController.text.trim(),
          "address": addressController.text.trim(),
          "profilePhoto": "",
          "isContractor": isContractor.value,
          "deviceToken": deviceToken,
          "deviceType": deviceType,
        }),
      );

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data.containsKey("token") && data.containsKey("user")) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", data["token"] as String);
          await prefs.setInt("id", data["user"]["id"] as int);
          await prefs.setString("role", (data["user"]["role"] ?? "").toString());
          await prefs.setString("phone", (data["user"]["phone"] ?? "").toString());
          await prefs.setString("isBusiness", (data["user"]["is_business"] ?? "").toString());

          Get.snackbar(
            LocalizationService().translate("common.success") ?? "Success",
            LocalizationService().translate("signup.registrationSuccessful") ?? "Registration successful!",
            snackPosition: SnackPosition.BOTTOM,
          );
          
          Get.offAll(() => const LoginPage());
        } else {
          Get.snackbar(
            LocalizationService().translate("common.success") ?? "Success",
            data?["message"]?.toString() ?? "Registration successful! Please check your email.",
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAll(() => const LoginPage());
        }
      } else {
        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          response.message ?? LocalizationService().translate("signup.registrationFailed") ?? "Registration failed. Please try again.",
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
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }
}
