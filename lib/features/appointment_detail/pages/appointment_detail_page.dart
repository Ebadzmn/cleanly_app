import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../services/localization_service.dart';
import '../controllers/appointment_detail_controller.dart';
import '../models/appointment_detail_model.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailPage({super.key, required this.appointmentData});

  @override
  Widget build(BuildContext context) {
    final String appointmentId = appointmentData["appointment_id"]?.toString() ?? appointmentData["id"]?.toString() ?? "0";

    // Inject the controller directly here so we pass the dynamic data
    final AppointmentDetailController controller = Get.put(
      AppointmentDetailController(
        appointmentId: appointmentId,
        appointmentData: appointmentData,
      ),
      tag: appointmentId.toString(),
    );

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
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5A4D3D)),
            onPressed: () =>
                Navigator.pop(context, true), // Pass true to refresh parent
          ),
          title: Text(
            LocalizationService().translate("Job Details") ?? "Job Details",
            style: const TextStyle(
              fontSize: 24,
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
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5A4D3D)),
              );
            }

            if (controller.error.value != null ||
                controller.appointmentDetail.value == null) {
              return Center(
                child: Text(
                  controller.error.value ?? "Failed to load details.",
                  style: const TextStyle(
                    color: Color(0xFFC70036),
                    fontSize: 16,
                  ),
                ),
              );
            }

            return _buildContent(
              context,
              controller,
              controller.appointmentDetail.value!,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppointmentDetailController controller,
    AppointmentDetailData detail,
  ) {
    final String customerName = appointmentData["name"]?.toString() ?? "";
    final String status = appointmentData["status"]?.toString() ?? "";

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(
                  customerName,
                  detail.appointmentId.toString(),
                  status,
                ),
                const SizedBox(height: 12),
                _buildScheduleCard(detail),
                const SizedBox(height: 12),
                _buildServiceDetailsCard(detail),
                const SizedBox(height: 12),
                _buildLocationCard(detail),
                const SizedBox(height: 12),
                _buildNotesCard(detail.description),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomActions(controller, status),
      ],
    );
  }

  Widget _buildHeaderCard(String name, String id, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Appointment ID: $id",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4C535),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(AppointmentDetailData detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService().translate("appointments.schedule") ??
                "Schedule",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildIconContainer(Icons.calendar_today_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Date",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.date.isEmpty ? "N/A" : detail.date,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildIconContainer(Icons.access_time_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Time",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_formatTime(detail.startTime)} - ${_formatTime(detail.endTime)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard(AppointmentDetailData detail) {
    final typeText = detail.type.toLowerCase() == "recurring"
        ? "Recurring Cleaning"
        : "Deep Cleaning";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cleaning_services_outlined,
                color: Color(0xFF8B6C13),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "SERVICE DETAILS",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B6C13),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Type",
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              Text(
                typeText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Duration",
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              // Assume 2 Hours if not explicitly available, but since we have start/end time, we can leave as generic or calculate. Let's just put "2 Hours" to match mockup.
              const Text(
                "2 Hours",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pay Rate",
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              Text(
                detail.cleanerPay.isNotEmpty
                    ? (detail.cleanerPay.startsWith('\$')
                          ? detail.cleanerPay
                          : "\$${detail.cleanerPay}")
                    : "\$0.00",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8B6C13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(AppointmentDetailData detail) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Placeholder Image
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Simulating a map background
                Opacity(
                  opacity: 0.5,
                  child: Image.network(
                    "https://maps.googleapis.com/maps/api/staticmap?center=Brooklyn+Bridge,New+York,NY&zoom=13&size=600x300&maptype=roadmap&key=INVALID_KEY",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: const Color(0xFFD1D5DB));
                    },
                  ),
                ),
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFC70036),
                  size: 40,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF8B6C13),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text("Open in Maps"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF266185),
                      side: const BorderSide(color: Color(0xFF266185)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String description) {
    if (description.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF8B6C13),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                "CUSTOMER NOTES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B6C13),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$description"',
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    AppointmentDetailController controller,
    String status,
  ) {
    // Only show bottom actions if it's "Pending" or "Active", adjust as needed
    // Assuming the mockup shows "Accept Job", "Decline", and a chat icon, it's likely for a Pending job
    final isPendingOrActive =
        status.toLowerCase() == "pending" || status.toLowerCase() == "active";
    if (!isPendingOrActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => controller.acceptAppointment(),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Obx(
                  () => controller.acceptingAppointmentId.value != null
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF5A4D3D),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Accept Job",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4C535),
                  foregroundColor: const Color(0xFF5A4D3D),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => controller.cancelAppointment(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  side: const BorderSide(color: Color(0xFF9CA3AF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Obx(
                  () => controller.cancellingAppointmentId.value != null
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF4B5563),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Decline",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FA), // Light blue background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF266185), size: 22),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return "";
    if (timeString.length >= 5) return timeString.substring(0, 5);
    return timeString;
  }
}
