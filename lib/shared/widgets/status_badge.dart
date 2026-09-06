import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum StatusTone { success, warning, primary, neutral, error }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  factory StatusBadge.forTurf({required String approvalStatus, required String status}) {
    if (approvalStatus == 'approved' && status == 'active') {
      return const StatusBadge(label: 'LIVE', tone: StatusTone.success);
    }
    switch (approvalStatus) {
      case 'approved':
        return const StatusBadge(label: 'APPROVED', tone: StatusTone.success);
      case 'under_review':
        return const StatusBadge(label: 'UNDER REVIEW', tone: StatusTone.warning);
      case 'submitted':
        return const StatusBadge(label: 'SUBMITTED', tone: StatusTone.primary);
      case 'rejected':
        return const StatusBadge(label: 'REJECTED', tone: StatusTone.error);
      case 'draft':
      default:
        return const StatusBadge(label: 'DRAFT', tone: StatusTone.neutral);
    }
  }

  factory StatusBadge.forDocument(String verificationStatus) {
    switch (verificationStatus) {
      case 'approved':
      case 'verified':
        return const StatusBadge(label: 'VERIFIED', tone: StatusTone.success);
      case 'rejected':
        return const StatusBadge(label: 'REJECTED', tone: StatusTone.error);
      case 'pending':
      default:
        return const StatusBadge(label: 'PENDING', tone: StatusTone.warning);
    }
  }

  static const StatusBadge notUploaded = StatusBadge(label: 'NOT UPLOADED', tone: StatusTone.neutral);

  final String label;
  final StatusTone tone;

  (Color, Color) get _colors {
    switch (tone) {
      case StatusTone.success:
        return (AppColors.success, AppColors.successTint);
      case StatusTone.warning:
        return (AppColors.warning, AppColors.warningTint);
      case StatusTone.primary:
        return (AppColors.primary, AppColors.primaryTint);
      case StatusTone.error:
        return (AppColors.error, AppColors.errorTint);
      case StatusTone.neutral:
        return (AppColors.textSecondary, AppColors.neutralTint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.badgeRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: AppTextStyles.caption(color: fg).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
