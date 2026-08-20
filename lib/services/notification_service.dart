import "dart:convert";
import "package:get/get.dart";
import "../features/appointment_detail/pages/appointment_detail_page.dart";

import "package:cleanly_app/firebase_file/firebase_options.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Error initializing Firebase in background handler: $e');
  }

  print("========== 🔔 BACKGROUND FCM RECEIVED ==========");
  print("Message ID: ${message.messageId}");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${json.encode(message.data)}");
  print("===============================================");

  try {
    await NotificationService._storeNotificationLocallyStatic(
      message.notification?.title ?? '',
      message.notification?.body ?? "",
      message.data,
    );
    debugPrint("Background notification processed successfully");
  } catch (e) {
    debugPrint('Error processing background notification: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized');
      return;
    }

    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }

      await _initializeLocalNotifications();

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

      await _getFCMToken();

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  String? get fcmToken => _fcmToken;

  Future<ByteArrayAndroidBitmap?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      } else {
        debugPrint('Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }

  String? _getImageUrl(RemoteMessage message) {
    if (message.data.containsKey('image')) {
      return message.data['image'] as String?;
    }
    if (message.data.containsKey('image_url')) {
      return message.data['image_url'] as String?;
    }
    if (message.data.containsKey('imageUrl')) {
      return message.data['imageUrl'] as String?;
    }
    if (message.notification?.android?.imageUrl != null) {
      return message.notification!.android!.imageUrl;
    }
    return null;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("========== 🔔 FOREGROUND FCM RECEIVED ==========");
    print("Message ID: ${message.messageId}");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${json.encode(message.data)}");
    print("===============================================");

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      String? imageUrl = _getImageUrl(message);
      ByteArrayAndroidBitmap? bigPicture;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        debugPrint('Image URL found: $imageUrl');
        bigPicture = await _downloadImage(imageUrl);
      }

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_launcher_icon',
        largeIcon: bigPicture,
        styleInformation: bigPicture != null
            ? BigPictureStyleInformation(
                bigPicture,
                contentTitle: notification.title,
                summaryText: notification.body,
              )
            : null,
      );

      final Map<String, dynamic> payloadMap = Map<String, dynamic>.from(message.data);
      if (notification.title != null) {
        payloadMap["_notification_title"] = notification.title;
        payloadMap["title"] = notification.title;
      }
      if (notification.body != null) {
        payloadMap["body"] = notification.body;
      }

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(payloadMap),
      );

      await _storeNotificationLocally(
        notification.title ?? '',
        notification.body ?? "",
        message.data,
      );
    }
  }

  Future<void> _storeNotificationLocally(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String notificationsKey = "notifications_list";

      final String? existingJson = prefs.getString(notificationsKey);
      List<Map<String, dynamic>> notifications = [];

      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          final List<dynamic> decoded =
              json.decode(existingJson) as List<dynamic>;
          notifications = decoded
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } catch (e) {
          debugPrint("Error parsing existing notifications: $e");
        }
      }

      final Map<String, dynamic> newNotification = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": title,
        "body": body,
        "timestamp": DateTime.now().toIso8601String(),
        "data": data ?? <String, dynamic>{},
      };

      notifications.insert(0, newNotification);

      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      final String updatedJson = json.encode(notifications);
      await prefs.setString(notificationsKey, updatedJson);

      debugPrint("Notification stored locally: $title");
    } catch (e) {
      debugPrint("Error storing notification locally: $e");
    }
  }

  static Future<void> _storeNotificationLocallyStatic(
    String? title,
    String? body,
    Map<String, dynamic>? data,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String notificationsKey = "notifications_list";

      final String? existingJson = prefs.getString(notificationsKey);
      List<Map<String, dynamic>> notifications = [];

      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          final List<dynamic> decoded =
              json.decode(existingJson) as List<dynamic>;
          notifications = decoded
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } catch (e) {
          debugPrint("Error parsing existing notifications: $e");
        }
      }

      final Map<String, dynamic> newNotification = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": title ?? '',
        "body": body ?? "",
        "timestamp": DateTime.now().toIso8601String(),
        "data": data ?? <String, dynamic>{},
      };

      notifications.insert(0, newNotification);

      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      final String updatedJson = json.encode(notifications);
      await prefs.setString(notificationsKey, updatedJson);

      debugPrint("Notification stored locally: ${title ?? ''}");
    } catch (e) {
      debugPrint("Error storing notification locally: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString("notifications_list");

      if (notificationsJson == null || notificationsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded =
          json.decode(notificationsJson) as List<dynamic>;
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint("Error retrieving stored notifications: $e");
      return [];
    }
  }

  static Map<String, dynamic>? _pendingNotificationData;
  static String? _pendingNotificationTitle;

  static void checkAndHandlePendingNotification() {
    if (_pendingNotificationData != null) {
      final data = Map<String, dynamic>.from(_pendingNotificationData!);
      final title = _pendingNotificationTitle;
      _pendingNotificationData = null;
      _pendingNotificationTitle = null;
      debugPrint("🚀 Executing pending notification navigation...");
      NotificationService().navigateToNotificationDetails(data, title: title);
    }
  }

  void navigateToNotificationDetails(Map<String, dynamic> rawData, {String? title}) {
    print("========== 🚀 NAVIGATING FROM NOTIFICATION ==========");
    print("Payload Data: ${json.encode(rawData)}");
    if (title != null) print("Notification Title: $title");

    if (Get.key.currentState == null || Get.context == null) {
      print("⚠️ Navigator context is not ready yet. Storing pending notification.");
      _pendingNotificationData = rawData;
      _pendingNotificationTitle = title;
      return;
    }

    Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
    if (data.containsKey("data")) {
      if (data["data"] is Map) {
        data.addAll(Map<String, dynamic>.from(data["data"] as Map));
      } else if (data["data"] is String) {
        try {
          final decoded = json.decode(data["data"] as String);
          if (decoded is Map<String, dynamic>) {
            data.addAll(decoded);
          }
        } catch (_) {}
      }
    }

    final String type = (data["type"]?.toString() ?? data["notification_type"]?.toString() ?? "").toLowerCase();
    final String titleLower = (title ?? data["_notification_title"]?.toString() ?? data["title"]?.toString() ?? "").toLowerCase();
    final String route = (data["route"]?.toString() ?? "").toLowerCase();

    final String? appointmentId = data["appointmentId"]?.toString() ??
        data["appointment_id"]?.toString() ??
        data["appointmentID"]?.toString() ??
        data["booking_id"]?.toString() ??
        data["bookingId"]?.toString() ??
        data["id"]?.toString();

    final String? jobId = data["jobId"]?.toString() ??
        data["job_id"]?.toString() ??
        data["jobID"]?.toString() ??
        data["job"]?.toString() ??
        data["id"]?.toString();

    final String? occurrenceId = data["occurrenceId"]?.toString() ?? data["occurrence_id"]?.toString();

    bool isJob = false;

    // Prioritize title and type to distinguish between Appointment API and Job API:
    if (titleLower.contains("appointment") || type.contains("appointment")) {
      isJob = false;
    } else if (titleLower.contains("job") || type.contains("job") || type == "new_job_available") {
      isJob = true;
    } else if (data["is_appointment"] == "true" || data["isAppointment"] == true) {
      isJob = false;
    } else if (data["is_job"] == "true" || data["isJob"] == true) {
      isJob = true;
    } else if (route == "/appointment-details") {
      isJob = false;
    } else if (route == "/job-details") {
      isJob = true;
    } else if (data.containsKey("appointment_id") || data.containsKey("appointmentId")) {
      isJob = false;
    } else if (data.containsKey("job_id") || data.containsKey("jobId")) {
      isJob = true;
    }

    final String? targetId = isJob
        ? (jobId != null && jobId.isNotEmpty ? jobId : appointmentId)
        : (appointmentId != null && appointmentId.isNotEmpty ? appointmentId : jobId);

    if (targetId != null && targetId.isNotEmpty) {
      final Map<String, dynamic> targetData = {
        "appointment_id": targetId,
        "job_id": targetId,
        "id": targetId,
        if (occurrenceId != null) "occurrenceId": occurrenceId,
        "type": data["type"]?.toString() ?? (isJob ? "new_job_available" : "appointment_assigned"),
        "date": data["date"]?.toString() ?? "",
      };

      print("Type: ${isJob ? "JOB" : "APPOINTMENT"} NOTIFICATION | Target ID: $targetId | isJob: $isJob");
      print("=====================================================");

      void performNavigation() {
        Get.to(() => AppointmentDetailPage(appointmentData: targetData, isJob: isJob));
      }

      if (Get.context != null) {
        performNavigation();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => performNavigation());
      }
      return;
    }

    print("⚠️ No valid jobId or appointmentId found in notification data");
    print("=====================================================");
  }

  void _handleNotificationTap(RemoteMessage message) {
    print("========== 🔔 NOTIFICATION TAPPED (FCM) ==========");
    print("Message ID: ${message.messageId}");
    print("Title: ${message.notification?.title}");
    print("Data: ${json.encode(message.data)}");
    print("==================================================");
    navigateToNotificationDetails(message.data, title: message.notification?.title);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print("========== 🔔 LOCAL NOTIFICATION TAPPED ==========");
    print("Payload: ${response.payload}");
    print("==================================================");
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            json.decode(response.payload!) as Map<String, dynamic>;
        final String? title = data["_notification_title"]?.toString() ?? data["title"]?.toString();
        navigateToNotificationDetails(data, title: title);
      } catch (e) {
        debugPrint('Error decoding notification payload: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
