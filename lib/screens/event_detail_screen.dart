import "dart:convert";
import "../core/utils/date_time_utils.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "dart:io";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:http/http.dart" as http;
import "package:url_launcher/url_launcher.dart";
import "../config/api_config.dart";
import "../services/localization_service.dart";
import "arrival_notification_screen.dart";
import "../features/profile/pages/profile_page.dart";
import "../features/profile/bindings/profile_binding.dart";
import "package:get/get.dart";
class EventDetailCleanerRequest {
  final String? avatar;

  EventDetailCleanerRequest({this.avatar});

  factory EventDetailCleanerRequest.fromJson(Map<String, dynamic> json) {
    return EventDetailCleanerRequest(avatar: json["avatar"]?.toString());
  }
}

class EventDetailCustomer {
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

  EventDetailCustomer({
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

  factory EventDetailCustomer.fromJson(Map<String, dynamic> json) {
    return EventDetailCustomer(
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

class EventDetailOccurrence {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  EventDetailOccurrence({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory EventDetailOccurrence.fromJson(Map<String, dynamic> json) {
    return EventDetailOccurrence(
      id: json["id"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["start_time"]?.toString() ?? "",
      endTime: json["end_time"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
    );
  }
}

class EventDetailData {
  final String occurrenceId;
  final String appointmentId;
  final String type;
  final String status;
  final String date;
  final String startTime;
  final String endTime;
  final EventDetailCustomer customer;
  final String? notesCleaner;
  final String? notesAdmin;
  final String grossProfit;
  final String? description;
  final String fees;
  final List<EventDetailCleanerRequest> cleanerRequests;
  final List<EventDetailOccurrence> allOccurrences;

  EventDetailData({
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
    required this.cleanerRequests,
    required this.allOccurrences,
  });

  factory EventDetailData.fromJson(Map<String, dynamic> json) {
    return EventDetailData(
      occurrenceId: json["occurrence_id"]?.toString() ?? "",
      appointmentId: json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      startTime: json["start_time"]?.toString() ?? "",
      endTime: json["end_time"]?.toString() ?? "",
      customer: EventDetailCustomer.fromJson(
        json["customer"] as Map<String, dynamic>? ?? {},
      ),
      notesCleaner: json["notes_cleaner"]?.toString(),
      notesAdmin: json["notes_admin"]?.toString(),
      grossProfit: json["gross_profit"]?.toString() ?? "0.00",
      description: json["description"]?.toString(),
      fees: json["fees"]?.toString() ?? "0.00",
      cleanerRequests: (json["cleaner_requests"] as List<dynamic>? ?? [])
          .map(
            (item) => EventDetailCleanerRequest.fromJson(
              item as Map<String, dynamic>? ?? {},
            ),
          )
          .toList(),
      allOccurrences: (json["all_occurrences"] as List<dynamic>? ?? [])
          .map(
            (item) => EventDetailOccurrence.fromJson(
              item as Map<String, dynamic>? ?? {},
            ),
          )
          .toList(),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final String occurrenceId;

  const EventDetailScreen({required this.occurrenceId, super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventDetailData? _eventDetailData;
  bool _isLoading = false;
  String? _error;
  String? _userImage;
  int? _cleanerId;

  bool _isUpdatingOnMyWay = false;
  bool _isUpdatingClockIn = false;
  bool _isUpdatingClockOut = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
    _fetchUserData();
  }

  Future<void> _fetchEventDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found for event detail");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = "Authentication token is missing.";
          });
        }
        return;
      }

      final Uri url = Uri.parse(
        ApiConfig.buildUrl(
          "/appointments/occurrence/${widget.occurrenceId}/detail",
        ),
      );

      debugPrint(
        "Fetching event detail for occurrence: ${widget.occurrenceId}",
      );
      debugPrint("Event Detail API URL: $url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("Event Detail API Response status: ${response.statusCode}");
      debugPrint("Event Detail API Response body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.headers["content-type"]?.contains("application/json") ==
            true) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            final bool success = data["success"] as bool? ?? false;

            if (success && data.containsKey("data")) {
              final Map<String, dynamic> dataMap =
                  data["data"] as Map<String, dynamic>;
              final EventDetailData eventDetailData = EventDetailData.fromJson(
                dataMap,
              );

              if (mounted) {
                setState(() {
                  _eventDetailData = eventDetailData;
                  _isLoading = false;
                  _error = null;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = "Invalid response format from server.";
                });
              }
            }
          } catch (e) {
            debugPrint("Error parsing event detail JSON response: $e");
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = "Error parsing response: $e";
              });
            }
          }
        } else {
          debugPrint("Response is not JSON");
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = "Invalid response format.";
            });
          }
        }
      } else {
        debugPrint(
          "Failed to fetch event detail. Status: ${response.statusCode}",
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error =
                "Failed to load event details. Code: ${response.statusCode}.";
          });
        }
      }
    } catch (e, stack) {
      debugPrint("Error fetching event detail: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Error loading event details: $e";
        });
      }
    }
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found for user data");
        return;
      }

      final url = Uri.parse(ApiConfig.buildUrl("/user"));

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("User API Response status: ${response.statusCode}");
      debugPrint("User API Response body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.headers["content-type"]?.contains("application/json") ==
            true) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            debugPrint("User API Parsed data: $data");

            if (mounted) {
              setState(() {
                _userImage = data["profile_url"]?.toString();
                final userData = data["user"] as Map<String, dynamic>?;
                if (userData != null) {
                  _cleanerId = data["id"] as int?;
                } else {
                  _cleanerId = data["id"] as int?;
                }
              });
            }
          } catch (e) {
            debugPrint("Error parsing user JSON response: $e");
          }
        }
      } else {
        debugPrint("Failed to fetch user data. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      debugPrint("Error fetching user data: $e");
      debugPrint("Stack trace: $stack");
    }
  }



  int calculateETA(String startTime, String endTime) {
    try {
      final startParts = startTime.split(":");
      final endParts = endTime.split(":");

      if (startParts.length >= 2 && endParts.length >= 2) {
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);

        final startTotalMinutes = startHour * 60 + startMinute;
        final endTotalMinutes = endHour * 60 + endMinute;

        int difference = endTotalMinutes - startTotalMinutes;

        if (difference < 0) {
          difference += 24 * 60; 
        }

        return difference;
      }
    } catch (e) {
      debugPrint("Error calculating ETA: $e");
    }
    return 0;
  }

  Future<void> _updateStatus(String status) async {
    if (_eventDetailData == null || _cleanerId == null) {
      debugPrint("Cannot update status: missing event data or cleaner ID");
      return;
    }

    setState(() {
      if (status == "on_my_way") {
        _isUpdatingOnMyWay = true;
      } else if (status == "checked_in") {
        _isUpdatingClockIn = true;
      } else if (status == "checked_out") {
        _isUpdatingClockOut = true;
      }
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found for status update");
        _resetLoadingStates(status);
        return;
      }

      final Uri url = Uri.parse(
        ApiConfig.buildUrl("/appointments/status-update"),
      );

      debugPrint("Updating status to: $status");

      Map<String, dynamic> requestBody = {
        "occurrence_id": widget.occurrenceId,
        "cleaner_id": _cleanerId,
        "status": status,
      };

      if (status == "on_my_way") {
        final int eta = calculateETA(
          _eventDetailData!.startTime,
          _eventDetailData!.endTime,
        );
        requestBody["eta"] = eta;
        requestBody["notes"] = _eventDetailData!.notesCleaner ?? "";
        debugPrint(
          "Parameters: occurrence_id=${widget.occurrenceId}, cleaner_id=$_cleanerId, status=$status, eta=$eta, notes=${requestBody["notes"]}",
        );
      } else {
        debugPrint(
          "Parameters: occurrence_id=${widget.occurrenceId}, cleaner_id=$_cleanerId, status=$status",
        );
      }

      debugPrint("Status Update API URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: json.encode(requestBody),
      );

      debugPrint("Status Update API Response status: ${response.statusCode}");
      debugPrint("Status Update API Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          final bool success = responseData["success"] as bool? ?? false;
          final String message =
              responseData["message"]?.toString() ??
              "Status updated successfully";

          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.green),
              );
            }
            await _fetchEventDetail();
          } else {
            final String errorMessage =
                responseData["message"]?.toString() ??
                "Failed to update status";
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("Error parsing status update response: $e");
          await _fetchEventDetail();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  LocalizationService().translate(
                    "events.statusUpdatedSuccessfully",
                  ),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        debugPrint("Failed to update status. Status: ${response.statusCode}");
        String errorMessage = "Failed to update status. Please try again.";
        try {
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          errorMessage = responseData["message"]?.toString() ?? errorMessage;
        } catch (e) {
          debugPrint("Error parsing error response: $e");
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, stack) {
      debugPrint("Error updating status: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translateWithParams(
                "events.errorUpdatingStatus",
                {"error": e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _resetLoadingStates(status);
    }
  }

  void _resetLoadingStates(String status) {
    if (mounted) {
      setState(() {
        if (status == "on_my_way") {
          _isUpdatingOnMyWay = false;
        } else if (status == "checked_in") {
          _isUpdatingClockIn = false;
        } else if (status == "checked_out") {
          _isUpdatingClockOut = false;
        }
      });
    }
  }

  String formatDateTime(String dateStr, String startTime, String endTime) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      final String formattedDate = DateFormat("MMM dd").format(date);
      final String formattedStartTime = DateTimeUtils.formatTime(startTime);
      final String formattedEndTime = DateTimeUtils.formatTime(endTime);
      return "$formattedDate, $formattedStartTime - $formattedEndTime";
    } catch (e) {
      debugPrint("Error formatting date time: $e");
      return "$dateStr, $startTime - $endTime";
    }
  }

  Map<String, dynamic> getStatusBadgeStyle(String status) {
    String statusText = status.replaceAll("_", " ").toUpperCase();
    Color statusBgColor = const Color(0xFFECFDF5);
    Color statusBorderColor = const Color(0xFFA4F4CF);
    Color statusTextColor = const Color(0xFF006045);

    if (status == "cleaner_assigned") {
      statusText = LocalizationService().translate("events.active");
    } else if (status == "on_my_way") {
      statusText = LocalizationService().translate(
        "arrivalNotification.onMyWay",
      );
      statusBgColor = const Color(0xFFE3F2FD);
      statusBorderColor = const Color(0xFF90CAF9);
      statusTextColor = const Color(0xFF1565C0);
    } else if (status == "checked_in") {
      statusText = LocalizationService().translate("events.check_in");
      statusBgColor = const Color(0xFFE8F5E9);
      statusBorderColor = const Color(0xFFA5D6A7);
      statusTextColor = const Color(0xFF2E7D32);
    } else if (status == "checked_out") {
      statusText = LocalizationService().translate("events.check_out");
      statusBgColor = const Color(0xFFE0E0E0);
      statusBorderColor = const Color(0xFFBDBDBD);
      statusTextColor = const Color(0xFF424242);
    } else if (status == "completed") {
      statusText = LocalizationService().translate("events.complete");
      statusBgColor = const Color(0xFFE0E0E0);
      statusBorderColor = const Color(0xFFBDBDBD);
      statusTextColor = const Color(0xFF424242);
    } else if (status == "cancelled") {
      statusText = LocalizationService().translate("events.cancel");
      statusBgColor = const Color(0xFFFFEBEE);
      statusBorderColor = const Color(0xFFFFCDD2);
      statusTextColor = const Color(0xFFC62828);
    }

    return {
      "text": statusText,
      "bgColor": statusBgColor,
      "borderColor": statusBorderColor,
      "textColor": statusTextColor,
    };
  }

  Future<void> openMaps(double lat, double lng) async {
    String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    String appleMapsUrl = "https://maps.apple.com/?q=$lat,$lng";

    if (Platform.isIOS) {
      final Uri appleUrl = Uri.parse(appleMapsUrl);
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final Uri googleUrl = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF77CCD9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          LocalizationService().translate("events.calendar"),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Get.to(() => const ProfilePage(), binding: ProfileBinding());
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: _userImage != null && _userImage!.isNotEmpty
                      ? Image.network(
                          _userImage!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.6),
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  "assets/images/placeholder.png",
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE0E0E0),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: Color(0xFF666666),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/placeholder.png",
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Color(0xFF666666),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                backgroundColor: Color(0xFF06E0FB),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchEventDetail,
                    child: Text(
                      LocalizationService().translate("common.retry"),
                    ),
                  ),
                ],
              ),
            )
          : _eventDetailData == null
          ? Center(
              child: Text(
                LocalizationService().translate("events.noEventDataAvailable"),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) {
                              final EventDetailCustomer? customer =
                                  _eventDetailData?.customer;
                              final String? customerLat = customer?.lat;
                              final String? customerLng = customer?.lng;

                              final String? streetViewUrl =
                                  ApiConfig.buildStreetViewUrl(
                                    customerLat,
                                    customerLng,
                                  );
                              print("Street View URL: ${streetViewUrl}");

                              final bool canOpenMaps =
                                  customerLat != null &&
                                  customerLat.isNotEmpty &&
                                  customerLng != null &&
                                  customerLng.isNotEmpty;

                              return GestureDetector(
                                onTap: canOpenMaps
                                    ? () async {
                                        debugPrint(
                                          "Street View image tapped - Opening maps",
                                        );
                                        try {
                                          final double lat = double.parse(
                                            customerLat,
                                          );
                                          final double lng = double.parse(
                                            customerLng,
                                          );
                                          debugPrint(
                                            "Opening maps with coordinates: lat=$lat, lng=$lng",
                                          );
                                          await openMaps(lat, lng);
                                        } catch (e) {
                                          debugPrint("Error opening maps: $e");
                                        }
                                      }
                                    : null,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      children: [
                                        streetViewUrl != null
                                            ? Image.network(
                                                streetViewUrl,
                                                width: double.infinity,
                                                height: 300,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Container(
                                                    height: 300,
                                                    width: double.infinity,
                                                    color: const Color(
                                                      0xFFE0E0E0,
                                                    ),
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        value:
                                                            loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2.0,
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF06E0FB,
                                                            ),
                                                        valueColor:
                                                            const AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.black),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                     
                                                      return Image.asset(
                                  "assets/images/placeholder.png",
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                );
                                                    },
                                              )
                                            : Image.asset(
                                  "assets/images/placeholder.png",
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                                        if (canOpenMaps)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: IgnorePointer(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.open_in_new,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildEventContent(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEventContent() {
    if (_eventDetailData == null) {
      return const SizedBox.shrink();
    }

    final data = _eventDetailData!;
    final statusStyle = getStatusBadgeStyle(data.status);
    final bool isOnMyWay = data.status == "on_my_way";
    final bool isCheckedIn = data.status == "checked_in";
    final bool isCheckedOut = data.status == "checked_out";

    final bool isAnyApiCalling =
        _isUpdatingOnMyWay || _isUpdatingClockIn || _isUpdatingClockOut;

    final bool onMyWayEnabled =
        _cleanerId != null && !isOnMyWay && !isCheckedIn && !isCheckedOut;
    final bool clockInEnabled =
        isOnMyWay && !isCheckedIn && !isCheckedOut && !isAnyApiCalling;
    final bool clockOutEnabled =
        isCheckedIn && !isCheckedOut && !isAnyApiCalling;

    return Transform.translate(
      offset: const Offset(0, -100),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEFBFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFe5e5ea), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              formatDateTime(
                                data.date,
                                data.startTime,
                                data.endTime,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusStyle["bgColor"] as Color,
                              border: Border.all(
                                color: statusStyle["borderColor"] as Color,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusStyle["text"] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: statusStyle["textColor"] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (data.description != null &&
                          data.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4a5565),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/reload.svg",
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.type == "one_time"
                            ? "${LocalizationService().translate("appointments.one_time")}"
                             : data.type == "recurring"
                            ? LocalizationService().translate(
                                "appointments.recurring",
                              )
                            : data.type,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/desc_icon.svg",
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.description ??
                              data.notesCleaner ??
                              data.customer.customerNotes ??
                              LocalizationService().translate(
                                "home.noDescriptionAvailable",
                              ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (data.customer.alarmGateCode != null &&
                      data.customer.alarmGateCode!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/svg/key.svg",
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.customer.alarmGateCode != null &&
                                    data.customer.alarmGateCode!.isNotEmpty
                                ? "${LocalizationService().translate("appointments.access_details_text")} ${data.customer.alarmGateCode}"
                                : "${LocalizationService().translate("appointments.access")}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: onMyWayEnabled
                        ? () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArrivalNotificationScreen(
                                  occurrenceId: widget.occurrenceId,
                                  cleanerId: _cleanerId!,
                                  currentStatus: data.status,
                                ),
                              ),
                            );
                            if (result == true) {
                              await _fetchEventDetail();
                            }
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: onMyWayEnabled
                            ? const Color(0xFF1e1e1e)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/svg/way_icon.svg",
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              onMyWayEnabled
                                  ? Colors.white
                                  : const Color(0xFF999999),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService().translate(
                              "arrivalNotification.onMyWay",
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: onMyWayEnabled
                                  ? Colors.white
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: clockInEnabled
                              ? () {
                                  _updateStatus("checked_in");
                                }
                              : null,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: clockInEnabled
                                    ? const Color(0xFF1e1e1e)
                                    : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: clockInEnabled
                                      ? const Color(0xFF00b8db)
                                      : const Color(0xFF999999),
                                  size: 20,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    LocalizationService().translate(
                                      "home.clockIn",
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: clockInEnabled
                                          ? const Color(0xFF313131)
                                          : const Color(0xFF999999),
                                    ),
                                  ),
                                ),
                                if (_isUpdatingClockIn) ...[
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        clockInEnabled
                                            ? const Color(0xFF00b8db)
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: clockOutEnabled
                              ? () {
                                  _updateStatus("checked_out");
                                }
                              : null,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: clockOutEnabled
                                    ? const Color(0xFF1e1e1e)
                                    : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/clock_out.svg",
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    clockOutEnabled
                                        ? const Color(0xFF313131)
                                        : const Color(0xFF999999),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    LocalizationService().translate(
                                      "home.clockOut",
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: clockOutEnabled
                                          ? const Color(0xFF313131)
                                          : const Color(0xFF999999),
                                    ),
                                  ),
                                ),
                                if (_isUpdatingClockOut) ...[
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        clockOutEnabled
                                            ? const Color(0xFF313131)
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  LocalizationService().translate("events.customer_notes"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf9fafb),
                    border: Border.all(
                      color: const Color(0xFFe5e7eb),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.notesCleaner ??
                        data.customer.customerNotes ??
                        LocalizationService().translate(
                          "home.noNotesAvailable",
                        ),

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4a5565),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (data.customer.bedrooms != null)
                      _buildTag(
                        "${data.customer.bedrooms} ${LocalizationService().translate(
                          "events.bedroom"
                        )}${data.customer.bedrooms! > 1 ? "s" : ""}",
                      ),
                    if (data.customer.bathrooms != null)
                      _buildTag(
                        "${data.customer.bathrooms}  ${LocalizationService().translate(
                          "events.washroom"
                        )}${data.customer.bathrooms! > 1 ? "s" : ""}",
                      ),
                    if (data.customer.kitchen != null &&
                        data.customer.kitchen! > 0)
                      _buildTag(
                        "${data.customer.kitchen}  ${LocalizationService().translate(
                          "events.kitchen"
                        )}${data.customer.kitchen! > 1 ? "s" : ""}",
                      ),
                    if (data.customer.pets != null && data.customer.pets! > 0)
                      _buildTag(
                        "${data.customer.pets}  ${LocalizationService().translate(
                          "events.pet"
                        )}${data.customer.pets! > 1 ? "s" : ""}",
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (data.notesAdmin != null && data.notesAdmin!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService().translate(
                      "appointments.notesFromAdmin",
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf9fafb),
                      border: Border.all(
                        color: const Color(0xFFe5e7eb),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data.notesAdmin!,

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4a5565),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFcac4d0), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF49454f),
        ),
      ),
    );
  }
}
