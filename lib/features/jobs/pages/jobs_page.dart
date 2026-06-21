import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/localization_service.dart';
import '../controllers/jobs_controller.dart';
import '../widgets/job_card_widget.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final JobsController controller = Get.put(JobsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Light bluish-gray matching image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A4D3D)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          LocalizationService().translate("jobs.title") ?? "Jobs",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5A1D), // Dark yellow/olive color like in image
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF4C535), width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/placeholder.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Custom TabBar as pills
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => Row(
                children: [
                  _buildPillTab("Active", 0, controller),
                  const SizedBox(width: 8),
                  _buildPillTab("Accepted", 1, controller),
                  const SizedBox(width: 8),
                  _buildPillTab("Assigned", 2, controller),
                  const SizedBox(width: 8),
                  _buildPillTab("Completed", 3, controller, badgeCount: controller.completedAppointments.length),
                ],
              )),
            ),
            const SizedBox(height: 24),
            // Subheader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Available Requests",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Obx(() => Text(
                    "${controller.activeAppointments.length} New found",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF266185),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // List View
            Expanded(
              child: Obx(() {
                final int currentIndex = controller.currentTabIndex.value;
                if (currentIndex == 0) {
                  return _buildList(controller.activeAppointments, controller, 0, "Active", controller.isActiveLoading.value);
                } else if (currentIndex == 1) {
                  return _buildList(controller.acceptedAppointments, controller, 1, "Accepted", controller.isAcceptedLoading.value);
                } else if (currentIndex == 2) {
                  return _buildList(controller.assignedAppointments, controller, 2, "Assigned", controller.isAssignedLoading.value);
                } else {
                  return _buildList(controller.completedAppointments, controller, 3, "Completed", controller.isCompletedLoading.value);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab(String title, int index, JobsController controller, {int badgeCount = 0}) {
    final bool isSelected = controller.currentTabIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.tabController.animateTo(index);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFC7F0F9) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xFF5A4D3D),
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC70036), // A red color from cleanly app palette
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 9 ? "9+" : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List appointments, JobsController controller, int tabIndex, String statusLabel, bool isLoading) {
    if (isLoading && appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF4C535)));
    }
    
    Future<void> onRefresh() async {
      if (tabIndex == 0) await controller.refreshActive();
      else if (tabIndex == 1) await controller.refreshAccepted();
      else if (tabIndex == 2) await controller.refreshAssigned();
      else if (tabIndex == 3) await controller.refreshCompleted();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFF4C535),
      child: appointments.isEmpty
          ? _buildEmptyState("No $statusLabel appointments available")
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return JobCardWidget(
                  appointment: appointments[index],
                  tabIndex: tabIndex,
                  statusLabel: statusLabel,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      children: [
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C8476),
            ),
          ),
        ),
      ],
    );
  }
}
