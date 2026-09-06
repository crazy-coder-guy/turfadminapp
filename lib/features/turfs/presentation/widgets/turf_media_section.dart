import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/data/uploads_repository.dart';
import '../../../../shared/models/turf_media.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../domain/turf_providers.dart';

/// One category of turf media: a single-slot "thumbnail" or a multi-photo
/// gallery ("gallery" for the public turf photos, "review" for photos an
/// admin needs to verify the turf). Every photo is an actual upload - never
/// a typed-in URL.
class TurfMediaSection extends ConsumerWidget {
  const TurfMediaSection({
    super.key,
    required this.turfId,
    required this.media,
    required this.category,
    required this.editable,
    this.singleSlot = false,
    this.courtId,
    this.onChanged,
  });

  final String turfId;
  final List<TurfMedia> media;
  final String category;
  final bool editable;
  final bool singleSlot;

  /// When set, this section manages a specific court's media instead of the
  /// turf's own media.
  final String? courtId;

  /// Called after any successful add/replace/delete, in addition to the
  /// standard [turfDetailProvider] invalidation - lets a screen that isn't
  /// itself watching that provider (e.g. the court form) refresh its own
  /// locally-loaded state.
  final VoidCallback? onChanged;

  Future<TurfMedia> _createMedia(
    WidgetRef ref, {
    required String mediaUrl,
    required int sortOrder,
  }) {
    final repository = ref.read(turfRepositoryProvider);
    return courtId != null
        ? repository.addCourtMedia(
            turfId,
            courtId!,
            mediaType: 'image',
            mediaUrl: mediaUrl,
            category: category,
            sortOrder: sortOrder,
          )
        : repository.addMedia(
            turfId,
            mediaType: 'image',
            mediaUrl: mediaUrl,
            category: category,
            sortOrder: sortOrder,
          );
  }

  Future<void> _removeMedia(WidgetRef ref, String mediaId) {
    final repository = ref.read(turfRepositoryProvider);
    return courtId != null
        ? repository.deleteCourtMedia(turfId, courtId!, mediaId)
        : repository.deleteMedia(turfId, mediaId);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TurfMedia item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete photo?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _removeMedia(ref, item.id);
      ref.invalidate(turfDetailProvider(turfId));
      onChanged?.call();
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref, {TurfMedia? existing}) async {
    // Replacing a single existing photo, or picking a thumbnail, is always
    // one file - only adding fresh gallery/review photos allows picking
    // several from the device library at once.
    final allowMultiple = existing == null && !singleSlot;
    List<File> pickedFiles = [];
    bool isSubmitting = false;
    String? error;

    void addFiles(StateSetter setSheetState, List<File> files) {
      final validFiles = <File>[];
      String? firstError;
      for (final file in files) {
        final validationError = validateUploadFile(file, allowedExtensions: kUploadImageOnlyExtensions);
        if (validationError == null) {
          validFiles.add(file);
        } else {
          firstError ??= validationError;
        }
      }
      setSheetState(() {
        error = firstError;
        pickedFiles = allowMultiple ? [...pickedFiles, ...validFiles] : validFiles;
      });
    }

    Future<void> pickFromCamera(StateSetter setSheetState) async {
      try {
        final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
        if (image == null) return;
        addFiles(setSheetState, [File(image.path)]);
      } catch (_) {
        setSheetState(() => error = 'Could not access the camera.');
      }
    }

    Future<void> pickFromGallery(StateSetter setSheetState) async {
      try {
        if (allowMultiple) {
          final images = await ImagePicker().pickMultiImage(imageQuality: 80);
          if (images.isEmpty) return;
          addFiles(setSheetState, images.map((image) => File(image.path)).toList());
        } else {
          final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
          if (image == null) return;
          addFiles(setSheetState, [File(image.path)]);
        }
      } catch (_) {
        setSheetState(() => error = 'Could not access the gallery.');
      }
    }

    await AppBottomSheet.show<void>(
      context,
      title: existing != null
          ? 'Replace photo'
          : (singleSlot ? 'Upload thumbnail' : 'Add photos'),
      builder: (sheetContext, setSheetState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allowMultiple
                ? 'JPG or PNG · up to 3 MB each · select multiple from Gallery'
                : 'JPG or PNG · up to 3 MB',
            style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.standard),
          if (pickedFiles.isEmpty)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.neutralTint,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                'No photo selected',
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
              ),
            )
          else if (!allowMultiple)
            ClipRRect(
              borderRadius: AppRadius.cardRadius,
              child: Image.file(pickedFiles.first, height: 140, width: double.infinity, fit: BoxFit.cover),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pickedFiles.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.cardRadius,
                      child: Image.file(pickedFiles[index], width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setSheetState(
                          () => pickedFiles = [...pickedFiles]..removeAt(index),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pickFromCamera(setSheetState),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pickFromGallery(setSheetState),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(error!, style: AppTextStyles.bodySmall(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.standard),
          AppButton(
            label: existing != null
                ? 'Replace'
                : (pickedFiles.length > 1 ? 'Upload ${pickedFiles.length} photos' : 'Upload'),
            isLoading: isSubmitting,
            onPressed: pickedFiles.isEmpty
                ? null
                : () async {
                    setSheetState(() => isSubmitting = true);
                    try {
                      for (var i = 0; i < pickedFiles.length; i++) {
                        final uploaded = await ref.read(uploadsRepositoryProvider).upload(
                              pickedFiles[i],
                              category: courtId != null ? 'court-media' : 'turf-media',
                            );
                        await _createMedia(
                          ref,
                          mediaUrl: uploaded.url,
                          sortOrder: existing?.sortOrder ?? (media.length + i),
                        );
                      }
                      if (existing != null) {
                        await _removeMedia(ref, existing.id);
                      }
                      ref.invalidate(turfDetailProvider(turfId));
                      onChanged?.call();
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    } on AppException catch (e) {
                      setSheetState(() {
                        error = e.message;
                        isSubmitting = false;
                      });
                    } catch (_) {
                      setSheetState(() {
                        error = 'Could not upload the photo(s). Please try again.';
                        isSubmitting = false;
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, TurfMedia item) {
    return ClipRRect(
      borderRadius: AppRadius.cardRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: item.mediaUrl,
            fit: BoxFit.cover,
            errorWidget: Container(color: AppColors.neutralTint),
          ),
          if (editable) ...[
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _addPhoto(context, ref, existing: item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _delete(context, ref, item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (singleSlot) {
      final thumbnail = media.isNotEmpty ? media.first : null;
      return SizedBox(
        width: 120,
        height: 120,
        child: thumbnail == null
            ? _AddTile(onTap: editable ? () => _addPhoto(context, ref) : null, label: 'Add')
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.cardRadius,
                    child: AppNetworkImage(
                      url: thumbnail.mediaUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(color: AppColors.neutralTint),
                    ),
                  ),
                  if (editable)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _addPhoto(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
      );
    }

    return media.isEmpty && !editable
        ? Text('No photos added yet', style: AppTextStyles.body(color: AppColors.textSecondary))
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemCount: media.length + (editable ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == media.length) {
                return _AddTile(onTap: () => _addPhoto(context, ref), label: 'Add photos');
              }
              return _tile(context, ref, media[index]);
            },
          );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.label});

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.cardRadius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.neutralTint,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
