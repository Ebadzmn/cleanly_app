import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/network_caller.dart';
import '../models/appointment_detail_model.dart';

class AppointmentDetailController extends GetxController {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  var appointmentDetail = Rxn<AppointmentDetailData>();
  var isLoading = false.obs;
  var error = RxnString();
  var acceptingAppointmentId = RxnString();
  var cancellingAppointmentId = RxnString();

  AppointmentDetailController({required this.appointmentId, required this.appointmentData});

  @override
  void onInit() {
    super.onInit();
    _fetchAppointmentDetail();
  }

  Future<void> _fetchAppointmentDetail() async {
    isLoading.value = true;
    error.value = null;

    try {
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/jobs/$appointmentId"));
      final response = await NetworkCaller.get(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true && data.containsKey("data")) {
          final Map<String, dynamic> dataMap = data["data"] as Map<String, dynamic>;
          appointmentDetail.value = AppointmentDetailData.fromJson(dataMap);
        } else {
          error.value = "Invalid response format from server.";
        }
      } else {
        error.value = "Failed to load appointment details. ${response.message ?? ''}";
      }
    } catch (e) {
      error.value = "Something went wrong while loading appointment details.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> acceptAppointment() async {
    acceptingAppointmentId.value = appointmentId;

    try {
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/jobs/$appointmentId/accept"));
      final response = await NetworkCaller.post(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar("Success", LocalizationService().translate("appointments.jobAcceptedSuccessfully") ?? "Job accepted.");
          await _fetchAppointmentDetail();
          return true;
        } else {
          Get.snackbar("Error", data?["message"] ?? LocalizationService().translate("appointments.failedToAcceptJob") ?? "Failed to accept.");
          return false;
        }
      } else {
        Get.snackbar("Error", response.message ?? LocalizationService().translate("appointments.failedToAcceptJob") ?? "Failed to accept.");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", LocalizationService().translate("appointments.somethingWentWrongAccepting") ?? "Something went wrong.");
      return false;
    } finally {
      acceptingAppointmentId.value = null;
    }
  }

  Future<bool> cancelAppointment() async {
    cancellingAppointmentId.value = appointmentId;

    try {
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/jobs/$appointmentId/reject"));
      final response = await NetworkCaller.post(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar("Success", LocalizationService().translate("appointments.jobCancelledSuccessfully") ?? "Job rejected.");
          return true;
        } else {
          Get.snackbar("Error", data?["message"] ?? LocalizationService().translate("appointments.failedToCancelJob") ?? "Failed to reject.");
          return false;
        }
      } else {
        Get.snackbar("Error", response.message ?? LocalizationService().translate("appointments.failedToCancelJob") ?? "Failed to reject.");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", LocalizationService().translate("appointments.somethingWentWrongCancelling") ?? "Something went wrong.");
      return false;
    } finally {
      cancellingAppointmentId.value = null;
    }
  }
}
