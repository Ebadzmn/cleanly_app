import 'package:flutter/material.dart';
import '../../../../services/localization_service.dart';
import 'package:intl/intl.dart';
import '../domain/models/appointment_models.dart';
import 'appointment_card_widget.dart';

class AgendaDayCardWidget extends StatelessWidget {
  final DateTime date;
  final String tagText;
  final Color tagBgColor;
  final Color tagTextColor;
  final Color borderColor;
  final List<Appointment> appointments;

  const AgendaDayCardWidget({
    Key? key,
    required this.date,
    required this.tagText,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.borderColor,
    required this.appointments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String dateStr = DateFormat("EEE dd MMM").format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F4F7), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
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
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Color(0xFF90702F),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2638),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tagText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: tagTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (appointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            LocalizationService().translate("home.noAppointmentsBooked") ?? "No appointments booked",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ),
                      )
                    else
                      ...appointments.map(
                        (appt) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppointmentCardWidget(appointment: appt),
                        ),
                      ).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
