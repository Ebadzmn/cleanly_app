import 'package:flutter/material.dart';
import '../domain/models/appointment_models.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../appointment_detail/pages/appointment_detail_page.dart';

class AppointmentCardWidget extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCardWidget({Key? key, required this.appointment})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String startTimeFormatted = DateTimeUtils.formatTime(
      appointment.startTime,
    );
    final String endTimeFormatted = DateTimeUtils.formatTime(
      appointment.endTime,
    );

    final String title =
        (appointment.type == "one_time" ? "One Time Service" : appointment.type)
            .isNotEmpty
        ? (appointment.type == "one_time"
              ? "One Time Service"
              : appointment.type)
        : "Estate Valuation";
    final String clientName =
        "Client: ${appointment.customer.name ?? 'Unknown'}";
    final String address =
        appointment.customer.address ?? "Address not available";

    return GestureDetector(
      onTap: () {
        final Map<String, dynamic> jobData = {
          "appointment_id": appointment.appointmentId,
          "name": appointment.customer.name ?? "Unknown",
          "status": appointment.status,
          "date": appointment.date,
          "time": "${appointment.startTime} - ${appointment.endTime}",
          "location": appointment.customer.address ?? "",
          "description": appointment.description,
          "type": appointment.type,
        };
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AppointmentDetailPage(appointmentData: jobData),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Time Column
            SizedBox(
              width: 75,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    startTimeFormatted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 1,
                    height: 12,
                    color: const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    endTimeFormatted,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: 1,
              height: 60,
              color: const Color(0xFFCBD5E1),
            ),

            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
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

            // Right Arrow Button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
