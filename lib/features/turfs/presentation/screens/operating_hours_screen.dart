import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/operating_hours.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../domain/marketplace_providers.dart';

class OperatingHoursScreen extends ConsumerStatefulWidget {
  const OperatingHoursScreen({super.key, required this.turfId, required this.courtId});

  final String turfId;
  final String courtId;

  @override
  ConsumerState<OperatingHoursScreen> createState() => _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends ConsumerState<OperatingHoursScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OperatingHoursWindow> _windows = const [];

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
      final windows = await ref.read(marketplaceRepositoryProvider).listOperatingHours(widget.turfId, widget.courtId);
      if (!mounted) return;
      setState(() {
        _windows = windows;
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

  List<OperatingHoursWindow> _windowsForDay(int day) =>
      _windows.where((w) => w.dayOfWeek == day).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Operating Hours', style: AppTextStyles.appHeader())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorStateView(message: _errorMessage!, onRetry: _load)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.standard),
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.standard),
                  itemBuilder: (context, day) => _DayCard(
                    day: day,
                    windows: _windowsForDay(day),
                    onAdd: () => _showWindowSheet(day: day),
                    onEdit: (window) => _showWindowSheet(day: window.dayOfWeek, existing: window),
                    onDelete: (window) => _handleDelete(window),
                  ),
                ),
    );
  }

  Future<void> _handleDelete(OperatingHoursWindow window) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove window',
      message: 'Remove ${window.startTime} - ${window.endTime}? This time will show as closed.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(marketplaceRepositoryProvider).deleteOperatingHours(widget.turfId, widget.courtId, window.id);
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showWindowSheet({required int day, OperatingHoursWindow? existing}) async {
    TimeOfDay start = existing != null ? _parseTime(existing.startTime) : const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay end = existing != null ? _parseTime(existing.endTime) : const TimeOfDay(hour: 22, minute: 0);
    String? sheetError;
    bool isSaving = false;

    await AppBottomSheet.show<void>(
      context,
      title: existing == null ? 'Add window - ${kDayOfWeekLabels[day]}' : 'Edit window - ${kDayOfWeekLabels[day]}',
      builder: (sheetContext, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimePickerRow(
              label: 'Start time',
              value: start,
              onTap: () async {
                final picked = await showTimePicker(context: sheetContext, initialTime: start);
                if (picked != null) setSheetState(() => start = picked);
              },
            ),
            const SizedBox(height: AppSpacing.standard),
            _TimePickerRow(
              label: 'End time',
              value: end,
              onTap: () async {
                final picked = await showTimePicker(context: sheetContext, initialTime: end);
                if (picked != null) setSheetState(() => end = picked);
              },
            ),
            if (sheetError != null) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(sheetError!, style: AppTextStyles.bodySmall(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.section),
            AppButton(
              label: existing == null ? 'Add window' : 'Save changes',
              isLoading: isSaving,
              onPressed: () async {
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
                    await ref.read(marketplaceRepositoryProvider).createOperatingHours(
                          widget.turfId,
                          widget.courtId,
                          dayOfWeek: day,
                          startTime: _toTimeString(start),
                          endTime: _toTimeString(end),
                        );
                  } else {
                    await ref.read(marketplaceRepositoryProvider).updateOperatingHours(
                          widget.turfId,
                          widget.courtId,
                          existing.id,
                          startTime: _toTimeString(start),
                          endTime: _toTimeString(end),
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

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.windows,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final List<OperatingHoursWindow> windows;
  final VoidCallback onAdd;
  final ValueChanged<OperatingHoursWindow> onEdit;
  final ValueChanged<OperatingHoursWindow> onDelete;

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
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add window'),
              ),
            ],
          ),
          if (windows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('Closed', style: AppTextStyles.body(color: AppColors.textSecondary)),
            )
          else
            ...windows.map(
              (window) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${window.startTime} - ${window.endTime}', style: AppTextStyles.body()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => onEdit(window),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => onDelete(window),
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

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({required this.label, required this.value, required this.onTap});

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard, vertical: AppSpacing.compact),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
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
