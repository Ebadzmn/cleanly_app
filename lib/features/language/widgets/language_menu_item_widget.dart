import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LanguageMenuItemWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const LanguageMenuItemWidget({
    super.key,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF77CCD9).withOpacity(0.2)
              : const Color(0xFFEEFBFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF77CCD9)
                : const Color(0xFFCAC4D0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  "assets/svg/language.svg",
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1.5,
                  height: 24,
                  color: const Color(0xFF77CCD9),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF77CCD9) : Colors.black,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF77CCD9),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
