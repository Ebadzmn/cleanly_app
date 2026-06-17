class AppointmentOccurrenceDetail {
  final String id;
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
      id: json["id"]?.toString() ?? "",
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
  final String lat;
  final String lng;
  final String email;
  final String phoneNumber;
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
    required this.lat,
    required this.lng,
    required this.email,
    required this.phoneNumber,
    required this.allOccurrences,
  });

  factory AppointmentDetailData.fromJson(Map<String, dynamic> json) {
    final String parsedId = json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "";
    final List<dynamic>? rawOccurrences = json["all_occurrences"] as List<dynamic>?;
    final List<AppointmentOccurrenceDetail> occurrences = rawOccurrences == null
        ? <AppointmentOccurrenceDetail>[]
        : rawOccurrences
              .whereType<Map<String, dynamic>>()
              .map(AppointmentOccurrenceDetail.fromJson)
              .toList();

    String parsedEmail = json["email"]?.toString() ?? json["customer_email"]?.toString() ?? json["user_email"]?.toString() ?? json["client_email"]?.toString() ?? "";
    String parsedPhone = json["phone"]?.toString() ?? json["phone_number"]?.toString() ?? json["customer_phone"]?.toString() ?? json["mobile"]?.toString() ?? json["contact_number"]?.toString() ?? json["client_phone"]?.toString() ?? "";

    if (parsedEmail.isEmpty && json["customer"] != null) {
      parsedEmail = json["customer"]["email"]?.toString() ?? "";
    }
    if (parsedPhone.isEmpty && json["customer"] != null) {
      parsedPhone = json["customer"]["phone"]?.toString() ?? json["customer"]["phone_number"]?.toString() ?? json["customer"]["mobile"]?.toString() ?? json["customer"]["contact_number"]?.toString() ?? "";
    }

    if (parsedEmail.isEmpty && json["user"] != null) {
      parsedEmail = json["user"]["email"]?.toString() ?? "";
    }
    if (parsedPhone.isEmpty && json["user"] != null) {
      parsedPhone = json["user"]["phone"]?.toString() ?? json["user"]["phone_number"]?.toString() ?? json["user"]["mobile"]?.toString() ?? json["user"]["contact_number"]?.toString() ?? "";
    }
    
    if (parsedEmail.isEmpty && json["client"] != null) {
      parsedEmail = json["client"]["email"]?.toString() ?? "";
    }
    if (parsedPhone.isEmpty && json["client"] != null) {
      parsedPhone = json["client"]["phone"]?.toString() ?? json["client"]["phone_number"]?.toString() ?? json["client"]["mobile"]?.toString() ?? json["client"]["contact_number"]?.toString() ?? "";
    }

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
      lat: json["lat"]?.toString() ?? json["latitude"]?.toString() ?? "",
      lng: json["lng"]?.toString() ?? json["longitude"]?.toString() ?? "",
      email: parsedEmail,
      phoneNumber: parsedPhone,
      notesCleaner: json["notes_cleaner"]?.toString(),
      notesAdmin: json["notes_admin"]?.toString(),
      allOccurrences: occurrences,
    );
  }
}
