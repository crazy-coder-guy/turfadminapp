import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/operating_hours.dart';
import '../../../../shared/models/pricing_rule.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../domain/marketplace_providers.dart';

class PricingRulesScreen extends ConsumerStatefulWidget {
  const PricingRulesScreen({super.key, required this.turfId, required this.courtId});

  final String turfId;
  final String courtId;

  @override
  ConsumerState<PricingRulesScreen> createState() => _PricingRulesScreenState();
}

class _PricingRulesScreenState extends ConsumerState<PricingRulesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PricingRule> _rules = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rules = await ref.read(marketplaceRepositoryProvider).listPricingRules(widget.turfId, widget.courtId);
      if (!mounted) return;
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  List<PricingRule> _rulesForDay(int day) =>
      _rules.where((r) => r.dayOfWeek == day).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Pricing', style: AppTextStyles.appHeader())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorStateView(message: _errorMessage!, onRetry: _load)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.standard),
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.standard),
                  itemBuilder: (context, day) => _PricingDayCard(
                    day: day,
                    rules: _rulesForDay(day),
                    onAdd: () => _showRuleSheet(day: day),
                    onEdit: (rule) => _showRuleSheet(day: rule.dayOfWeek, existing: rule),
                    onToggleActive: (rule) => _handleToggle(rule),
                    onDelete: (rule) => _handleDelete(rule),
                  ),
                ),
    );
  }

  Future<void> _handleToggle(PricingRule rule) async {
    try {
      await ref.read(marketplaceRepositoryProvider).updatePricingRule(
            widget.turfId,
            widget.courtId,
            rule.id,
            isActive: !rule.isActive,
          );
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _handleDelete(PricingRule rule) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete pricing rule',
      message: 'Remove the ${rule.startTime} - ${rule.endTime} rate?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(marketplaceRepositoryProvider).deletePricingRule(widget.turfId, widget.courtId, rule.id);
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showRuleSheet({required int day, PricingRule? existing}) async {
    TimeOfDay start = existing != null ? _parseTime(existing.startTime) : const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay end = existing != null ? _parseTime(existing.endTime) : const TimeOfDay(hour: 22, minute: 0);
    final priceController = TextEditingController(text: existing?.priceAmount.toStringAsFixed(0) ?? '');
    String? sheetError;
    bool isSaving = false;

    await AppBottomSheet.show<void>(
      context,
      title: existing == null ? 'Add rate - ${kDayOfWeekLabels[day]}' : 'Edit rate - ${kDayOfWeekLabels[day]}',
      builder: (sheetContext, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeRow(
              label: 'Start time',
              value: start,
              onTap: () async {
                final picked = await showTimePicker(context: sheetContext, initialTime: start);
                if (picked != null) setSheetState(() => start = picked);
              },
            ),
            const SizedBox(height: AppSpacing.standard),
            _TimeRow(
              label: 'End time',
              value: end,
              onTap: () async {
                final picked = await showTimePicker(context: sheetContext, initialTime: end);
                if (picked != null) setSheetState(() => end = picked);
              },
            ),
            const SizedBox(height: AppSpacing.standard),
            AppTextField(
              label: 'Price per hour (INR)',
              controller: priceController,
              keyboardType: TextInputType.number,
            ),
            if (sheetError != null) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(sheetError!, style: AppTextStyles.bodySmall(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.section),
            AppButton(
              label: existing == null ? 'Add rate' : 'Save changes',
              isLoading: isSaving,
              onPressed: () async {
                final price = double.tryParse(priceController.text.trim());
                if (price == null || price < 0) {
                  setSheetState(() => sheetError = 'Enter a valid price');
                  return;
                }
                if (_toTimeString(start).compareTo(_toTimeString(end)) >= 0) {
                  setSheetState(() => sheetError = 'Start time must be before end time');
                  return;
                }
                setSheetState(() {
                  isSaving = true;
                  sheetError = null;
                });
                try {
                  if (existing == null) {
                    await ref.read(marketplaceRepositoryProvider).createPricingRule(
                          widget.turfId,
                          widget.courtId,
                          dayOfWeek: day,
                          startTime: _toTimeString(start),
                          endTime: _toTimeString(end),
                          priceAmount: price,
                        );
                  } else {
                    await ref.read(marketplaceRepositoryProvider).updatePricingRule(
                          widget.turfId,
                          widget.courtId,
                          existing.id,
                          startTime: _toTimeString(start),
                          endTime: _toTimeString(end),
                          priceAmount: price,
                        );
                  }
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                } on AppException catch (e) {
                  setSheetState(() {
                    isSaving = false;
                    sheetError = e.message;
                  });
                }
              },
            ),
          ],
        );
      },
    );

    await _load();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _toTimeString(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _PricingDayCard extends StatelessWidget {
  const _PricingDayCard({
    required this.day,
    required this.rules,
    required this.onAdd,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final int day;
  final List<PricingRule> rules;
  final VoidCallback onAdd;
  final ValueChanged<PricingRule> onEdit;
  final ValueChanged<PricingRule> onToggleActive;
  final ValueChanged<PricingRule> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.standard),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kDayOfWeekLabels[day], style: AppTextStyles.cardTitle()),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add rate')),
            ],
          ),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('No pricing configured', style: AppTextStyles.body(color: AppColors.textSecondary)),
            )
          else
            ...rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${rule.startTime} - ${rule.endTime}  ·  ₹${rule.priceAmount.toStringAsFixed(0)}/hr',
                        style: AppTextStyles.body(color: rule.isActive ? AppColors.textPrimary : AppColors.textSecondary),
                      ),
                    ),
                    Switch(value: rule.isActive, onChanged: (_) => onToggleActive(rule), activeColor: AppColors.primary),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => onEdit(rule)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => onDelete(rule),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value, required this.onTap});

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard, vertical: AppSpacing.compact),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body(color: AppColors.textSecondary)),
            Text(value.format(context), style: AppTextStyles.body()),
          ],
        ),
      ),
    );
  }
}
