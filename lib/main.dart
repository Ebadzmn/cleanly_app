import "package:cleanly_app/features/splash/pages/splash_page.dart";
import "package:cleanly_app/firebase_file/firebase_options.dart";
import "package:cleanly_app/services/notification_service.dart";
import "package:cleanly_app/services/localization_service.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:get/get.dart";


bool isFirebaseInitialized = false;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
    isFirebaseInitialized = true;
  } catch (e) {
    print("Firebase init failed: $e");
  }

  await NotificationService().initialize();
  
  await LocalizationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    LocalizationService().setOnLanguageChangedCallback(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SplashPage(),
    );
  }
}
