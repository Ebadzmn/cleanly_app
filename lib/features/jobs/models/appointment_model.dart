class AppointmentOccurrence {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String customerName;

  const AppointmentOccurrence({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.customerName,
  });

  factory AppointmentOccurrence.fromJson(Map<String, dynamic> json) {
    final int parsedId = (json["id"] as num?)?.toInt() ?? 0;
    return AppointmentOccurrence(
      id: parsedId,
      date: json["date"]?.toString() ?? "",
      startTime: json["start_time"]?.toString() ?? "",
      endTime: json["end_time"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      customerName: json["name"]?.toString() ?? "",
    );
  }
}

class Appointment {
  final int appointmentId;
  final String type;
  final String description;
  final String pay;
  final String address;
  final String date;
  final String startTime;
  final String endTime;
  final List<AppointmentOccurrence> occurrences;
  final String customerName;

  const Appointment({
    required this.appointmentId,
    required this.type,
    required this.description,
    required this.pay,
    required this.address,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.occurrences,
    required this.customerName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final int parsedId = (json["appointment_id"] as num?)?.toInt() ?? 0;
    final List<dynamic>? rawOccurrences =
        json["all_occurrences"] as List<dynamic>?;
    final List<AppointmentOccurrence> parsedOccurrences = rawOccurrences == null
        ? <AppointmentOccurrence>[]
        : rawOccurrences
              .whereType<Map<String, dynamic>>()
              .map(AppointmentOccurrence.fromJson)
              .toList();

    return Appointment(
      appointmentId: parsedId,
      type: json["type"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      pay: json["cleaner_pay"]?.toString() ?? "0.00",
      address: json["address"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["start_time"]?.toString() ?? "",
      endTime: json["end_time"]?.toString() ?? "",
      occurrences: parsedOccurrences,
      customerName: json["name"]?.toString() ?? "",
    );
  }
}
