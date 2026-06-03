import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
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

  var acceptingAppointmentId = RxnInt();
  var cancellingAppointmentId = RxnInt();

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
        ApiConfig.buildUrlWithParams("/appointments/available", {
          "_t": DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );

      final http.Response response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body) as Map<String, dynamic>;
        
        if (decodedBody.containsKey("data")) {
          final List<dynamic>? rawData = decodedBody["data"] as List<dynamic>?;
          if (rawData != null) {
            activeAppointments.value = rawData
                .whereType<Map<String, dynamic>>()
                .map(Appointment.fromJson)
                .toList();
          }
        }
      } else {
        activeError.value = "Failed to fetch active appointments.";
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) return;

      final Uri url = Uri.parse(
        ApiConfig.buildUrlWithParams("/appointments/jobs", {"tab": tab}),
      );

      final http.Response response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic>? rawData = decodedBody["data"] as List<dynamic>?;
        
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

  Future<void> acceptAppointment(int appointmentId) async {
    acceptingAppointmentId.value = appointmentId;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");
      if (token == null) return;

      final Uri url = Uri.parse(ApiConfig.buildUrl("/appointments/jobs/accept"));
      final http.MultipartRequest request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";
      request.fields["appointment_id"] = appointmentId.toString();

      final http.StreamedResponse response = await request.send();
      final String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(responseBody) as Map<String, dynamic>;
        if (decodedBody["success"] == true) {
          Get.snackbar("Success", LocalizationService().translate("jobs.appointmentAccepted") ?? "Appointment accepted.");
          _fetchAvailableAppointments();
          _fetchTabAppointments("accepted");
        } else {
          Get.snackbar("Error", decodedBody["message"] ?? "Failed to accept.");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not accept appointment.");
    } finally {
      acceptingAppointmentId.value = null;
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    cancellingAppointmentId.value = appointmentId;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");
      if (token == null) return;

      final Uri url = Uri.parse(ApiConfig.buildUrl("/appointments/jobs/cancel"));
      final http.MultipartRequest request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";
      request.fields["appointment_id"] = appointmentId.toString();

      final http.StreamedResponse response = await request.send();
      final String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(responseBody) as Map<String, dynamic>;
        if (decodedBody["success"] == true) {
          Get.snackbar("Success", LocalizationService().translate("jobs.appointmentCancelled") ?? "Appointment cancelled.");
          _fetchTabAppointments("accepted");
          _fetchTabAppointments("pending");
        } else {
          Get.snackbar("Error", decodedBody["message"] ?? "Failed to cancel.");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not cancel appointment.");
    } finally {
      cancellingAppointmentId.value = null;
    }
  }
}
