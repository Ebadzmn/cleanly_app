import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/network_caller.dart';
import '../../login/pages/login_page.dart';

class MoreController extends GetxController {
  var isLoading = false.obs;
  var isLogoutLoading = false.obs;
  var isBlocking = false.obs;
  var userImage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    isLoading.value = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found");
        return;
      }

      final Uri url = Uri.parse(ApiConfig.buildUrl("/user"));
      final response = await NetworkCaller.get(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null) {
          userImage.value = data["profile_url"]?.toString();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logoutUser() async {
    isLogoutLoading.value = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      try {
        final url = Uri.parse(ApiConfig.buildUrl('/api/auth/logout'));
        await NetworkCaller.post(url);
      } catch (apiError) {
        debugPrint("Logout API failed, proceeding to clear local data: $apiError");
      }

      const secureStorage = FlutterSecureStorage();
      await secureStorage.delete(key: 'auth_token');

      bool isRemembered = prefs.getBool('remember_me') ?? false;
      String? savedEmail = prefs.getString('remembered_email');
      String? savedPassword = prefs.getString('remembered_password');

      await prefs.clear();

      if (isRemembered && savedEmail != null && savedPassword != null) {
        await prefs.setBool('remember_me', isRemembered);
        await prefs.setString('remembered_email', savedEmail);
        await prefs.setString('remembered_password', savedPassword);
      }

      Get.snackbar(
        "Success",
        LocalizationService().translate("more.loggedOutSuccessfully") ?? "Logged out successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAll(() => const LoginPage());
    } catch (e) {
      Get.snackbar(
        "Error",
        "${LocalizationService().translate("common.error") ?? "Error"}: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLogoutLoading.value = false;
    }
  }

  Future<void> blockAvailability(String date, String startTime, String endTime) async {
    isBlocking.value = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        Get.snackbar("Error", "Authentication token not found.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final Uri url = Uri.parse(ApiConfig.buildUrl('/api/cleaners/availability/block'));
      final Map<String, dynamic> body = {
        "date": date,
        "startTime": startTime,
        "endTime": endTime
      };

      final response = await NetworkCaller.post(url, body: json.encode(body));
      
      if (response.isSuccess) {
        Get.back(); // close the dialog
        Get.snackbar(
          "Success",
          "Availability blocked successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          response.message ?? "Failed to block availability",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "An error occurred: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isBlocking.value = false;
    }
  }
}
