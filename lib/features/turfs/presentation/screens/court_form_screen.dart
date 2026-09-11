import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/turf_media.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../master_data/domain/master_data_providers.dart';
import '../../domain/turf_providers.dart';
import '../widgets/turf_media_section.dart';

class CourtFormScreen extends ConsumerStatefulWidget {
  const CourtFormScreen({super.key, required this.turfId, this.courtId});

  final String turfId;
  final String? courtId;

  @override
  ConsumerState<CourtFormScreen> createState() => _CourtFormScreenState();
}

class _CourtFormScreenState extends ConsumerState<CourtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _surfaceTypeController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isIndoor = false;
  bool _isActive = true;
  final Set<String> _selectedSportIds = {};

  List<TurfMedia> _thumbnailMedia = const [];
  List<TurfMedia> _galleryMedia = const [];
  List<TurfMedia> _reviewMedia = const [];
  bool _canEditMedia = true;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isDeactivating = false;
  String? _errorMessage;

  bool get _isEditMode => widget.courtId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final turf = await ref.read(turfRepositoryProvider).getTurf(widget.turfId);
      final court = turf.courts.firstWhere((c) => c.id == widget.courtId);
      _nameController.text = court.name;
      _descriptionController.text = court.description ?? '';
      _surfaceTypeController.text = court.surfaceType ?? '';
      _capacityController.text = court.capacity?.toString() ?? '';
      _isIndoor = court.isIndoor;
      _isActive = court.isActive;
      _selectedSportIds.addAll(court.sports.map((s) => s.id));
      _thumbnailMedia = court.thumbnailMedia != null ? [court.thumbnailMedia!] : const [];
      _galleryMedia = court.galleryMedia;
      _reviewMedia = court.reviewMedia;
      _canEditMedia = turf.canEditMedia;
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadMedia() async {
    try {
      final turf = await ref.read(turfRepositoryProvider).getTurf(widget.turfId);
      final court = turf.courts.firstWhere((c) => c.id == widget.courtId);
      if (!mounted) return;
      setState(() {
        _thumbnailMedia = court.thumbnailMedia != null ? [court.thumbnailMedia!] : const [];
        _galleryMedia = court.galleryMedia;
        _reviewMedia = court.reviewMedia;
        _canEditMedia = turf.canEditMedia;
      });
    } on AppException {
      // The media sections already surface their own error snackbars.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _surfaceTypeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedSportIds.isEmpty) {
      setState(() => _errorMessage = 'Assign at least one sport to this court.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(turfRepositoryProvider);
      final capacity = int.tryParse(_capacityController.text.trim());
      final sports = ref.read(sportsProvider).valueOrNull ?? const [];
      final courtType = sports
          .where((sport) => _selectedSportIds.contains(sport.id))
          .map((sport) => sport.name)
          .join(', ');
      if (widget.courtId == null) {
        await repository.createCourt(
          widget.turfId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          courtType: courtType,
          surfaceType: _surfaceTypeController.text.trim(),
          capacity: capacity,
          isIndoor: _isIndoor,
          sportIds: _selectedSportIds.toList(),
        );
      } else {
        await repository.updateCourt(
          widget.turfId,
          widget.courtId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          courtType: courtType,
          surfaceType: _surfaceTypeController.text.trim(),
          capacity: capacity,
          isIndoor: _isIndoor,
          status: _isActive ? 'active' : 'inactive',
          sportIds: _selectedSportIds.toList(),
        );
      }
      ref.invalidate(turfDetailProvider(widget.turfId));
      if (mounted) context.pop();
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Deactivate court?',
      message: 'This court will no longer be shown as active.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _isDeactivating = true);
    try {
      await ref.read(turfRepositoryProvider).deactivateCourt(widget.turfId, widget.courtId!);
      ref.invalidate(turfDetailProvider(widget.turfId));
      if (mounted) context.pop();
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isDeactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Court' : 'Add New Court',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                AppTextField(
                  label: 'Court Name',
                  hint: 'e.g. Court A (7-a-side)',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Court name is required' : null,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Description',
                  hint: 'Court specifications, dimensions...',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Surface Type',
                  hint: 'e.g. Synthetic Turf',
                  controller: _surfaceTypeController,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Capacity (Max Players)',
                  hint: 'e.g. 14',
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isIndoor,
                  onChanged: (value) => setState(() => _isIndoor = value),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Indoor Court',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (_isEditMode)
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: const Text(
                      'Active Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'SPORTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the sport(s) this court supports.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                _buildSportsPicker(),
                if (_isEditMode) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'COURT THUMBNAIL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TurfMediaSection(
                    turfId: widget.turfId,
                    courtId: widget.courtId,
                    media: _thumbnailMedia,
                    category: kMediaCategoryThumbnail,
                    editable: _canEditMedia,
                    singleSlot: true,
                    onChanged: _reloadMedia,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'COURT IMAGES (${_galleryMedia.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TurfMediaSection(
                    turfId: widget.turfId,
                    courtId: widget.courtId,
                    media: _galleryMedia,
                    category: kMediaCategoryGallery,
                    editable: _canEditMedia,
                    onChanged: _reloadMedia,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'REVIEW IMAGES (${_reviewMedia.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Shared with admins for verification only - not shown publicly.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  TurfMediaSection(
                    turfId: widget.turfId,
                    courtId: widget.courtId,
                    media: _reviewMedia,
                    category: kMediaCategoryReview,
                    editable: _canEditMedia,
                    onChanged: _reloadMedia,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'MARKETPLACE SETTINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Operating Hours',
                    variant: AppButtonVariant.outline,
                    icon: Icons.schedule_outlined,
                    onPressed: () => context.go('/turfs/${widget.turfId}/courts/${widget.courtId}/operating-hours'),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Pricing',
                    variant: AppButtonVariant.outline,
                    icon: Icons.payments_outlined,
                    onPressed: () => context.go('/turfs/${widget.turfId}/courts/${widget.courtId}/pricing'),
                  ),
                ],
                const SizedBox(height: 36),
                AppButton(
                  label: _isEditMode ? 'Save Changes' : 'Add Court',
                  isLoading: _isSubmitting,
                  onPressed: _save,
                ),
                if (_isEditMode) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Deactivate Court',
                    variant: AppButtonVariant.outline,
                    isLoading: _isDeactivating,
                    onPressed: _deactivate,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSportsPicker() {
    final sportsAsync = ref.watch(sportsProvider);
    return sportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorStateView(
        message: 'Unable to load sports.',
        onRetry: () => ref.invalidate(sportsProvider),
      ),
      data: (sports) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: sports.where((s) => s.isActive).map((sport) {
          final selected = _selectedSportIds.contains(sport.id);
          return FilterChip(
            label: Text(
              sport.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : const Color(0xFF334155),
              ),
            ),
            selected: selected,
            showCheckmark: true,
            selectedColor: const Color(0xFFEFF8FF),
            backgroundColor: const Color(0xFFF8FAFC),
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1.0,
            ),
            checkmarkColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) => setState(() {
              if (value) {
                _selectedSportIds.add(sport.id);
              } else {
                _selectedSportIds.remove(sport.id);
              }
            }),
          );
        }).toList(),
      ),
    );
  }
}
