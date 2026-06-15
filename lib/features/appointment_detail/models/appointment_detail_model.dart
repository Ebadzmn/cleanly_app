class AppointmentOccurrenceDetail {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  const AppointmentOccurrenceDetail({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory AppointmentOccurrenceDetail.fromJson(Map<String, dynamic> json) {
    return AppointmentOccurrenceDetail(
      id: (json["id"] as num?)?.toInt() ?? 0,
      date: json["date"]?.toString() ?? "",
      startTime: json["start_time"]?.toString() ?? "",
      endTime: json["end_time"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
    );
  }
}

class AppointmentDetailData {
  final String appointmentId;
  final String type;
  final String description;
  final String fees;
  final String grossProfit;
  final String netProfit;
  final String cleanerPay;
  final String gateWayFee;
  final String address;
  final String name;
  final String title;
  final String firstName;
  final String lastName;
  final String date;
  final String startTime;
  final String endTime;
  final String? notesCleaner;
  final String? notesAdmin;
  final List<AppointmentOccurrenceDetail> allOccurrences;

  const AppointmentDetailData({
    required this.appointmentId,
    required this.type,
    required this.description,
    required this.fees,
    required this.grossProfit,
    required this.netProfit,
    required this.cleanerPay,
    required this.gateWayFee,
    required this.address,
    required this.name,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notesCleaner,
    this.notesAdmin,
    required this.allOccurrences,
  });

  factory AppointmentDetailData.fromJson(Map<String, dynamic> json) {
    final String parsedId = json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "0";
    final List<dynamic>? rawOccurrences = json["all_occurrences"] as List<dynamic>?;
    final List<AppointmentOccurrenceDetail> occurrences = rawOccurrences == null
        ? <AppointmentOccurrenceDetail>[]
        : rawOccurrences
              .whereType<Map<String, dynamic>>()
              .map(AppointmentOccurrenceDetail.fromJson)
              .toList();

    return AppointmentDetailData(
      appointmentId: parsedId,
      type: json["type"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      fees: json["fees"]?.toString() ?? "0.00",
      grossProfit: json["gross_profit"]?.toString() ?? "0.00",
      netProfit: json["net_profit"]?.toString() ?? "0.00",
      cleanerPay: json["price"]?.toString() ?? json["cleaner_pay"]?.toString() ?? "",
      gateWayFee: json["gateway_fee"]?.toString() ?? "",
      address: json["address"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      firstName: json["first_name"]?.toString() ?? "",
      lastName: json["last_name"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["startTime"]?.toString() ?? json["start_time"]?.toString() ?? "",
      endTime: json["endTime"]?.toString() ?? json["end_time"]?.toString() ?? "",
      notesCleaner: json["notes_cleaner"]?.toString(),
      notesAdmin: json["notes_admin"]?.toString(),
      allOccurrences: occurrences,
    );
  }
}
