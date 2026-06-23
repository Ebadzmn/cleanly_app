import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/network_caller.dart';
import '../models/appointment_detail_model.dart';

class AppointmentDetailController extends GetxController {
  final String appointmentId;
  final String? targetDate;
  final bool isJob;

  AppointmentDetailController({
    required this.appointmentId,
    this.targetDate,
    this.isJob = false,
  });

  var appointmentDetail = Rxn<AppointmentDetailData>();
  var isLoading = false.obs;
  var error = RxnString();
  var acceptingAppointmentId = RxnString();
  var cancellingAppointmentId = RxnString();
  var selectedArriveIn = RxnString();
  var isArrivingIn = false.obs;
  var hasArrived = false.obs;
  var hasCheckedIn = false.obs;
  var isCheckingIn = false.obs;
  var isCheckingOut = false.obs;
  var checkOutNotes = "".obs;

  String? get occurrenceId {
    final occurrences = appointmentDetail.value?.allOccurrences;
    if (occurrences != null && occurrences.isNotEmpty) {
      if (targetDate != null && targetDate!.isNotEmpty) {
        try {
          return occurrences.firstWhere((occ) => occ.date == targetDate).id;
        } catch (e) {
          // If not found, fallback to first
        }
      }
      return occurrences.first.id;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _fetchAppointmentDetail();
  }

  Future<void> _fetchAppointmentDetail() async {
    isLoading.value = true;
    error.value = null;

    try {
      final String endpoint = isJob
          ? "/api/jobs/$appointmentId"
          : "/api/appointments/$appointmentId";
      final Uri url = Uri.parse(ApiConfig.buildUrl(endpoint));
      final response = await NetworkCaller.get(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null &&
            data["success"] == true &&
            data.containsKey("data")) {
          final Map<String, dynamic> dataMap =
              data["data"] as Map<String, dynamic>;
          appointmentDetail.value = AppointmentDetailData.fromJson(dataMap);
        } else {
          error.value = LocalizationService().translate("jobs.invalidResponse") ?? "Invalid response format from server.";
        }
      } else {
        error.value =
            "${LocalizationService().translate("jobs.failedToLoadDetails") ?? "Failed to load appointment details."} ${response.message ?? ''}";
      }
    } catch (e) {
      error.value = LocalizationService().translate("jobs.errorLoadingDetails") ?? "Something went wrong while loading appointment details.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> acceptAppointment() async {
    acceptingAppointmentId.value = appointmentId;

    try {
      final Uri url = Uri.parse(
        ApiConfig.buildUrl("/api/jobs/$appointmentId/accept"),
      );
      final response = await NetworkCaller.post(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar(
            "Success",
            LocalizationService().translate(
                  "appointments.jobAcceptedSuccessfully",
                ) ??
                "Job accepted.",
          );
          await _fetchAppointmentDetail();
          return true;
        } else {
          Get.snackbar(
            "Error",
            data?["message"] ??
                LocalizationService().translate(
                  "appointments.failedToAcceptJob",
                ) ??
                "Failed to accept.",
          );
          return false;
        }
      } else {
        Get.snackbar(
          "Error",
          response.message ??
              LocalizationService().translate(
                "appointments.failedToAcceptJob",
              ) ??
              "Failed to accept.",
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        LocalizationService().translate(
              "appointments.somethingWentWrongAccepting",
            ) ??
            "Something went wrong.",
      );
      return false;
    } finally {
      acceptingAppointmentId.value = null;
    }
  }

  Future<bool> cancelAppointment() async {
    cancellingAppointmentId.value = appointmentId;

    try {
      final Uri url = Uri.parse(
        ApiConfig.buildUrl("/api/jobs/$appointmentId/reject"),
      );
      final response = await NetworkCaller.post(url);

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar(
            "Success",
            LocalizationService().translate(
                  "appointments.jobCancelledSuccessfully",
                ) ??
                "Job rejected.",
          );
          return true;
        } else {
          Get.snackbar(
            "Error",
            data?["message"] ??
                LocalizationService().translate(
                  "appointments.failedToCancelJob",
                ) ??
                "Failed to reject.",
          );
          return false;
        }
      } else {
        Get.snackbar(
          "Error",
          response.message ??
              LocalizationService().translate(
                "appointments.failedToCancelJob",
              ) ??
              "Failed to reject.",
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        LocalizationService().translate(
              "appointments.somethingWentWrongCancelling",
            ) ??
            "Something went wrong.",
      );
      return false;
    } finally {
      cancellingAppointmentId.value = null;
    }
  }

