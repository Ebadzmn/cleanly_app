import re
import sys

def modify_time(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    new_func = '''  String formatTime(String timeStr) {
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
  }'''

    # Find the function in home_screen.dart
    # _buildUpNextCard contains a nested formatTime function
    # _buildAppointmentCard contains a nested formatTime function
    # EventDetailScreen contains a member formatTime function

    # We can just use python to replace them all
    pattern = r'String formatTime\(String timeStr\) \{[\s\S]*?return timeStr;\n    \}'
    content = re.sub(pattern, new_func, content)

    with open(file_path, 'w') as f:
        f.write(content)

modify_time("lib/screens/home_screen.dart")
modify_time("lib/screens/event_detail_screen.dart")
