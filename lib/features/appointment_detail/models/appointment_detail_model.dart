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
  final String status;
  final String description;
  final String fees;
  final String grossProfit;
  final String netProfit;
  final String cleanerPay;
  final String gateWayFee;
  final String address;
  final String? addressLine1;
  final String? houseNumber;
  final String? apartmentNumber;
  final String? city;
  final String? state;
  final String? zipCode;
  final int? bedrooms;
  final int? bathrooms;
  final int? kitchens;
  final int? squareFootage;
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
    required this.status,
    required this.description,
    required this.fees,
    required this.grossProfit,
    required this.netProfit,
    required this.cleanerPay,
    required this.gateWayFee,
    required this.address,
    this.addressLine1,
    this.houseNumber,
    this.apartmentNumber,
    this.city,
    this.state,
    this.zipCode,
    this.bedrooms,
    this.bathrooms,
    this.kitchens,
    this.squareFootage,
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
    final List<dynamic>? rawOccurrences = (json["occurrences"] as List<dynamic>?) ?? (json["all_occurrences"] as List<dynamic>?);
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

    final addressRaw = json["addressDetails"] ?? json["address"];
    String addressString = "";
    String? addressLine1;
    String? houseNumber;
    String? apartmentNumber;
    String? city;
    String? state;
    String? zipCode;
    int? bedrooms;
    int? bathrooms;
    int? kitchens;
    int? squareFootage;

    if (addressRaw is Map<String, dynamic>) {
      addressLine1 = addressRaw["addressLine1"]?.toString() ?? json["addressLine1"]?.toString();
      houseNumber = addressRaw["houseNumber"]?.toString() ?? json["houseNumber"]?.toString();
      apartmentNumber = addressRaw["apartmentNumber"]?.toString() ?? json["apartmentNumber"]?.toString();
      city = addressRaw["city"]?.toString() ?? json["city"]?.toString();
      state = addressRaw["state"]?.toString() ?? json["state"]?.toString();
      zipCode = addressRaw["zipCode"]?.toString() ?? json["zipCode"]?.toString();
      bedrooms = addressRaw["bedrooms"] != null ? int.tryParse(addressRaw["bedrooms"].toString()) : null;
      bathrooms = addressRaw["bathrooms"] != null ? int.tryParse(addressRaw["bathrooms"].toString()) : null;
      kitchens = addressRaw["kitchens"] != null ? int.tryParse(addressRaw["kitchens"].toString()) : null;
      squareFootage = addressRaw["squareFootage"] != null ? int.tryParse(addressRaw["squareFootage"].toString()) : null;
    } else {
      addressString = addressRaw?.toString() ?? "";
      addressLine1 = json["addressLine1"]?.toString();
      houseNumber = json["houseNumber"]?.toString();
      apartmentNumber = json["apartmentNumber"]?.toString();
      city = json["city"]?.toString();
      state = json["state"]?.toString();
      zipCode = json["zipCode"]?.toString();
      bedrooms = json["bedrooms"] != null ? int.tryParse(json["bedrooms"].toString()) : null;
      bathrooms = json["bathrooms"] != null ? int.tryParse(json["bathrooms"].toString()) : null;
      kitchens = json["kitchens"] != null ? int.tryParse(json["kitchens"].toString()) : null;
      squareFootage = json["squareFootage"] != null ? int.tryParse(json["squareFootage"].toString()) : null;
    }

    return AppointmentDetailData(
      appointmentId: parsedId,
      type: json["type"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      fees: json["fees"]?.toString() ?? "0.00",
      grossProfit: json["gross_profit"]?.toString() ?? "0.00",
      netProfit: json["net_profit"]?.toString() ?? "0.00",
      cleanerPay: json["price"]?.toString() ?? json["cleaner_pay"]?.toString() ?? "",
      gateWayFee: json["gateway_fee"]?.toString() ?? "",
      address: addressString,
      addressLine1: addressLine1,
      houseNumber: houseNumber,
      apartmentNumber: apartmentNumber,
      city: city,
      state: state,
      zipCode: zipCode,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      kitchens: kitchens,
      squareFootage: squareFootage,
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

  String get fullAddress {
    List<String> parts = [];
    
    String line1 = "";
    if (houseNumber != null && houseNumber!.isNotEmpty) {
      line1 += houseNumber!;
    }
    if (addressLine1 != null && addressLine1!.isNotEmpty) {
      if (line1.isNotEmpty) line1 += " ";
      line1 += addressLine1!;
    }
    if (line1.isNotEmpty) parts.add(line1);
    
    if (apartmentNumber != null && apartmentNumber!.isNotEmpty) {
      parts.add("Apt $apartmentNumber");
    }
    
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return address;
  }
}
