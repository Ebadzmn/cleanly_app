import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';

class ProfileController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  
  Rx<File?> selectedImage = Rx<File?>(null);
  RxBool isLoading = false.obs;
  RxBool isUpdatingProfile = false.obs;
  
  RxBool obscurePassword = true.obs;
  RxBool obscureReEnterPassword = true.obs;
  
  RxString userName = ''.obs;
  RxString name = ''.obs;
  RxString phone = ''.obs;
  RxString userEmail = ''.obs;
  RxnString userImage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleReEnterPasswordVisibility() {
    obscureReEnterPassword.value = !obscureReEnterPassword.value;
  }

  Future<void> fetchUserData() async {
    isLoading.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found");
        isLoading.value = false;
        return;
      }

      final url = Uri.parse(ApiConfig.buildUrl("/user"));

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("User API Response status: ${response.statusCode}");
      debugPrint("User API Response body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.headers["content-type"]?.contains("application/json") == true) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            debugPrint("User API Parsed data: $data");

            userName.value = data["username"]?.toString() ?? "";
            userEmail.value = data["email"]?.toString() ?? "";
            userImage.value = data["profile_url"]?.toString();
            name.value = data["name"]?.toString() ?? "";
            phone.value = data["phone"]?.toString() ?? "";

            nameController.text = name.value;
            emailController.text = userEmail.value;
            String phoneValue = phone.value;
            phoneController.text = phoneValue.toLowerCase() == "pending" ? "" : phoneValue;
          } catch (e) {
            debugPrint("Error parsing JSON response: $e");
          }
        }
      } else {
        debugPrint("Failed to fetch user data. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      debugPrint("Error fetching user data: $e");
      debugPrint("Stack trace: $stack");
      Get.snackbar(
        "Error",
        LocalizationService().translate("profile.failedToLoadUserData"),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        LocalizationService().translate("profile.nameRequired"),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.isNotEmpty || confirmPasswordController.text.isNotEmpty) {
      if (passwordController.text != confirmPasswordController.text) {
        Get.snackbar(
          "Error",
          LocalizationService().translate("profile.passwordsDoNotMatch"),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (passwordController.text.length < 8) {
        Get.snackbar(
          "Error",
          LocalizationService().translate("profile.passwordTooShort"),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    isUpdatingProfile.value = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        Get.snackbar(
          "Error",
          LocalizationService().translate("profile.authenticationTokenMissing"),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isUpdatingProfile.value = false;
        return;
      }

      final Uri url = Uri.parse(ApiConfig.buildUrl("/profile/update"));

      final http.MultipartRequest request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      request.fields["name"] = nameController.text.trim();
      request.fields["email"] = emailController.text.trim();
      request.fields["phone"] = phoneController.text.trim();

      if (passwordController.text.isNotEmpty) {
        request.fields["password"] = passwordController.text;
      }
      if (confirmPasswordController.text.isNotEmpty) {
        request.fields["confirm_password"] = confirmPasswordController.text;
      }

      if (selectedImage.value != null) {
        final String fileName = selectedImage.value!.path.split("/").last;
        request.files.add(
          await http.MultipartFile.fromPath(
            "avatar",
            selectedImage.value!.path,
            filename: fileName,
          ),
        );
      }

      final http.StreamedResponse response = await request.send();
      final String responseBody = await response.stream.bytesToString();

      debugPrint("Profile Update API Response status: ${response.statusCode}");
      debugPrint("Profile Update API Response body: $responseBody");

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> decodedBody = json.decode(responseBody) as Map<String, dynamic>;
          final bool status = decodedBody["status"] as bool? ?? false;

          if (status || response.statusCode == 200) {
            Get.snackbar(
              "Success",
              LocalizationService().translate("profile.profileUpdatedSuccessfully"),
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );

            passwordController.clear();
            confirmPasswordController.clear();
            selectedImage.value = null;

            await fetchUserData();
          } else {
            String errorMessage = _extractErrorMessage(decodedBody);
            Get.snackbar(
              "Error",
              errorMessage,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          }
        } catch (e) {
          debugPrint("Error parsing profile update response: $e");
          Get.snackbar(
            "Error",
            LocalizationService().translate("profile.errorProcessingResponse"),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        try {
          final Map<String, dynamic> decodedBody = json.decode(responseBody) as Map<String, dynamic>;
          String errorMessage = _extractErrorMessage(decodedBody);
          Get.snackbar(
            "Error",
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } catch (e) {
          Get.snackbar(
            "Error",
            LocalizationService().translate("profile.failedToUpdateProfile"),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e, stack) {
      debugPrint("Error updating profile: $e");
      debugPrint("Stack trace: $stack");
      Get.snackbar(
        "Error",
        LocalizationService().translate("profile.errorOccurred"),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  String _extractErrorMessage(Map<String, dynamic> response) {
    if (response.containsKey("errors")) {
      final errors = response["errors"];
      String errorMessage = "";

      if (errors is Map<String, dynamic>) {
        List<String> errorMessages = [];
        errors.forEach((field, errorList) {
          if (errorList is List) {
            for (var error in errorList) {
              errorMessages.add(error.toString());
            }
          } else {
            errorMessages.add(errorList.toString());
          }
        });
        errorMessage = errorMessages.join("\n");
      } else if (errors is List) {
        errorMessage = errors.map((e) => e.toString()).join("\n");
      } else {
        errorMessage = errors.toString();
      }

      if (errorMessage.isNotEmpty) {
        return errorMessage;
      }
    }

    if (response.containsKey("message")) {
      final message = response["message"];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return LocalizationService().translate("profile.failedToUpdateProfile");
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        LocalizationService().translateWithParams(
          "profile.errorPickingImage",
          {"error": e.toString()},
        ),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
