import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_config.dart';
import '../../../../services/localization_service.dart';

class ProfileController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

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
  RxString selectedLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value = LocalizationService().currentLanguage;
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

      final url = Uri.parse(ApiConfig.buildUrl("/api/cleaners/profile"));

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
        if (response.headers["content-type"]?.contains("application/json") ==
            true) {
          try {
            final responseData =
                json.decode(response.body) as Map<String, dynamic>;
            debugPrint("User API Parsed data: $responseData");

            // Handle if data is nested inside "data" object
            final data =
                responseData.containsKey("data") && responseData["data"] is Map
                ? responseData["data"] as Map<String, dynamic>
                : responseData;

            userName.value = data["username"]?.toString() ?? "";
            userEmail.value = data["email"]?.toString() ?? "";

            // Support both old and new photo keys
            userImage.value = ApiConfig.getFullImageUrl(
              data["profilePhoto"]?.toString() ??
                  data["profile_url"]?.toString(),
            );

            // Support both old and new name keys
            final String firstName = data["firstName"]?.toString() ?? "";
            final String lastName = data["lastName"]?.toString() ?? "";
            final String fullName =
                data["fullName"]?.toString() ?? data["name"]?.toString() ?? "";

            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              name.value = "$firstName $lastName".trim();
            } else {
              name.value = fullName;
            }

            phone.value = data["phone"]?.toString() ?? "";

            if (data.containsKey("cleanFlowLanguage") && data["cleanFlowLanguage"] != null) {
              final String lang = data["cleanFlowLanguage"].toString().toLowerCase();
              if (lang == "english" || lang == "en") {
                selectedLanguage.value = "en";
                LocalizationService().loadLanguage("en");
              } else if (lang == "spanish" || lang == "es" || lang == "español") {
                selectedLanguage.value = "es";
                LocalizationService().loadLanguage("es");
              } else if (lang == "en" || lang == "es") {
                selectedLanguage.value = lang;
                LocalizationService().loadLanguage(lang);
              }
            }

            nameController.text = name.value;
            emailController.text = userEmail.value;
            String phoneValue = phone.value;
            phoneController.text = phoneValue.toLowerCase() == "pending"
                ? ""
                : phoneValue;
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

    if (passwordController.text.isNotEmpty ||
        confirmPasswordController.text.isNotEmpty) {
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

      // No need to upload image here anymore, it uploads instantly on selection.
      // Update profile details
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/cleaners/profile"));

      final names = nameController.text.trim().split(" ");
      final firstName = names.isNotEmpty ? names.first : "";
      final lastName = names.length > 1 ? names.sublist(1).join(" ") : "";

      final Map<String, dynamic> body = {
        "firstName": firstName,
        "lastName": lastName,
        "username": userName.value,
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "cleanFlowLanguage": selectedLanguage.value,
      };

      // If we had a previously uploaded image, it's already set in the DB,
      // but we can pass it again if we have it, although the API might just ignore it if missing.

      if (passwordController.text.isNotEmpty) {
        body["password"] = passwordController.text;
      }
      if (confirmPasswordController.text.isNotEmpty) {
        body["confirm_password"] = confirmPasswordController.text;
      }

      final http.Response response = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final String responseBody = response.body;

      debugPrint("Profile Update API Response status: ${response.statusCode}");
      debugPrint("Profile Update API Response body: $responseBody");

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> decodedBody =
              json.decode(responseBody) as Map<String, dynamic>;
          final bool status = decodedBody["status"] as bool? ?? false;

          if (status || response.statusCode == 200) {
            await LocalizationService().loadLanguage(selectedLanguage.value);
            Get.snackbar(
              "Success",
              LocalizationService().translate(
                "profile.profileUpdatedSuccessfully",
              ),
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
          final Map<String, dynamic> decodedBody =
              json.decode(responseBody) as Map<String, dynamic>;
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
        await _uploadAndSaveProfileImage(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        LocalizationService().translateWithParams("profile.errorPickingImage", {
          "error": e.toString(),
        }),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadAndSaveProfileImage(File file) async {
    isUpdatingProfile.value = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");
      if (token == null || token.isEmpty) return;

      final Uri uploadUrl = Uri.parse(ApiConfig.buildUrl("/api/upload"));
      final http.MultipartRequest uploadRequest = http.MultipartRequest(
        "POST",
        uploadUrl,
      );
      uploadRequest.headers["Authorization"] = "Bearer $token";
      uploadRequest.headers["Accept"] = "application/json";

      final String fileName = file.path.split("/").last;

      final String extension = fileName.split('.').last.toLowerCase();
      MediaType mediaType = MediaType('image', 'jpeg'); // default
      if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        mediaType = MediaType('image', 'gif');
      } else if (extension == 'webp') {
        mediaType = MediaType('image', 'webp');
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      }

      print("🚀 [UPLOAD] Starting profile image upload...");
      print("🚀 [UPLOAD] URL: $uploadUrl");
      print("🚀 [UPLOAD] File path: ${file.path}");
      print("🚀 [UPLOAD] File name: $fileName");
      print("🚀 [UPLOAD] MimeType: ${mediaType.mimeType}");

      uploadRequest.files.add(
        await http.MultipartFile.fromPath(
          "image",
          file.path,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      final http.StreamedResponse uploadResponse = await uploadRequest.send();
      final String uploadResponseBody = await uploadResponse.stream
          .bytesToString();

      print("📥 [UPLOAD] Response Code: ${uploadResponse.statusCode}");
      print("📥 [UPLOAD] Response Body: $uploadResponseBody");

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        final Map<String, dynamic> decodedUpload =
            json.decode(uploadResponseBody) as Map<String, dynamic>;
        if (decodedUpload["success"] == true && decodedUpload["data"] != null) {
          final String uploadedUrl =
              decodedUpload["data"]["url"]?.toString() ?? "";
          print("✅ [UPLOAD] Success! Uploaded URL: $uploadedUrl");

          if (uploadedUrl.isNotEmpty) {
            final Uri updateUrl = Uri.parse(
              ApiConfig.buildUrl("/api/cleaners/profile"),
            );

            final names = name.value.split(" ");
            final firstName = names.isNotEmpty ? names.first : "";
            final lastName = names.length > 1 ? names.sublist(1).join(" ") : "";

            final Map<String, dynamic> body = {
              "firstName": firstName,
              "lastName": lastName,
              "username": userName.value,
              "profilePhoto": uploadedUrl,
            };

            print("🚀 [PATCH] Starting profile update...");
            print("🚀 [PATCH] URL: $updateUrl");
            print("🚀 [PATCH] Body: ${jsonEncode(body)}");

            final response = await http.patch(
              updateUrl,
              headers: {
                "Authorization": "Bearer $token",
                "Accept": "application/json",
                "Content-Type": "application/json",
              },
              body: jsonEncode(body),
            );

            print("📥 [PATCH] Response Code: ${response.statusCode}");
            print("📥 [PATCH] Response Body: ${response.body}");

            if (response.statusCode == 200) {
              Get.snackbar(
                "Success",
                "Profile photo updated successfully",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              await fetchUserData(); // Refresh to show new image
            } else {
              print("❌ [PATCH] Failed to update profile.");
              Get.snackbar(
                "Error",
                "Failed to update profile",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          }
        } else {
          print("❌ [UPLOAD] API returned success false or missing data.");
          Get.snackbar(
            "Error",
            "Failed to upload image",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        print("❌ [UPLOAD] HTTP Error: ${uploadResponse.statusCode}");
        Get.snackbar(
          "Error",
          "Failed to upload image",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("🚨 [UPLOAD ERROR] Exception: $e");
    } finally {
      isUpdatingProfile.value = false;
    }
  }
}
