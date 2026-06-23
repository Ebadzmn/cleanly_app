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
    "Active",
    "Accepted",
    "Assigned",
    "Completed",
  ];

  var activeAppointments = <Appointment>[].obs;
  var isActiveLoading = false.obs;
  var activeError = RxnString();

  var acceptedAppointments = <Appointment>[].obs;
  var isAcceptedLoading = false.obs;
  var acceptedError = RxnString();

  var assignedAppointments = <Appointment>[].obs;
  var isAssignedLoading = false.obs;
  var assignedError = RxnString();

  var completedAppointments = <Appointment>[].obs;
  var isCompletedLoading = false.obs;
  var completedError = RxnString();

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

    _fetchTabAppointments("active");
    _fetchTabAppointments("accepted");
    _fetchTabAppointments("assigned");
    _fetchTabAppointments("completed");
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _fetchDataForTab(int index) {
    if (index == 0) _fetchTabAppointments("active");
    if (index == 1) _fetchTabAppointments("accepted");
    if (index == 2) _fetchTabAppointments("assigned");
    if (index == 3) _fetchTabAppointments("completed");
  }

  Future<void> refreshActive() => _fetchTabAppointments("active");
  Future<void> refreshAccepted() => _fetchTabAppointments("accepted");
  Future<void> refreshAssigned() => _fetchTabAppointments("assigned");
  Future<void> refreshCompleted() => _fetchTabAppointments("completed");

  Future<void> _fetchTabAppointments(String tab) async {
    if (tab == "active") {
      isActiveLoading.value = true;
      activeError.value = null;
    } else if (tab == "accepted") {
      isAcceptedLoading.value = true;
      acceptedError.value = null;
    } else if (tab == "completed") {
      isCompletedLoading.value = true;
      completedError.value = null;
    } else if (tab == "assigned") {
      isAssignedLoading.value = true;
      assignedError.value = null;
    }

    try {
      String statusParam = "all";
      if (tab == "active") statusParam = "Active";
      if (tab == "accepted") statusParam = "Accepted";
      if (tab == "completed") statusParam = "Completed";
      if (tab == "assigned") statusParam = "Assigned";

      final Uri url = Uri.parse(
        ApiConfig.buildUrlWithParams("/api/jobs/cleaner", {
          "status": statusParam,
          "page": "1",
          "limit": "10",
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

        if (tab == "active") {
          activeAppointments.value = fetchedAppointments;
        } else if (tab == "accepted") {
          acceptedAppointments.value = fetchedAppointments;
        } else if (tab == "completed") {
          completedAppointments.value = fetchedAppointments;
        } else if (tab == "assigned") {
          assignedAppointments.value = fetchedAppointments;
        }
      }
    } catch (e) {
      if (tab == "active") activeError.value = LocalizationService().translate("jobs.errorFetchingData") ?? "Error fetching data.";
      if (tab == "accepted") acceptedError.value = LocalizationService().translate("jobs.errorFetchingData") ?? "Error fetching data.";
      if (tab == "completed") completedError.value = LocalizationService().translate("jobs.errorFetchingData") ?? "Error fetching data.";
      if (tab == "assigned") assignedError.value = LocalizationService().translate("jobs.errorFetchingData") ?? "Error fetching data.";
    } finally {
      if (tab == "active") isActiveLoading.value = false;
      if (tab == "accepted") isAcceptedLoading.value = false;
      if (tab == "completed") isCompletedLoading.value = false;
      if (tab == "assigned") isAssignedLoading.value = false;
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
          Get.snackbar(LocalizationService().translate("common.success") ?? "Success", LocalizationService().translate("jobs.appointmentAccepted") ?? "Appointment accepted.",
              backgroundColor: Colors.green, colorText: Colors.white);
          _fetchTabAppointments("active");
          _fetchTabAppointments("accepted");
        } else {
          Get.snackbar(LocalizationService().translate("common.error") ?? "Error", data?["message"] ?? (LocalizationService().translate("jobs.failedToAccept") ?? "Failed to accept."),
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar(LocalizationService().translate("common.error") ?? "Error", response.message ?? (LocalizationService().translate("jobs.couldNotAcceptAppointment") ?? "Could not accept appointment."),
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.couldNotAcceptAppointment") ?? "Could not accept appointment.",
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
          Get.snackbar(LocalizationService().translate("common.success") ?? "Success", LocalizationService().translate("jobs.appointmentCancelled") ?? "Appointment rejected.",
              backgroundColor: Colors.green, colorText: Colors.white);
          _fetchTabAppointments("active");
        } else {
          Get.snackbar(LocalizationService().translate("common.error") ?? "Error", data?["message"] ?? (LocalizationService().translate("jobs.failedToReject") ?? "Failed to reject."),
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar(LocalizationService().translate("common.error") ?? "Error", response.message ?? (LocalizationService().translate("jobs.couldNotRejectAppointment") ?? "Could not reject appointment."),
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.couldNotRejectAppointment") ?? "Could not reject appointment.",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      cancellingAppointmentId.value = null;
    }
  }
}
