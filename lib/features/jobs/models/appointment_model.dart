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
  final String jobId;
  final String type;
  final String description;
  final String pay;
  final String address;
  final String date;
  final String startTime;
  final String endTime;
  final List<AppointmentOccurrence> occurrences;
  final String customerName;

  // Additional fields for detailed completed job information
  final String? paymentStatus;
  final String? paymentMethod;
  final String? grossProfit;
  final String? gatewayFee;
  final String? netProfit;
  final String? cleanerPayoutStatus;
  final String? status;
  final int? bedrooms;
  final int? bathrooms;
  final int? kitchen;
  final int? squareFootage;
  final String? notesCleaner;
  final Map<String, dynamic>? rawJson;

  const Appointment({
    required this.appointmentId,
    required this.jobId,
    required this.type,
    required this.description,
    required this.pay,
    required this.address,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.occurrences,
    required this.customerName,
    this.paymentStatus,
    this.paymentMethod,
    this.grossProfit,
    this.gatewayFee,
    this.netProfit,
    this.cleanerPayoutStatus,
    this.status,
    this.bedrooms,
    this.bathrooms,
    this.kitchen,
    this.squareFootage,
    this.notesCleaner,
    this.rawJson,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final String parsedAppointmentId = json["appointment_id"]?.toString() ?? json["occurrence_id"]?.toString() ?? json["id"]?.toString() ?? "0";
    final String parsedJobId = json["job_id"]?.toString() ?? (json["job"] != null ? json["job"]["id"]?.toString() : null) ?? json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "0";
    
    final List<dynamic>? rawOccurrences =
        json["all_occurrences"] as List<dynamic>?;
    final List<AppointmentOccurrence> parsedOccurrences = rawOccurrences == null
        ? <AppointmentOccurrence>[]
        : rawOccurrences
              .whereType<Map<String, dynamic>>()
              .map(AppointmentOccurrence.fromJson)
              .toList();

    String customerName = json["name"]?.toString() ?? "";
    if (customerName.isEmpty && json["customer"] != null && json["customer"] is Map<String, dynamic>) {
      final customer = json["customer"] as Map<String, dynamic>;
      customerName = customer["name"]?.toString() ?? "";
      if (customerName.isEmpty) {
        final firstName = customer["firstName"]?.toString() ?? "";
        final lastName = customer["lastName"]?.toString() ?? "";
        customerName = "$firstName $lastName".trim();
      }
    }

    final Map<String, dynamic>? customerObj = json["customer"] is Map<String, dynamic> ? json["customer"] as Map<String, dynamic> : null;
    final int? bedrooms = customerObj?["bedrooms"] is int ? customerObj!["bedrooms"] as int : int.tryParse(customerObj?["bedrooms"]?.toString() ?? "");
    final int? bathrooms = customerObj?["bathrooms"] is int ? customerObj!["bathrooms"] as int : int.tryParse(customerObj?["bathrooms"]?.toString() ?? "");
    final int? kitchen = customerObj?["kitchen"] is int ? customerObj!["kitchen"] as int : int.tryParse(customerObj?["kitchen"]?.toString() ?? "");
    final int? squareFootage = customerObj?["square_footage"] is int ? customerObj!["square_footage"] as int : int.tryParse(customerObj?["square_footage"]?.toString() ?? "");

    return Appointment(
      appointmentId: parsedAppointmentId,
      jobId: parsedJobId,
      type: json["title"]?.toString() ?? json["type"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      pay: json["cleaner_pay"]?.toString() ?? json["price"]?.toString() ?? "0.00",
      address: json["address"]?.toString() ?? (customerObj?["address"]?.toString() ?? ""),
      date: json["date"]?.toString() ?? "",
      startTime: json["startTime"]?.toString() ?? json["start_time"]?.toString() ?? "",
      endTime: json["endTime"]?.toString() ?? json["end_time"]?.toString() ?? "",
      occurrences: parsedOccurrences,
      customerName: customerName,
      paymentStatus: json["payment_status"]?.toString(),
      paymentMethod: json["payment_method"]?.toString(),
      grossProfit: json["gross_profit"]?.toString(),
      gatewayFee: json["gateway_fee"]?.toString(),
      netProfit: json["net_profit"]?.toString(),
      cleanerPayoutStatus: json["cleaner_payout_status"]?.toString(),
      status: json["status"]?.toString(),
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      kitchen: kitchen,
      squareFootage: squareFootage,
      notesCleaner: json["notes_cleaner"]?.toString(),
      rawJson: json,
    );
  }
}
