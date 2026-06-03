import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/localization_service.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inject the controller here if not done via binding or if loaded directly
    if (!Get.isRegistered<SplashController>()) {
      Get.put(SplashController());
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
          ),
          
          // Gradient Overlay to add premium depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFEEFBFC).withOpacity(0.6),
                  const Color(0xFFCDEEF1).withOpacity(0.85),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),

                // Centered Logo & Brand Card
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glassmorphic / Premium Logo Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3D4A).withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/Cleanly_Logo.jpg',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App Title
                    Text(
                      LocalizationService().translate("splash.appName"),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Slogan / Subtitle
                    Text(
                      "Premium Cleaning Services",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B5563).withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Bottom Loading Indicator & Version
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Elegant circular loading
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Version 1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
