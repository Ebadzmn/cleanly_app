import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isInitialLoading = true.obs;
  final RxString userImage = ''.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _fetchUserData();
    loadNotifications(isRefresh: false);

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      loadNotifications(isRefresh: true);
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _fetchUserData() async {
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
          try {
            final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
            userImage.value = data["profile_url"]?.toString() ?? '';
          } catch (e) {
            debugPrint("Error parsing JSON response: $e");
          }
        }
      }
    } catch (e, stack) {
      debugPrint("Error fetching user data: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh) {
      isInitialLoading.value = true;
    }

    try {
      final List<Map<String, dynamic>> storedNotifications = await NotificationService.getStoredNotifications();

      notifications.value = storedNotifications
          .map((map) => NotificationModel.fromMap(map))
          .toList();
    } catch (e, stack) {
      debugPrint("Error loading notifications: $e");
      debugPrint("Stack trace: $stack");
    } finally {
      if (!isClosed) {
        isInitialLoading.value = false;
      }
    }
  }
}
