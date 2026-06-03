import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../services/localization_service.dart';
import '../../profile/pages/profile_page.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../language/pages/language_page.dart';
import '../../language/bindings/language_binding.dart';
import '../controllers/more_controller.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final MoreController controller = Get.put(MoreController());

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.7, 1.0],
            colors: [
              Color(0xFFC7F0F9), // Light sky blue
              Color(0xFFEDF8FA), // Light transition
              Color(0xFFFCE18D), // Soft yellow transition
              Color(0xFFF4C535), // Golden yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, controller),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF5A4D3D)),
                    );
                  }

                  return _buildContent(context, controller);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MoreController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LocalizationService().translate("more.title") ?? "More",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A4D3D),
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => const ProfilePage(), binding: ProfileBinding());
            },
            child: Obx(() {
              final String? imageUrl = controller.userImage.value;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Image.asset(
      "assets/images/placeholder.png",
      width: 44,
      height: 44,
      fit: BoxFit.cover,
    );
  }

  Widget _buildContent(BuildContext context, MoreController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(LocalizationService().translate("more.profile") ?? "Profile"),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: "assets/svg/profile.svg",
            title: LocalizationService().translate("more.profile") ?? "Profile",
            onTap: () {
              Get.to(() => const ProfilePage(), binding: ProfileBinding());
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(LocalizationService().translate("more.language") ?? "Language"),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: "assets/svg/language.svg",
            title: LocalizationService().translate("more.languages") ?? "Languages",
            onTap: () {
              Get.to(() => const LanguagePage(), binding: LanguageBinding());
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(LocalizationService().translate("more.logout") ?? "Logout"),
          const SizedBox(height: 12),
          Obx(() => _buildMenuItem(
                icon: "assets/svg/logout.svg",
                title: LocalizationService().translate("more.logout") ?? "Logout",
                isLoading: controller.isLogoutLoading.value,
                isDestructive: true,
                onTap: () => controller.logoutUser(),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5A4D3D),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    final Color iconAndTextColor = isDestructive ? const Color(0xFFC70036) : const Color(0xFF5A4D3D);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.60),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(iconAndTextColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: iconAndTextColor,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(iconAndTextColor),
                ),
              )
            else
              Icon(Icons.chevron_right, size: 24, color: iconAndTextColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
