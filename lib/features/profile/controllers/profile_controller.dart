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
import '../../more/controllers/more_controller.dart';

class ProfileController extends GetxController {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController ssnController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Rx<File?> selectedImage = Rx<File?>(null);
  RxBool isLoading = false.obs;
  RxBool isUpdatingProfile = false.obs;

  RxString userName = ''.obs;
  RxString name = ''.obs;
  RxnString userImage = RxnString();
  RxString selectedLanguage = 'en'.obs;
  RxString userToken = ''.obs;


  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value = LocalizationService().currentLanguage;
    fetchUserData();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    birthDateController.dispose();
    ssnController.dispose();
    super.onClose();
  }

  Future<void> fetchUserData() async {
    if (firstNameController.text.isEmpty && lastNameController.text.isEmpty) {
      isLoading.value = true;
    }


    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found");
        isLoading.value = false;
        return;
      }
      userToken.value = token;


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


            // Support object or string profilePhoto / profile_url keys
            String? rawPhoto;
            if (data["profilePhoto"] != null) {
              if (data["profilePhoto"] is Map) {
                rawPhoto = data["profilePhoto"]["url"]?.toString() ??
                    data["profilePhoto"]["path"]?.toString();
              } else {
                rawPhoto = data["profilePhoto"]?.toString();
              }
            }
            rawPhoto ??= data["profile_photo"]?.toString() ??
                data["profile_url"]?.toString() ??
                data["profileImage"]?.toString() ??
                data["avatar"]?.toString() ??
                data["image"]?.toString();

            userImage.value = ApiConfig.getFullImageUrl(rawPhoto);
            debugPrint("🖼️ [RAW PROFILE PHOTO FROM API]: $rawPhoto");
            debugPrint("🖼️ [RESOLVED USER IMAGE URL]: ${userImage.value}");


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

            firstNameController.text = firstName;
            lastNameController.text = lastName;

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

            usernameController.text = data["username"]?.toString() ?? "";
            birthDateController.text = data["birthDate"]?.toString() ?? "";
            ssnController.text = data["ssn"]?.toString() ?? "";
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
    if (firstNameController.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "First name is required",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
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

      String? uploadedPhotoUrl;
      if (selectedImage.value != null) {
        uploadedPhotoUrl = await _uploadImage(selectedImage.value!);
      }

      // Update profile details
      final Uri url = Uri.parse(ApiConfig.buildUrl("/api/cleaners/profile"));

      final Map<String, dynamic> body = {
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "username": usernameController.text.trim(),
        "cleanFlowLanguage": selectedLanguage.value == "es" ? "Spanish" : "English",
        "birthDate": birthDateController.text.trim(),
        "ssn": ssnController.text.trim(),
      };

      if (uploadedPhotoUrl != null && uploadedPhotoUrl.isNotEmpty) {
        body["profilePhoto"] = uploadedPhotoUrl;
      }

      debugPrint("\n================ API REQUEST ================");
      debugPrint("🚀 URL: $url");
      debugPrint("🛠️ METHOD: PATCH");
      debugPrint("📦 BODY: ${const JsonEncoder.withIndent('  ').convert(body)}");
      debugPrint("=============================================\n");

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

  Future<String?> _uploadImage(File file) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");
      if (token == null || token.isEmpty) return null;

      final Uri uploadUrl = Uri.parse(ApiConfig.buildUrl("/api/upload"));
      final http.MultipartRequest uploadRequest = http.MultipartRequest(
        "POST",
        uploadUrl,
      );
      uploadRequest.headers["Authorization"] = "Bearer $token";
      uploadRequest.headers["Accept"] = "application/json";

      final String fileName = file.path.split("/").last.split("\\").last;

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

      debugPrint("🚀 [UPLOAD] Starting profile image upload...");
      debugPrint("🚀 [UPLOAD] URL: $uploadUrl");
      debugPrint("🚀 [UPLOAD] File path: ${file.path}");

      uploadRequest.files.add(
        await http.MultipartFile.fromPath(
          "image",
          file.path,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      final http.StreamedResponse uploadResponse = await uploadRequest.send();
      final String uploadResponseBody = await uploadResponse.stream.bytesToString();

      debugPrint("📥 [UPLOAD] Response Code: ${uploadResponse.statusCode}");
      debugPrint("📥 [UPLOAD] Response Body: $uploadResponseBody");

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
        final dynamic decodedUpload = json.decode(uploadResponseBody);
        String? uploadedUrl;

        if (decodedUpload is Map<String, dynamic>) {
          if (decodedUpload["data"] != null) {
            if (decodedUpload["data"] is Map) {
              uploadedUrl = decodedUpload["data"]["url"]?.toString() ??
                            decodedUpload["data"]["path"]?.toString() ??
                            decodedUpload["data"]["image"]?.toString();
            } else if (decodedUpload["data"] is String) {
              uploadedUrl = decodedUpload["data"].toString();
            }
          }
          uploadedUrl ??= decodedUpload["url"]?.toString() ??
                          decodedUpload["path"]?.toString() ??
                          decodedUpload["image"]?.toString();
        }

        debugPrint("✅ [UPLOAD] Extracted Uploaded URL: $uploadedUrl");
        return uploadedUrl;
      }
    } catch (e, stack) {
      debugPrint("🚨 [UPLOAD ERROR] Exception: $e");
      debugPrint("🚨 Stack trace: $stack");
    }
    return null;
  }


}