  Future<void> arriveIn() async {
    if (selectedArriveIn.value == null) return;

    final occId = occurrenceId;
    if (occId == null || occId.isEmpty) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.noOccurrenceAvailable") ?? "No occurrence available for this job.");
      return;
    }

    isArrivingIn.value = true;
    try {
      final etaString = selectedArriveIn.value!.split(' ').first;
      final eta = int.tryParse(etaString) ?? 0;

      final Uri url = Uri.parse(
        ApiConfig.buildUrl("/api/appointments/occurrence/$occId/on-my-way"),
      );

      final body = {"eta": eta};

      final response = await NetworkCaller.post(url, body: jsonEncode(body));

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          hasArrived.value = true;
          Get.snackbar(
            "Success",
            LocalizationService().translate("appointments.onMyWaySuccess") ??
                "Arrival time confirmed for ${selectedArriveIn.value}",
          );
          await _fetchAppointmentDetail();
        } else {
          Get.snackbar(
            LocalizationService().translate("common.error") ?? "Error",
            data?["message"] ?? (LocalizationService().translate("jobs.failedToConfirmArrival") ?? "Failed to confirm arrival time."),
          );
        }
      } else {
        Get.snackbar(
          LocalizationService().translate("common.error") ?? "Error",
          response.message ?? (LocalizationService().translate("jobs.failedToConfirmArrival") ?? "Failed to confirm arrival time."),
        );
      }
    } catch (e) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.errorConfirmingArrival") ?? "Something went wrong while confirming arrival.");
    } finally {
      isArrivingIn.value = false;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> checkIn() async {
    final occId = occurrenceId;
    if (occId == null || occId.isEmpty) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.noOccurrenceAvailable") ?? "No occurrence available for this job.");
      return;
    }
    isCheckingIn.value = true;
    try {
      final position = await _determinePosition();
      final Uri url = Uri.parse(
        ApiConfig.buildUrl("/api/appointments/occurrence/$occId/check-in"),
      );

      final body = {"lat": position.latitude, "lng": position.longitude};

      final response = await NetworkCaller.post(url, body: jsonEncode(body));

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          hasCheckedIn.value = true;
          Get.snackbar(
            "Success",
            LocalizationService().translate("appointments.checkInSuccess") ??
                "Checked In successfully",
          );
          await _fetchAppointmentDetail();
        } else {
          Get.snackbar(LocalizationService().translate("common.error") ?? "Error", data?["message"] ?? (LocalizationService().translate("jobs.failedToCheckIn") ?? "Failed to check in."));
        }
      } else {
        Get.snackbar(LocalizationService().translate("common.error") ?? "Error", response.message ?? (LocalizationService().translate("jobs.failedToCheckIn") ?? "Failed to check in."));
      }
    } catch (e) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.errorCheckingIn") ?? "Something went wrong while checking in.");
    } finally {
      isCheckingIn.value = false;
    }
  }

  Future<void> checkOut() async {
    final occId = occurrenceId;
    if (occId == null || occId.isEmpty) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.noOccurrenceAvailable") ?? "No occurrence available for this job.");
      return;
    }
    isCheckingOut.value = true;
    try {
      final position = await _determinePosition();
      final Uri url = Uri.parse(
        ApiConfig.buildUrl("/api/appointments/occurrence/$occId/check-out"),
      );

      final body = {
        "lat": position.latitude,
        "lng": position.longitude,
        "notes": checkOutNotes.value,
      };

      final response = await NetworkCaller.post(url, body: jsonEncode(body));

      if (response.isSuccess) {
        final data = response.data;
        if (data != null && data["success"] == true) {
          Get.snackbar(
            "Success",
            LocalizationService().translate("appointments.checkOutSuccess") ??
                "Checked Out successfully",
          );
          await _fetchAppointmentDetail(); // Refresh job details
        } else {
          Get.snackbar(LocalizationService().translate("common.error") ?? "Error", data?["message"] ?? (LocalizationService().translate("jobs.failedToCheckOut") ?? "Failed to check out."));
        }
      } else {
        Get.snackbar(LocalizationService().translate("common.error") ?? "Error", response.message ?? (LocalizationService().translate("jobs.failedToCheckOut") ?? "Failed to check out."));
      }
    } catch (e) {
      Get.snackbar(LocalizationService().translate("common.error") ?? "Error", LocalizationService().translate("jobs.errorCheckingOut") ?? "Something went wrong while checking out.");
    } finally {
      isCheckingOut.value = false;
    }
  }
}
