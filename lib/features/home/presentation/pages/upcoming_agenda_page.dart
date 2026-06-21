import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../widgets/agenda_day_card_widget.dart';

class UpcomingAgendaPage extends StatelessWidget {
  const UpcomingAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming HomeController is already put in the widget tree by the home screen
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "All Upcoming Agenda",
          style: TextStyle(
            color: Color(0xFF1E2638),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E2638)),
      ),
      body: Obx(() {
        if (homeController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF6C844)),
          );
        }

        final upcomingList = homeController.appointmentsData.value?.upcoming ?? [];

        if (upcomingList.isEmpty) {
          return const Center(
            child: Text(
              "You have a clear schedule ahead!",
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: upcomingList.length,
          itemBuilder: (context, index) {
            final group = upcomingList[index];
            DateTime upcomingDate;
            try {
              upcomingDate = DateTime.parse(group.date);
            } catch (e) {
              upcomingDate = DateTime.now(); // fallback
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AgendaDayCardWidget(
                date: upcomingDate,
                tagText: "Upcoming",
                tagBgColor: const Color(0xFFF9F0D6),
                tagTextColor: const Color(0xFF90702F),
                borderColor: const Color(0xFFF6C844),
                appointments: group.data,
              ),
            );
          },
        );
      }),
    );
  }
}
