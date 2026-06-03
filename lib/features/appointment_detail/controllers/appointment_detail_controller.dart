import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../models/appointment_detail_model.dart';

class AppointmentDetailController extends GetxController {
  final int appointmentId;
  final Map<String, dynamic> appointmentData;

  var appointmentDetail = Rxn<AppointmentDetailData>();
  var isLoading = false.obs;
  var error = RxnString();
  var acceptingAppointmentId = RxnInt();
  var cancellingAppointmentId = RxnInt();

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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        error.value = "Authentication token is missing.";
        isLoading.value = false;
        return;
      }

      final Uri url = Uri.parse(ApiConfig.buildUrl("/appointments/$appointmentId/detail"));
      final http.Response response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body) as Map<String, dynamic>;
        
        if (decodedBody["success"] == true && decodedBody.containsKey("data")) {
          final Map<String, dynamic> dataMap = decodedBody["data"] as Map<String, dynamic>;
          appointmentDetail.value = AppointmentDetailData.fromJson(dataMap);
        } else {
          error.value = "Invalid response format from server.";
        }
      } else {
        error.value = "Failed to load appointment details. Code: ${response.statusCode}.";
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");
      if (token == null || token.isEmpty) {
        Get.snackbar("Error", LocalizationService().translate("appointments.authenticationTokenMissing") ?? "Auth token missing");
        return false;
      }

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
          Get.snackbar("Success", LocalizationService().translate("appointments.jobAcceptedSuccessfully") ?? "Job accepted.");
          await _fetchAppointmentDetail();
          return true;
        } else {
          Get.snackbar("Error", LocalizationService().translate("appointments.failedToAcceptJob") ?? "Failed to accept.");
          return false;
        }
      } else {
        Get.snackbar("Error", LocalizationService().translateWithParams("appointments.failedToAcceptJobCode", {"code": response.statusCode.toString()}) ?? "Failed to accept.");
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");
      if (token == null || token.isEmpty) {
        Get.snackbar("Error", LocalizationService().translate("appointments.authenticationTokenMissing") ?? "Auth token missing");
        return false;
      }

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
          Get.snackbar("Success", LocalizationService().translate("appointments.jobCancelledSuccessfully") ?? "Job cancelled.");
          return true;
        } else {
          Get.snackbar("Error", LocalizationService().translate("appointments.failedToCancelJob") ?? "Failed to cancel.");
          return false;
        }
      } else {
        Get.snackbar("Error", LocalizationService().translateWithParams("appointments.failedToCancelJobCode", {"code": response.statusCode.toString()}) ?? "Failed to cancel.");
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
