import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/blocked_availability_list_controller.dart';
import '../../../../services/localization_service.dart';

class BlockedAvailabilityListPage extends StatelessWidget {
  const BlockedAvailabilityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BlockedAvailabilityListController controller = Get.put(BlockedAvailabilityListController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate("more.blockedAvailabilityList") ?? "Blocked Availability",
          style: const TextStyle(color: Color(0xFF1E2638), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E2638)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.blockedList.isEmpty) {
          return Center(
            child: Text(
              LocalizationService().translate("more.noBlockedAvailability") ?? "No blocked availability found.",
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.blockedList.length,
          itemBuilder: (context, index) {
            final item = controller.blockedList[index];
            
            // Format Date safely
            String formattedDate = LocalizationService().translate("common.na") ?? "N/A";
            try {
              if (item["date"] != null) {
                final dt = DateTime.parse(item["date"].toString());
                formattedDate = DateFormat('MMM dd, yyyy').format(dt);
              }
            } catch (_) {}

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_busy, color: Color(0xFFF97316)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2638),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${item["startTime"]} - ${item["endTime"]}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
