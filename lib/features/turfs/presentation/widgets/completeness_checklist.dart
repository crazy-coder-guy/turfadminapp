import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/turf_completeness.dart';

class CompletenessChecklist extends StatelessWidget {
  const CompletenessChecklist({super.key, required this.completeness});

  final TurfCompleteness completeness;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turf completeness', style: AppTextStyles.cardTitle()),
          const SizedBox(height: AppSpacing.sm),
          ...completeness.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item.isComplete ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: item.isComplete ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item.label, style: AppTextStyles.body())),
                ],
              ),
            ),
          ),
          if (!completeness.isComplete) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Complete the missing items before submitting.',
              style: AppTextStyles.caption(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
