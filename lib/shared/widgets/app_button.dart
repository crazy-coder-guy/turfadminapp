import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_foreground(disabled)),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _foreground(disabled)),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.button(color: _foreground(disabled))),
            ],
          );

    final button = SizedBox(
      height: AppDimensions.buttonHeight,
      width: fullWidth ? double.infinity : null,
      child: _wrappedButton(disabled: disabled, child: content),
    );

    return button;
  }

  Widget _wrappedButton({required bool disabled, required Widget child}) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(onPressed: disabled ? null : onPressed, child: child);
      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tertiary,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.neutralTint,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
            elevation: 0,
          ),
          child: child,
        );
      case AppButtonVariant.outline:
        return OutlinedButton(onPressed: disabled ? null : onPressed, child: child);
    }
  }

  Color _foreground(bool disabled) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return disabled ? AppColors.textSecondary : AppColors.textOnPrimary;
      case AppButtonVariant.secondary:
        return disabled ? AppColors.textSecondary : AppColors.primary;
      case AppButtonVariant.outline:
        return AppColors.textPrimary;
    }
  }
}
