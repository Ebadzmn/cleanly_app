import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../services/localization_service.dart';
import '../../profile/pages/profile_page.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../language/pages/language_page.dart';
import '../../language/bindings/language_binding.dart';
import '../controllers/more_controller.dart';
import 'blocked_availability_list_page.dart';

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
                      child: CircularProgressIndicator(
                        color: Color(0xFF5A4D3D),
                      ),
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
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarPlaceholder(),
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
          _buildSectionTitle(
            LocalizationService().translate("more.profile") ?? "Profile",
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: "assets/svg/profile.svg",
            title: LocalizationService().translate("more.profile") ?? "Profile",
            onTap: () {
              Get.to(() => const ProfilePage(), binding: ProfileBinding());
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(
            LocalizationService().translate("more.language") ?? "Language",
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: "assets/svg/language.svg",
            title:
                LocalizationService().translate("more.languages") ??
                "Languages",
            onTap: () {
              Get.to(() => const LanguagePage(), binding: LanguageBinding());
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(
            LocalizationService().translate("more.availability") ??
                "Availability",
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            iconData: Icons.event_busy_outlined,
            title:
                LocalizationService().translate("Block my availability") ??
                "Block my availability",
            onTap: () => _showBlockAvailabilityDialog(context, controller),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            iconData: Icons.list_alt,
            title: LocalizationService().translate("Blocked Availability List") ?? "Blocked Availability List",
            onTap: () {
              Get.to(() => const BlockedAvailabilityListPage());
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(
            LocalizationService().translate("more.logout") ?? "Logout",
          ),
          const SizedBox(height: 12),
          Obx(
            () => _buildMenuItem(
              icon: "assets/svg/logout.svg",
              title: LocalizationService().translate("more.logout") ?? "Logout",
              isLoading: controller.isLogoutLoading.value,
              isDestructive: true,
              onTap: () => controller.logoutUser(),
            ),
          ),
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
    String? icon,
    IconData? iconData,
    required String title,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    final Color iconAndTextColor = isDestructive
        ? const Color(0xFFC70036)
        : const Color(0xFF5A4D3D);

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
              child: icon != null
                  ? SvgPicture.asset(
                      icon,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        iconAndTextColor,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(iconData, size: 20, color: iconAndTextColor),
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
              Icon(
                Icons.chevron_right,
                size: 24,
                color: iconAndTextColor.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }

  void _showBlockAvailabilityDialog(
    BuildContext context,
    MoreController controller,
  ) {
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Block Availability",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2638),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? "Select Date"
                                : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedDate == null
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E2638),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start Time Picker
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedStartTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedStartTime = pickedTime;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedStartTime == null
                                ? "Select Start Time"
                                : _formatTimeOfDay(selectedStartTime!),
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedStartTime == null
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E2638),
                            ),
                          ),
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // End Time Picker
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime:
                            selectedEndTime ??
                            (selectedStartTime ?? TimeOfDay.now()),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedEndTime = pickedTime;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedEndTime == null
                                ? "Select End Time"
                                : _formatTimeOfDay(selectedEndTime!),
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedEndTime == null
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E2638),
                            ),
                          ),
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            controller.isBlocking.value ||
                                selectedDate == null ||
                                selectedStartTime == null ||
                                selectedEndTime == null
                            ? null
                            : () {
                                final dateStr =
                                    "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                                final startStr = _formatTimeOfDay(
                                  selectedStartTime!,
                                );
                                final endStr = _formatTimeOfDay(
                                  selectedEndTime!,
                                );
                                controller.blockAvailability(
                                  dateStr,
                                  startStr,
                                  endStr,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isBlocking.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Block Availability",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    int hour = tod.hour;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')} $ampm';
  }
}
