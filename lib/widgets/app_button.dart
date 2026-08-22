import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger, success }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  _ButtonColors get _colors {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(AppColors.primary, AppColors.onPrimary, null);
      case AppButtonVariant.secondary:
        return _ButtonColors(AppColors.secondary, AppColors.onSecondary, null);
      case AppButtonVariant.outline:
        return _ButtonColors(
          AppColors.surfaceMuted,
          AppColors.onSurfaceMuted,
          AppColors.primary.withOpacity(0.15),
        );
      case AppButtonVariant.danger:
        return _ButtonColors(AppColors.danger, AppColors.onDanger, null);
      case AppButtonVariant.success:
        return _ButtonColors(AppColors.success, AppColors.onSuccess, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final disabled = onPressed == null || isLoading;

    final button = ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        disabledBackgroundColor: colors.background.withOpacity(0.4),
        disabledForegroundColor: colors.foreground.withOpacity(0.7),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: colors.border != null
              ? BorderSide(color: colors.border!)
              : BorderSide.none,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      child: isLoading
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colors.foreground),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;
  _ButtonColors(this.background, this.foreground, this.border);
}
