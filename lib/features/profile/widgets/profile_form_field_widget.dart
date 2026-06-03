import 'package:flutter/material.dart';

class ProfileFormFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isReEnterPassword;
  final bool readOnly;
  final bool isRequired;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  const ProfileFormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isReEnterPassword = false,
    this.readOnly = false,
    this.isRequired = true,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 3),
              const Text(
                "*",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFC70036),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            enabled: !readOnly,
            obscureText: obscureText,
            style: TextStyle(
              fontSize: 16,
              color: readOnly ? const Color(0xFF666666) : const Color(0xFF2C2C2C),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF4A5565),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: readOnly,
              fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF6B7280),
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
