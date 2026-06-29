import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/network_caller.dart';

class BlockedAvailabilityListController extends GetxController {
  var isLoading = false.obs;
  var blockedList = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlockedAvailability();
  }

  Future<void> fetchBlockedAvailability() async {
    isLoading.value = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) return;

      final Uri url = Uri.parse(ApiConfig.buildUrl('/api/cleaners/availability/block'));
      final response = await NetworkCaller.get(url);

      if (response.isSuccess && response.data != null) {
        if (response.data["data"] is List) {
          blockedList.value = response.data["data"];
        }
      } else {
        Get.snackbar("Error", response.message ?? "Failed to fetch blocked availability", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBlockedAvailability(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) return;

      final Uri url = Uri.parse(ApiConfig.buildUrl('/api/cleaners/availability/block/$id'));
      final response = await NetworkCaller.delete(url);

      if (response.isSuccess) {
        Get.snackbar(
          "Success",
          "Blocked availability deleted successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchBlockedAvailability();
      } else {
        Get.snackbar(
          "Error",
          response.message ?? "Failed to delete blocked availability",
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
    }
  }
}
