class CleanerRequest {
  final String? avatar;

  CleanerRequest({this.avatar});

  factory CleanerRequest.fromJson(Map<String, dynamic> json) {
    return CleanerRequest(avatar: json["avatar"]?.toString());
  }
}

class Customer {
  final String id;
  final String? title;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? preferredPaymentMethod;
  final String? marketingSource;
  final String? phoneNumber;
  final String? email;
  final bool sendAutomatedEmails;
  final String? address;
  final String? customerNotes;
  final int? bedrooms;
  final int? squareFootage;
  final int? bathrooms;
  final int? kitchen;
  final int? pets;
  final String? preferredCleaners;
  final String? alarmGateCode;
  final String? lat;
  final String? lng;
  final String? fullName;

  Customer({
    required this.id,
    this.title,
    this.name,
    this.firstName,
    this.lastName,
    this.company,
    this.preferredPaymentMethod,
    this.marketingSource,
    this.phoneNumber,
    this.email,
    required this.sendAutomatedEmails,
    this.address,
    this.customerNotes,
    this.bedrooms,
    this.squareFootage,
    this.bathrooms,
    this.kitchen,
    this.pets,
    this.preferredCleaners,
    this.alarmGateCode,
    this.lat,
    this.lng,
    this.fullName,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json["id"]?.toString() ?? "",
      title: json["title"]?.toString(),
      name: json["name"]?.toString(),
      firstName: json["first_name"]?.toString(),
      lastName: json["last_name"]?.toString(),
      company: json["company"]?.toString(),
      preferredPaymentMethod: json["preferred_payment_method"]?.toString(),
      marketingSource: json["marketing_source"]?.toString(),
      phoneNumber: json["phone_number"]?.toString(),
      email: json["email"]?.toString(),
      sendAutomatedEmails: json["send_automated_emails"] as bool? ?? false,
      address: json["address"]?.toString(),
      customerNotes: json["customer_notes"]?.toString(),
      bedrooms: json["bedrooms"] as int?,
      squareFootage: json["square_footage"] as int?,
      bathrooms: json["bathrooms"] as int?,
      kitchen: json["kitchen"] as int?,
      pets: json["pets"] as int?,
      preferredCleaners: json["preferred_cleaners"]?.toString(),
      alarmGateCode: json["alarm_gate_code"]?.toString(),
      lat: json["lat"]?.toString(),
      lng: json["lng"]?.toString(),
      fullName: json["full_name"]?.toString(),
    );
  }
}

class Occurrence {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  Occurrence({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Occurrence.fromJson(Map<String, dynamic> json) {
    return Occurrence(
      id: json["id"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["start_time"]?.toString() ?? "",
      endTime: json["end_time"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
    );
  }
}

class Appointment {
  final String occurrenceId;
  final String appointmentId;
  final String type;
  final String status;
  final String date;
  final String startTime;
  final String endTime;
  final Customer customer;
  final String? notesCleaner;
  final String? notesAdmin;
  final String grossProfit;
  final String? description;
  final String fees;
  final String cleanerPay;
  final List<CleanerRequest> cleanerRequests;
  final List<Occurrence> allOccurrences;

  Appointment({
    required this.occurrenceId,
    required this.appointmentId,
    required this.type,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.customer,
    this.notesCleaner,
    this.notesAdmin,
    required this.grossProfit,
    this.description,
    required this.fees,
    required this.cleanerPay,
    required this.cleanerRequests,
    required this.allOccurrences,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      occurrenceId: json["occurrence_id"]?.toString() ?? "",
      appointmentId: json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "0",
      type: json["title"]?.toString() ?? json["type"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["startTime"]?.toString() ?? json["start_time"]?.toString() ?? "",
      endTime: json["endTime"]?.toString() ?? json["end_time"]?.toString() ?? "",
      customer: Customer.fromJson(
        json["customer"] != null ? (json["customer"] as Map<String, dynamic>) : json,
      ),
      notesCleaner: json["notes_cleaner"]?.toString(),
      notesAdmin: json["notes_admin"]?.toString(),
      grossProfit: json["gross_profit"]?.toString() ?? "0.00",
      description: json["description"]?.toString(),
      fees: json["price"]?.toString() ?? json["fees"]?.toString() ?? "0.00",
      cleanerPay: json["cleaner_pay"]?.toString() ?? "0.00",
      cleanerRequests: (json["cleaner_requests"] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CleanerRequest.fromJson(item as Map<String, dynamic>? ?? {}),
          )
          .toList(),
      allOccurrences: (json["all_occurrences"] as List<dynamic>? ?? [])
          .map(
            (item) => Occurrence.fromJson(item as Map<String, dynamic>? ?? {}),
          )
          .toList(),
    );
  }
}

class UpcomingDate {
  final String date;
  final List<Appointment> data;

  UpcomingDate({required this.date, required this.data});

  factory UpcomingDate.fromJson(Map<String, dynamic> json) {
    return UpcomingDate(
      date: json["date"]?.toString() ?? "",
      data: (json["data"] as List<dynamic>? ?? [])
          .map(
            (item) => Appointment.fromJson(item as Map<String, dynamic>? ?? {}),
          )
          .toList(),
    );
  }
}

class AppointmentsResponse {
  final List<UpcomingDate> upcoming;
  final bool success;
  final String message;

  AppointmentsResponse({
    required this.upcoming,
    required this.success,
    required this.message,
  });

  factory AppointmentsResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentsResponse(
      success: json["success"] as bool? ?? false,
      message: json["message"]?.toString() ?? "",
      upcoming: (json["data"]?["upcoming"] as List<dynamic>? ?? [])
          .map(
            (item) => UpcomingDate.fromJson(item as Map<String, dynamic>? ?? {}),
          )
          .toList(),
    );
  }
}
