import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "../config/api_config.dart";
import "../services/notification_service.dart";
import "home_screen.dart";
import "../services/localization_service.dart";
import "../features/profile/pages/profile_page.dart";
import "../features/profile/bindings/profile_binding.dart";
import "package:get/get.dart";
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
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

    return NotificationItem(
      id:
          map["id"]?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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

class _NotificationScreenState extends State<NotificationScreen> {
  String? _userImage;
  bool _isInitialLoading = true;
  List<NotificationItem> _notifications = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadNotifications(isRefresh: false);

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadNotifications(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found");
        return;
      }

      final Uri url = Uri.parse(ApiConfig.buildUrl("/user"));

      final http.Response response = await http.get(
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
            final Map<String, dynamic> data =
                json.decode(response.body) as Map<String, dynamic>;
            debugPrint("User API Parsed data: $data");

            if (mounted) {
              setState(() {
                _userImage = data["profile_url"]?.toString();
              });
            }
          } catch (e) {
            debugPrint("Error parsing JSON response: $e");
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

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (!mounted) return;

    if (!isRefresh) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    try {
      final List<Map<String, dynamic>> storedNotifications =
          await NotificationService.getStoredNotifications();

      if (mounted) {
        setState(() {
          _notifications = storedNotifications
              .map((map) => NotificationItem.fromMap(map))
              .toList();
          _isInitialLoading = false;
        });
        debugPrint(
          "Loaded ${_notifications.length} notifications from local storage",
        );
      }
    } catch (e, stack) {
      debugPrint("Error loading notifications: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
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
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(8),
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
          LocalizationService().translate("notifications.title"),
          style: TextStyle(
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
                            padding: const EdgeInsets.all(8),
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
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
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
                          ),
                        ),
                      ),
              ),
            ),
            ),
          ),
        ],
      ),

      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                backgroundColor: Color(0xFF06E0FB),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: _notifications.isEmpty
                        ? RefreshIndicator(
                            strokeWidth: 2.0,
                            backgroundColor: const Color(0xFF06E0FB),
                            color: Colors.black,
                            onRefresh: () =>
                                _loadNotifications(isRefresh: true),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child:  Center(
                                  child: Text(
                                    LocalizationService().translate("notifications.noNotifications"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF6a7282),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                                strokeWidth: 2.0,
      backgroundColor: const Color(0xFF06E0FB),
      color: Colors.black,
                            onRefresh: () =>
                                _loadNotifications(isRefresh: true),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(
                                  _notifications[index],
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFfe5e5ea), width: 1),
      ),
      child: Row(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/svg/bell_icon.svg",
                width: 20,
                height: 20,
                color: const Color(0xFF77ccd9),
              ),
              const SizedBox(width: 8),
              Container(width: 1.5, height: 60, color: const Color(0xFF77ccd9)),
            ],
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6a7282),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Text(
            notification.formattedTime,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4a5565),
            ),
          ),
        ],
      ),
    );
  }
}
