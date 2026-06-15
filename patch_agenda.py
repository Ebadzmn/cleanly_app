import re
import sys

def patch_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # We will replace _buildAgendaDayCard entirely
    agenda_day_pattern = r'''  Widget _buildAgendaDayCard\([\s\S]*?  List<Widget> _buildEventSections'''
    
    new_agenda_day = '''  Widget _buildAgendaDayCard(
    DateTime date,
    String tagText,
    Color tagBgColor,
    Color tagTextColor,
    Color borderColor,
    List<Appointment> appointments,
  ) {
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
                        child: const Center(
                          child: Text(
                            "No appointments booked",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ),
                      )
                    else
                      ...appointments
                          .map(
                            (appt) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAppointmentCard(appt),
                            ),
                          )
                          .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventSections'''

    content = re.sub(agenda_day_pattern, new_agenda_day, content)

    # Now replace _buildAppointmentCard entirely
    appt_pattern = r'''  Widget _buildAppointmentCard\(Appointment appointment\) \{[\s\S]*?            \],
          \),
        \),
      \),
    \);
  \}'''

    new_appt = '''  Widget _buildAppointmentCard(Appointment appointment) {
    String formatTime(String timeStr) {
      try {
        if (timeStr.toUpperCase().contains("AM") || timeStr.toUpperCase().contains("PM")) {
          return timeStr;
        }
        final parts = timeStr.split(":");
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
          final minute = int.parse(minuteStr);
          final period = hour >= 12 ? "PM" : "AM";
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          return "$displayHour:${minute.toString().padLeft(2, "0")} $period";
        }
      } catch (e) {}
      return timeStr;
    }

    final String startTimeFormatted = formatTime(appointment.startTime);
    final String endTimeFormatted = formatTime(appointment.endTime);
    
    final String title = (appointment.type == "one_time" ? "One Time Service" : appointment.type).isNotEmpty ? (appointment.type == "one_time" ? "One Time Service" : appointment.type) : "Estate Valuation";
    final String clientName = "Client: ${appointment.customer.name ?? 'Unknown'}";
    final String address = appointment.customer.address ?? "Address not available";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(occurrenceId: appointment.occurrenceId),
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
  }'''

    content = re.sub(appt_pattern, new_appt, content)

    with open(file_path, 'w') as f:
        f.write(content)

patch_file(sys.argv[1])
