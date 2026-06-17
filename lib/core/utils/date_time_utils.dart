class DateTimeUtils {
  static String formatTime(String timeStr) {
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
    } catch (e) {
      // ignore
    }
    return timeStr;
  }
}
