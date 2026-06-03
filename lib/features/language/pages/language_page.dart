import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_controller.dart';
import '../widgets/language_menu_item_widget.dart';
import '../../../../services/localization_service.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizationService localization = LocalizationService();
    final LanguageController controller = Get.find<LanguageController>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4, 0.7, 1.0],
          colors: [
            Color(0xFFC7F0F9),
            Color(0xFFEDF8FA),
            Color(0xFFFCE18D),
            Color(0xFFF4C535),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Get.back(),
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
          title: Text(localization.translate("language.title")),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 25),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.60),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LanguageMenuItemWidget(
                                title: localization.translate(
                                  "language.english",
                                ),
                                isSelected:
                                    controller.currentLanguage.value == "en",
                                onTap: () {
                                  controller.selectLanguage("en");
                                },
                              ),
                              const SizedBox(height: 12),
                              LanguageMenuItemWidget(
                                title: localization.translate(
                                  "language.spanish",
                                ),
                                isSelected:
                                    controller.currentLanguage.value == "es",
                                onTap: () {
                                  controller.selectLanguage("es");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
