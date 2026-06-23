import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../services/localization_service.dart';
import '../models/appointment_model.dart';
import '../controllers/jobs_controller.dart';
import 'package:get/get.dart';
import '../../appointment_detail/pages/appointment_detail_page.dart';

class JobCardWidget extends StatelessWidget {
  final Appointment appointment;
  final int tabIndex;
  final String statusLabel;

  const JobCardWidget({
    super.key,
    required this.appointment,
    required this.tabIndex,
    required this.statusLabel,
  });

  Map<String, dynamic> _mapAppointmentToJobData() {
    final String scheduleText;
    if (appointment.startTime.isNotEmpty && appointment.endTime.isNotEmpty) {
      final String startFormatted = appointment.startTime.length >= 5
          ? appointment.startTime.substring(0, 5)
          : appointment.startTime;
      final String endFormatted = appointment.endTime.length >= 5
          ? appointment.endTime.substring(0, 5)
          : appointment.endTime;
      scheduleText = "$startFormatted - $endFormatted";
    } else if (appointment.startTime.isNotEmpty) {
      scheduleText = appointment.startTime.length >= 5
          ? appointment.startTime.substring(0, 5)
          : appointment.startTime;
    } else {
      scheduleText = appointment.endTime.length >= 5
          ? appointment.endTime.substring(0, 5)
          : appointment.endTime;
    }

    final String formattedAddress;
    final String address = appointment.address.trim();
    if (address.isEmpty) {
      formattedAddress = "";
    } else {
      final List<String> addressWords = address.split(" ");
      if (addressWords.length > 3) {
        formattedAddress = "${addressWords[0]} ${addressWords[1]} ${addressWords[2]}...";
      } else {
        formattedAddress = address;
      }
    }

    return <String, dynamic>{
      "job_id": appointment.jobId,
      "appointment_id": appointment.appointmentId,
      "name": appointment.customerName,
      "status": statusLabel,
      "date": appointment.date,
      "time": scheduleText,
      "location": address, // Full address for display
      "cleaner_pay": appointment.pay,
      "description": appointment.description,
      "type": appointment.type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final jobData = _mapAppointmentToJobData();
    final bool isDetailed = tabIndex == 0; // Show detailed card only for 'Active'

    return GestureDetector(
      onTap: () async {
        final bool? shouldRefresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => AppointmentDetailPage(appointmentData: jobData, isJob: true)),
        );
        if (shouldRefresh == true) {
          Get.find<JobsController>().refreshActive();
        }
      },
      child: isDetailed ? _buildDetailedCard(context, jobData) : _buildCompactCard(context, jobData),
    );
  }

  Widget _buildDetailedCard(BuildContext context, Map<String, dynamic> jobData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services_outlined, color: Color(0xFF266185), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (jobData["type"] == "recurring" ? (LocalizationService().translate("jobs.recurringCleaning") ?? "RECURRING CLEANING") : (LocalizationService().translate("jobs.deepCleaning") ?? "DEEP CLEANING")).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF266185),
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4C535),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  jobData["status"].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5A4D3D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            jobData["type"].toString().isNotEmpty ? jobData["type"] : (LocalizationService().translate("jobs.serviceAppointment") ?? "Service Appointment"),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          if (jobData["description"] != null && jobData["description"].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              jobData["description"],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  jobData["name"],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildIconText(Icons.calendar_today_outlined, jobData["date"])),
              const SizedBox(width: 12),
              Expanded(child: _buildIconText(Icons.access_time_outlined, jobData["time"])),
            ],
          ),
          const SizedBox(height: 12),
          _buildIconText(Icons.location_on_outlined, jobData["location"]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  LocalizationService().translate("jobs.estEarnings") ?? "Est. Earnings",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  jobData["cleaner_pay"] != null && jobData["cleaner_pay"].toString().isNotEmpty 
                      ? "\$${jobData["cleaner_pay"]}" 
                      : "\$0.00",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B6C13), // Darker yellow/brown
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final String? jobId = jobData["job_id"]?.toString();
                      if (jobId != null) {
                        Get.find<JobsController>().cancelAppointment(jobId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFF991B1B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      LocalizationService().translate("common.reject") ?? "Reject",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final String? jobId = jobData["job_id"]?.toString();
                      if (jobId != null) {
                        Get.find<JobsController>().acceptAppointment(jobId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4C535),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      LocalizationService().translate("common.accept") ?? "Accept",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A4D3D),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () async {
                final bool? shouldRefresh = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => AppointmentDetailPage(appointmentData: jobData, isJob: true)),
                );
                if (shouldRefresh == true) {
                  Get.find<JobsController>().refreshActive();
                }
              },
              child: Text(
                LocalizationService().translate("jobs.viewDetails") ?? "View Details",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF266185),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, Map<String, dynamic> jobData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          Container(
            width: 4,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFF4C535),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobData["type"].toString().isNotEmpty ? jobData["type"] : (LocalizationService().translate("jobs.serviceAppointment") ?? "Service Appointment"),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (jobData["description"] != null && jobData["description"].toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                jobData["description"],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    jobData["name"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4B5563),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        jobData["cleaner_pay"] != null && jobData["cleaner_pay"].toString().isNotEmpty 
                            ? "\$${jobData["cleaner_pay"]}" 
                            : "\$0.00",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B6C13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jobData["type"] == "recurring" ? (LocalizationService().translate("jobs.recurringCleaning") ?? "Recurring Cleaning") : (LocalizationService().translate("jobs.standardCleaning") ?? "Standard Cleaning"),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconText(Icons.calendar_today_outlined, "${jobData["date"]}, ${jobData["time"]}", size: 12),
                      const Icon(Icons.chevron_right, color: Color(0xFF8C8476), size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {double size = 13}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 2, color: const Color(0xFF4B5563)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
