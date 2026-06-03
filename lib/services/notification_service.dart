import "dart:convert";

import "package:cleanly_app/firebase_file/firebase_options.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
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

  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  debugPrint('Message notification body: ${message.notification?.body}');

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_launcher_icon');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  String? getImageUrl(RemoteMessage message) {
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

  Future<ByteArrayAndroidBitmap?> downloadImage(String imageUrl) async {
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

  try {
    if (message.notification != null) {
      String? imageUrl = getImageUrl(message);
      ByteArrayAndroidBitmap? bigPicture;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        debugPrint('Background: Image URL found: $imageUrl');
        bigPicture = await downloadImage(imageUrl);
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
                contentTitle: message.notification?.title ?? '',
                summaryText: message.notification?.body ?? '',
              )
            : null,
      );

      await localNotifications.show(
        message.hashCode,
        message.notification?.title ?? '',
        message.notification?.body ?? "",
        NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );

      await NotificationService._storeNotificationLocallyStatic(
        message.notification?.title ?? '',
        message.notification?.body ?? "",
        message.data,
      );

      debugPrint("Background notification shown successfully");
    } else {
      debugPrint(
        'No notification payload in message, only data: ${message.data}',
      );
    }
  } catch (e) {
    debugPrint('Error showing background notification: $e');
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
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification title: ${message.notification?.title}');
    debugPrint('Message notification body: ${message.notification?.body}');

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
        payload: message.data.toString(),
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

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
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
