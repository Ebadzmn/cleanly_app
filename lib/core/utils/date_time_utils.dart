import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Formats a raw date string (e.g. "2026-08-28T00:00:00.000Z" or "2026-08-28")
  /// into a clean, human-readable date format like "Aug 28, 2026".
  static String formatDate(String dateStr) {
    if (dateStr.isEmpty) return "";
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        return DateFormat("MMM dd, yyyy").format(dt);
      }
    } catch (_) {}

    if (dateStr.contains("T")) {
      final clean = dateStr.split("T").first;
      try {
        final dt = DateTime.tryParse(clean);
        if (dt != null) {
          return DateFormat("MMM dd, yyyy").format(dt);
        }
      } catch (_) {}
      return clean;
    }
    return dateStr;
  }

  /// Formats a raw time string (e.g. "09:00:00" or "09:00 - 11:00")
  /// into 12-hour AM/PM format (e.g. "9:00 AM" or "09:00 AM - 11:00 AM").
  static String formatTime(String timeStr) {
    if (timeStr.isEmpty) return "";
    if (timeStr.contains("-")) {
      final parts = timeStr.split("-");
      if (parts.length == 2) {
        final start = formatSingleTime(parts[0].trim());
        final end = formatSingleTime(parts[1].trim());
        return "$start - $end";
      }
    }
    return formatSingleTime(timeStr);
  }

  static String formatSingleTime(String timeStr) {
    if (timeStr.isEmpty) return "";
    try {
      if (timeStr.toUpperCase().contains("AM") ||
          timeStr.toUpperCase().contains("PM")) {
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

  /// Helper to combine date & time formatted cleanly
  static String formatDateTime(String dateStr, String timeStr) {
    final formattedDate = formatDate(dateStr);
    final formattedTime = formatTime(timeStr);
    if (formattedDate.isNotEmpty && formattedTime.isNotEmpty) {
      return "$formattedDate • $formattedTime";
    }
    return formattedDate.isNotEmpty ? formattedDate : formattedTime;
  }
}

