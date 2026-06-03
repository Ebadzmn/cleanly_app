import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../login/pages/login_page.dart';

class MoreController extends GetxController {
  var isLoading = false.obs;
  var isLogoutLoading = false.obs;
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
      final http.Response response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        if (response.headers["content-type"]?.contains("application/json") == true) {
          final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
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
      final String? token = prefs.getString('token');

      final url = Uri.parse(ApiConfig.buildUrl('/logout'));
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await prefs.remove('token');
        Get.snackbar(
          "Success",
          LocalizationService().translate("more.loggedOutSuccessfully") ?? "Logged out successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAll(() => const LoginPage());
      } else {
        Get.snackbar(
          "Error",
          LocalizationService().translate("more.logoutFailed") ?? "Logout failed",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
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
}
