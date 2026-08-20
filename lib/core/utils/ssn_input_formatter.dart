import 'package:flutter/services.dart';

/// Formats SSN input automatically to XXX-XX-XXXX (e.g. 222-22-2222)
class SsnInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer formatted = StringBuffer();

    for (int i = 0; i < digitsOnly.length && i < 9; i++) {
      if (i == 3 || i == 5) {
        formatted.write('-');
      }
      formatted.write(digitsOnly[i]);
    }

    final String text = formatted.toString();
    int cursorPosition = text.length;

    if (newValue.selection.end < newValue.text.length) {
      int nonDigitsBeforeCursor = newValue.text
          .substring(0, newValue.selection.end)
          .replaceAll(RegExp(r'\D'), '')
          .length;
      int newOffset = 0;
      int digitsSeen = 0;
      for (int i = 0; i < text.length; i++) {
        if (text[i] != '-') {
          digitsSeen++;
        }
        if (digitsSeen == nonDigitsBeforeCursor) {
          newOffset = i + 1;
          break;
        }
      }
      cursorPosition = newOffset.clamp(0, text.length);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
