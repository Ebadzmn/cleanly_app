import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime dateTime;
    try {
      final String? timestampStr = map["timestamp"]?.toString();
      if (timestampStr != null) {
        dateTime = DateTime.parse(timestampStr);
      } else {
        dateTime = DateTime.now();
      }
    } catch (e) {
      debugPrint("Error parsing timestamp: $e");
      dateTime = DateTime.now();
    }

    return NotificationModel(
      id: map["id"]?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map["title"]?.toString() ?? "Notification",
      body: map["body"]?.toString() ?? "",
      timestamp: dateTime,
      data: map["data"] as Map<String, dynamic>?,
    );
  }

  String get formattedTime {
    final int hour = timestamp.hour;
    final int minute = timestamp.minute;
    final String period = hour >= 12 ? "PM" : "AM";
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String minuteStr = minute.toString().padLeft(2, "0");
    return "$displayHour:$minuteStr $period";
  }
}
