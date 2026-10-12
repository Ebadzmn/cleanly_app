import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/on_device_translation_service.dart';

class JobInfoCardWidget extends StatefulWidget {
  final String title;
  final String description;

  const JobInfoCardWidget({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<JobInfoCardWidget> createState() => _JobInfoCardWidgetState();
}

class _JobInfoCardWidgetState extends State<JobInfoCardWidget> {
  final OnDeviceTranslationService _translationService =
      OnDeviceTranslationService();

  String? _translatedTitle;
  String? _translatedDescription;
  bool _isTranslating = false;
  bool _showTranslated = true;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = LocalizationService().currentLanguage;
    LocalizationService().addListener(_onLanguageChanged);

    if (_currentLanguage.toLowerCase() == "es") {
      _translateContent();
    }
  }

  @override
  void didUpdateWidget(covariant JobInfoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != oldWidget.title ||
        widget.description != oldWidget.description) {
      _translatedTitle = null;
      _translatedDescription = null;
      if (_currentLanguage.toLowerCase() == "es") {
        _translateContent();
      }
    }
  }

  void _onLanguageChanged() {
    final newLang = LocalizationService().currentLanguage;
    if (newLang != _currentLanguage) {
      if (mounted) {
        setState(() {
          _currentLanguage = newLang;
          _showTranslated = true;
        });
      }
      if (newLang.toLowerCase() == "es") {
        _translateContent();
      }
    }
  }

  Future<void> _translateContent() async {
    if (widget.title.isEmpty && widget.description.isEmpty) return;

    // If both are already translated and cached
    if (_translatedTitle != null && _translatedDescription != null) {
      if (mounted) setState(() {});
      return;
    }

    if (mounted) {
      setState(() {
        _isTranslating = true;
      });
    }

    try {
      String? tTitle;
      String? tDesc;

      final futures = <Future>[];

      if (widget.title.isNotEmpty) {
        futures.add(
          _translationService
              .translate(
                text: widget.title,
                sourceLanguage: TranslateLanguage.english,
                targetLanguage: TranslateLanguage.spanish,
              )
              .then((res) => tTitle = res),
        );
      }

      if (widget.description.isNotEmpty) {
        futures.add(
          _translationService
              .translate(
                text: widget.description,
                sourceLanguage: TranslateLanguage.english,
                targetLanguage: TranslateLanguage.spanish,
              )
              .then((res) => tDesc = res),
        );
      }

      await Future.wait(futures).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _translatedTitle = tTitle ?? widget.title;
          _translatedDescription = tDesc ?? widget.description;
        });
      }
    } catch (e) {
      debugPrint("Translation error in JobInfoCard: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    LocalizationService().removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title.isEmpty && widget.description.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isSpanish = _currentLanguage.toLowerCase() == "es";
    final bool hasTranslation =
        _translatedTitle != null || _translatedDescription != null;

    final String displayTitle = (isSpanish &&
            _showTranslated &&
            _translatedTitle != null &&
            _translatedTitle!.isNotEmpty)
        ? _translatedTitle!
        : widget.title;

    final String displayDescription = (isSpanish &&
            _showTranslated &&
            _translatedDescription != null &&
            _translatedDescription!.isNotEmpty)
        ? _translatedDescription!
        : widget.description;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF8B6C13),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationService().translate("jobs.jobInfo"),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B6C13),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_isTranslating)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B6C13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LocalizationService().translate("jobs.translating"),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B6C13),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else if (isSpanish && hasTranslation)
                InkWell(
                  onTap: () {
                    setState(() {
                      _showTranslated = !_showTranslated;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showTranslated ? Icons.undo : Icons.translate,
                          size: 14,
                          color: const Color(0xFF8B6C13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showTranslated
                              ? LocalizationService()
                                  .translate("jobs.showOriginal")
                              : LocalizationService()
                                  .translate("jobs.showTranslation"),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B6C13),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          if (displayTitle.isNotEmpty) ...[
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Description
          if (displayDescription.isNotEmpty)
            Text(
              displayDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),

          // Subtle translation badge when translated
          if (isSpanish && _showTranslated && hasTranslation) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.g_translate,
                  size: 12,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  LocalizationService().translate("jobs.translatedToSpanish"),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
