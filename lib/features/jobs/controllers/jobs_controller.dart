import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/network_caller.dart';
import '../models/appointment_model.dart';

class JobsController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  var currentTabIndex = 0.obs;

  final List<String> jobTabs = [
    LocalizationService().translate("jobs.active_tab") ?? "Active",
    LocalizationService().translate("jobs.accepted_tab") ?? "Accepted",
    LocalizationService().translate("jobs.rejected_tab") ?? "Rejected",
    LocalizationService().translate("jobs.pending_tab") ?? "Pending",
  ];

  var activeAppointments = <Appointment>[].obs;
  var isActiveLoading = false.obs;
  var activeError = RxnString();

  var acceptedAppointments = <Appointment>[].obs;
  var isAcceptedLoading = false.obs;
  var acceptedError = RxnString();

  var rejectedAppointments = <Appointment>[].obs;
  var isRejectedLoading = false.obs;
  var rejectedError = RxnString();

  var pendingAppointments = <Appointment>[].obs;
  var isPendingLoading = false.obs;
  var pendingError = RxnString();

  var acceptingAppointmentId = RxnString();
  var cancellingAppointmentId = RxnString();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: jobTabs.length, vsync: this);
    tabController.addListener(() {
      if (tabController.indexIsChanging || tabController.index != currentTabIndex.value) {
        currentTabIndex.value = tabController.index;
        _fetchDataForTab(tabController.index);
      }
    });

    _fetchAvailableAppointments();
    _fetchTabAppointments("accepted");
    _fetchTabAppointments("rejected");
    _fetchTabAppointments("pending");
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _fetchDataForTab(int index) {
    if (index == 0) _fetchAvailableAppointments();
    if (index == 1) _fetchTabAppointments("accepted");
    if (index == 2) _fetchTabAppointments("rejected");
    if (index == 3) _fetchTabAppointments("pending");
  }

  Future<void> refreshActive() => _fetchAvailableAppointments();
  Future<void> refreshAccepted() => _fetchTabAppointments("accepted");
  Future<void> refreshRejected() => _fetchTabAppointments("rejected");
  Future<void> refreshPending() => _fetchTabAppointments("pending");

  Future<void> _fetchAvailableAppointments() async {
    isActiveLoading.value = true;
    activeError.value = null;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        activeError.value = "Authentication token is missing.";
        isActiveLoading.value = false;
        return;
      }

      final Uri url = Uri.parse(
        ApiConfig.buildUrlWithParams("/api/jobs/active", {
          "_t": DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );

      final response = await NetworkCaller.get(url);

      if (response.isSuccess) {
        final Map<String, dynamic>? decodedBody = response.data as Map<String, dynamic>?;
        
        if (decodedBody != null && decodedBody.containsKey("data")) {
          final List<dynamic>? rawData = decodedBody["data"] as List<dynamic>?;
          if (rawData != null) {
            activeAppointments.value = rawData
                .whereType<Map<String, dynamic>>()
                .map(Appointment.fromJson)
                .toList();
          }
        }
      } else {
        activeError.value = response.message ?? "Failed to fetch active appointments.";
      }
    } catch (e) {
      activeError.value = "An error occurred while fetching data.";
    } finally {
      isActiveLoading.value = false;
    }
  }

  Future<void> _fetchTabAppointments(String tab) async {
    if (tab == "accepted") {
      isAcceptedLoading.value = true;
      acceptedError.value = null;
    } else if (tab == "pending") {
      isPendingLoading.value = true;
      pendingError.value = null;
    } else if (tab == "rejected") {
      isRejectedLoading.value = true;
      rejectedError.value = null;
    }

    try {
      String statusParam = "all";
      if (tab == "accepted") statusParam = "Accepted";
      if (tab == "pending") statusParam = "Pending";
      if (tab == "rejected") statusParam = "Rejected";

      final Uri url = Uri.parse(
        ApiConfig.buildUrlWithParams("/api/jobs/cleaner", {
          "status": statusParam,
          "page": "1",
          "limit": "100",
        }),
      );

      final response = await NetworkCaller.get(url);

      if (response.isSuccess) {
        final Map<String, dynamic>? decodedBody = response.data as Map<String, dynamic>?;
        final List<dynamic>? rawData = decodedBody?["data"] as List<dynamic>?;
        
        final fetchedAppointments = rawData == null
            ? <Appointment>[]
            : rawData
                .whereType<Map<String, dynamic>>()
                .map(Appointment.fromJson)
                .toList();

        if (tab == "accepted") {
          acceptedAppointments.value = fetchedAppointments;
        } else if (tab == "pending") {
          pendingAppointments.value = fetchedAppointments;
        } else if (tab == "rejected") {
          rejectedAppointments.value = fetchedAppointments;
        }
      }
    } catch (e) {
      if (tab == "accepted") acceptedError.value = "Error fetching data.";
      if (tab == "pending") pendingError.value = "Error fetching data.";
      if (tab == "rejected") rejectedError.value = "Error fetching data.";
    } finally {
      if (tab == "accepted") isAcceptedLoading.value = false;
      if (tab == "pending") isPendingLoading.value = false;
      if (tab == "rejected") isRejectedLoading.value = false;
    }
  }

  Future<void> acceptAppointment(String appointmentId) async {
    acceptingAppointmentId.value = appointmentId;

    try {
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/jobs/$appointmentId/accept"));
      
      final response = await NetworkCaller.post(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar("Success", LocalizationService().translate("jobs.appointmentAccepted") ?? "Appointment accepted.",
              backgroundColor: Colors.green, colorText: Colors.white);
          _fetchAvailableAppointments();
          _fetchTabAppointments("accepted");
        } else {
          Get.snackbar("Error", data?["message"] ?? "Failed to accept.",
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar("Error", response.message ?? "Could not accept appointment.",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not accept appointment.",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      acceptingAppointmentId.value = null;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    cancellingAppointmentId.value = appointmentId;

    try {
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/jobs/$appointmentId/reject"));
      
      final response = await NetworkCaller.post(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar("Success", LocalizationService().translate("jobs.appointmentCancelled") ?? "Appointment rejected.",
              backgroundColor: Colors.green, colorText: Colors.white);
          _fetchAvailableAppointments();
          _fetchTabAppointments("rejected");
        } else {
          Get.snackbar("Error", data?["message"] ?? "Failed to reject.",
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar("Error", response.message ?? "Could not reject appointment.",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not reject appointment.",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      cancellingAppointmentId.value = null;
    }
  }
}
