import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppTextStyles.sectionHeader()),
      content: Text(message, style: AppTextStyles.body(color: AppColors.textSecondary)),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.standard,
        0,
        AppSpacing.standard,
        AppSpacing.standard,
      ),
      actions: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            label: confirmLabel,
            variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
