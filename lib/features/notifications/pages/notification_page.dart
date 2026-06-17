import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/localization_service.dart';
import '../../profile/pages/profile_page.dart';
import '../../profile/bindings/profile_binding.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_card_widget.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1F2937),
                size: 18,
              ),
            ),
          ),
        ),
        title: Text(
          LocalizationService().translate("notifications.title") ?? "Notifications",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Get.to(() => const ProfilePage(), binding: ProfileBinding());
              },
              child: Obx(() => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF4C535), width: 2),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF4C535).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: controller.userImage.value.isNotEmpty
                      ? Image.network(
                          controller.userImage.value,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                        )
                      : _buildPlaceholderAvatar(),
                ),
              )),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isInitialLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4C535)),
            ),
          );
        }

        return SafeArea(
          child: controller.notifications.isEmpty
              ? _buildEmptyState(controller)
              : RefreshIndicator(
                  color: const Color(0xFFF4C535),
                  backgroundColor: Colors.white,
                  onRefresh: () => controller.loadNotifications(isRefresh: true),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
                    itemCount: controller.notifications.length,
                    itemBuilder: (context, index) {
                      return NotificationCardWidget(
                        notification: controller.notifications[index],
                      );
                    },
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Image.asset(
      "assets/images/placeholder.png",
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }

  Widget _buildEmptyState(NotificationController controller) {
    return RefreshIndicator(
      color: const Color(0xFFF4C535),
      backgroundColor: Colors.white,
      onRefresh: () => controller.loadNotifications(isRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Container(
          height: Get.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFC7F0F9).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 50,
                    color: Color(0xFF266185),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "You're all caught up!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocalizationService().translate("notifications.noNotifications") ??
                    "There are no new notifications for you right now.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
