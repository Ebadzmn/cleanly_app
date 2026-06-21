class AppointmentOccurrence {
  final String id;
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
    final String parsedId = json["id"]?.toString() ?? "0";
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
  final String appointmentId;
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
    final String parsedId = json["occurrence_id"]?.toString() ?? json["id"]?.toString() ?? json["appointment_id"]?.toString() ?? "0";
    final List<dynamic>? rawOccurrences =
        json["all_occurrences"] as List<dynamic>?;
    final List<AppointmentOccurrence> parsedOccurrences = rawOccurrences == null
        ? <AppointmentOccurrence>[]
        : rawOccurrences
              .whereType<Map<String, dynamic>>()
              .map(AppointmentOccurrence.fromJson)
              .toList();

    String customerName = json["name"]?.toString() ?? "";
    if (customerName.isEmpty && json["customer"] != null) {
      final customer = json["customer"];
      customerName = customer["name"]?.toString() ?? "";
      if (customerName.isEmpty) {
        final firstName = customer["firstName"]?.toString() ?? "";
        final lastName = customer["lastName"]?.toString() ?? "";
        customerName = "$firstName $lastName".trim();
      }
    }

    return Appointment(
      appointmentId: parsedId,
      type: json["title"]?.toString() ?? json["type"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      pay: json["price"]?.toString() ?? json["cleaner_pay"]?.toString() ?? "0.00",
      address: json["address"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["startTime"]?.toString() ?? json["start_time"]?.toString() ?? "",
      endTime: json["endTime"]?.toString() ?? json["end_time"]?.toString() ?? "",
      occurrences: parsedOccurrences,
      customerName: customerName,
    );
  }
}
