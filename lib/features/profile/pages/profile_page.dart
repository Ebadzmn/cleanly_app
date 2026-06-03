import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_form_field_widget.dart';
import '../../../../services/localization_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final LocalizationService localization = LocalizationService();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4, 0.7, 1.0],
          colors: [
            Color(0xFFC7F0F9),
            Color(0xFFEDF8FA),
            Color(0xFFFCE18D),
            Color(0xFFF4C535),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF77CCD9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          title: Text(localization.translate("profile.title")),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                backgroundColor: Color(0xFF06E0FB),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: controller.pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4A90E2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: controller.selectedImage.value != null
                              ? Image.file(
                                  controller.selectedImage.value!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  controller.userImage.value ?? "",
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black.withOpacity(0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/images/placeholder.png',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: controller.pickImage,
                      child: Text(
                        localization.translate("profile.tapToChangePhoto"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.name.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.userEmail.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.60),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          ProfileFormFieldWidget(
                            label: localization.translate("profile.changeName"),
                            controller: controller.nameController,
                            placeholder: localization.translate("profile.name"),
                          ),
                          const SizedBox(height: 16),
                          ProfileFormFieldWidget(
                            label: localization.translate("profile.email"),
                            controller: controller.emailController,
                            placeholder: localization.translate(
                              "login.emailPlaceholder",
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          ProfileFormFieldWidget(
                            label: localization.translate(
                              "profile.changePassword",
                            ),
                            controller: controller.passwordController,
                            placeholder: localization.translate(
                              "profile.password",
                            ),
                            isPassword: true,
                            isRequired: false,
                            obscureText: controller.obscurePassword.value,
                            onToggleVisibility:
                                controller.togglePasswordVisibility,
                          ),
                          const SizedBox(height: 16),
                          ProfileFormFieldWidget(
                            label: localization.translate(
                              "profile.confirmPassword",
                            ),
                            controller: controller.confirmPasswordController,
                            placeholder: localization.translate(
                              "profile.confirmPassword",
                            ),
                            isPassword: true,
                            isReEnterPassword: true,
                            isRequired: false,
                            obscureText:
                                controller.obscureReEnterPassword.value,
                            onToggleVisibility:
                                controller.toggleReEnterPasswordVisibility,
                          ),
                          const SizedBox(height: 16),
                          ProfileFormFieldWidget(
                            label: localization.translate(
                              "profile.changePhoneNumber",
                            ),
                            controller: controller.phoneController,
                            placeholder: localization.translate(
                              "profile.phone",
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitProfileButton(controller, localization),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubmitProfileButton(
    ProfileController controller,
    LocalizationService localization,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: controller.isUpdatingProfile.value
            ? null
            : controller.updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          disabledBackgroundColor: Colors.black.withOpacity(0.6),
        ),
        child: controller.isUpdatingProfile.value
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localization.translate("profile.saveChanges"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              )
            : Text(
                localization.translate("profile.saveChanges"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
