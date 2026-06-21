import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/appointment_detail_controller.dart';
import '../models/appointment_detail_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointmentData;
  final bool isJob;

  const AppointmentDetailPage({super.key, required this.appointmentData, this.isJob = false});

  @override
  Widget build(BuildContext context) {
    final String appointmentId =
        appointmentData["appointment_id"]?.toString() ??
        appointmentData["id"]?.toString() ??
        "0";
    final String targetDate = appointmentData["date"]?.toString() ?? "";

    // Inject the controller directly here so we pass the dynamic data
    final AppointmentDetailController controller = Get.put(
      AppointmentDetailController(
        appointmentId: appointmentId,
        targetDate: targetDate,
        isJob: isJob,
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
            isJob ? "Job Details" : "Appointment Details",
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

    // Determine the most accurate status: Occurrence status > Detail status > Fallback
    String status = appointmentData["status"]?.toString() ?? "";
    if (detail.status.isNotEmpty) {
      status = detail.status;
    }
    if (detail.allOccurrences.isNotEmpty) {
      final targetDate = appointmentData["date"]?.toString() ?? "";
      if (targetDate.isNotEmpty) {
        try {
          final occ = detail.allOccurrences.firstWhere(
            (o) => o.date == targetDate,
          );
          if (occ.status.isNotEmpty) status = occ.status;
        } catch (e) {
          // fallback to first if not found
          final occStatus = detail.allOccurrences.first.status;
          if (occStatus.isNotEmpty) status = occStatus;
        }
      } else {
        final occStatus = detail.allOccurrences.first.status;
        if (occStatus.isNotEmpty) status = occStatus;
      }
    }

    final String initialTabStatus = appointmentData["status"]?.toString().toLowerCase() ?? "";

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomerProfileCard(
                  customerName,
                  detail.firstName,
                  detail.lastName,
                  status,
                ),
                const SizedBox(height: 12),
                _buildScheduleCard(detail),
                const SizedBox(height: 12),
                _buildServiceDetailsCard(detail),
                const SizedBox(height: 12),
                _buildLocationCard(detail),
                const SizedBox(height: 12),
                _buildHouseInfoCard(detail),
                const SizedBox(height: 12),
                _buildJobInfoCard(detail.title, detail.description),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomActions(context, controller, status, initialTabStatus),
      ],
    );
  }

  Widget _buildCustomerProfileCard(String headerName, String firstName, String lastName, String status) {
    final String fullName = [
      firstName,
      lastName,
    ].where((s) => s.isNotEmpty).join(' ').trim();
    
    final String displayKeyName = headerName.isNotEmpty ? headerName : fullName;
    final String displayName = displayKeyName.isNotEmpty ? displayKeyName : "Unknown Customer";

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Color(0xFF8B6C13),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "CUSTOMER",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B6C13),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4C535).withOpacity(0.2), // Light yellow for status
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF4C535), width: 1),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B6C13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F4F6),
                ),
                child: Center(
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
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
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF8B6C13),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "SCHEDULE",
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6), // light yellowish background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B6C13),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(detail.date),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: const Color(0xFFFDE68A),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Time",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B6C13),
                        ),
                      ),
                      const SizedBox(height: 4),
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
                        detail.fullAddress,
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
                    onPressed: () async {
                      final lat = detail.lat;
                      final lng = detail.lng;
                      Uri uri;
                      if (lat.isNotEmpty &&
                          lng.isNotEmpty &&
                          lat != "0" &&
                          lng != "0" &&
                          lat != "0.0" &&
                          lng != "0.0") {
                        uri = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                        );
                      } else {
                        uri = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(detail.fullAddress)}",
                        );
                      }
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
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

  Widget _buildHouseInfoCard(AppointmentDetailData detail) {
    if (detail.bedrooms == null && detail.bathrooms == null && detail.kitchens == null && detail.squareFootage == null) {
      return const SizedBox.shrink();
    }
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
                Icons.home_outlined,
                color: Color(0xFF8B6C13),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                "HOUSE INFO",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B6C13),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (detail.bedrooms != null) ...[
            _buildHouseInfoRow("Bedrooms", "${detail.bedrooms}"),
            const SizedBox(height: 12),
          ],
          if (detail.bathrooms != null) ...[
            _buildHouseInfoRow("Bathrooms", "${detail.bathrooms}"),
            const SizedBox(height: 12),
          ],
          if (detail.kitchens != null) ...[
            _buildHouseInfoRow("Kitchens", "${detail.kitchens}"),
            const SizedBox(height: 12),
          ],
          if (detail.squareFootage != null) ...[
            _buildHouseInfoRow("Square Footage", "${detail.squareFootage} sqft"),
          ],
        ],
      ),
    );
  }

  Widget _buildHouseInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildJobInfoCard(String title, String description) {
    if (title.isEmpty && description.isEmpty) return const SizedBox.shrink();
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
                "JOB INFO",
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
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    AppointmentDetailController controller,
    String status,
    String initialTabStatus,
  ) {
    final statusLower = status.toLowerCase();
    final isPending = statusLower == "pending";

    final bool isOnMyWay = statusLower == "on_my_way";
    final bool isCheckedIn = statusLower == "checked_in";
    final bool isCheckedOut = statusLower == "checked_out";
    final bool isCompleted = statusLower == "completed";

    final bool onMyWayEnabled = !isPending && !isCheckedOut && !isCompleted;
    final bool checkInEnabled = !isPending && !isCheckedOut && !isCompleted;
    final bool checkOutEnabled = !isPending && !isCheckedOut && !isCompleted;

    if (isJob && (initialTabStatus == "accepted" || initialTabStatus == "assigned" || initialTabStatus == "completed")) {
      return const SizedBox.shrink();
    }

    if (isJob || isPending) {
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

    // Tracking buttons for accepted/active jobs
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onMyWayEnabled
                  ? () => _showArriveInDialog(context, controller)
                  : null,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: onMyWayEnabled
                      ? const Color(0xFF1e1e1e)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: onMyWayEnabled
                          ? Colors.white
                          : const Color(0xFF999999),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "On My Way",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: onMyWayEnabled
                            ? Colors.white
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: checkInEnabled ? () => controller.checkIn() : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: checkInEnabled
                              ? const Color(0xFF1e1e1e)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: checkInEnabled
                                ? const Color(0xFF00b8db)
                                : const Color(0xFF999999),
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Obx(
                            () => controller.isCheckingIn.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF00b8db),
                                    ),
                                  )
                                : Flexible(
                                    child: Text(
                                      "Check In",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: checkInEnabled
                                            ? const Color(0xFF313131)
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: checkOutEnabled ? () => controller.checkOut() : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: checkOutEnabled
                              ? const Color(0xFF1e1e1e)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: checkOutEnabled
                                ? const Color(0xFFC70036)
                                : const Color(0xFF999999),
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Obx(
                            () => controller.isCheckingOut.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFC70036),
                                    ),
                                  )
                                : Flexible(
                                    child: Text(
                                      "Check Out",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: checkOutEnabled
                                            ? const Color(0xFF313131)
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArriveInDialog(
    BuildContext context,
    AppointmentDetailController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Select Arrival Time",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEtaOption(context, controller, "15 mins"),
              _buildEtaOption(context, controller, "30 mins"),
              _buildEtaOption(context, controller, "45 mins"),
              _buildEtaOption(context, controller, "60 mins"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEtaOption(
    BuildContext context,
    AppointmentDetailController controller,
    String eta,
  ) {
    return ListTile(
      title: Text(eta),
      onTap: () {
        controller.selectedArriveIn.value = eta;
        Navigator.pop(context);
        controller.arriveIn();
      },
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return "N/A";
    try {
      final DateTime date = DateTime.parse(dateString);
      final List<String> months = [
        "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${months[date.month]} ${date.day}, ${date.year}";
    } catch (e) {
      if (dateString.contains("T")) {
        return dateString.split("T").first;
      }
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return "";
    if (timeString.length >= 5) return timeString.substring(0, 5);
    return timeString;
  }
}
