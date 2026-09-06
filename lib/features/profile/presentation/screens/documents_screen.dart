import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/data/uploads_repository.dart';
import '../../../../shared/models/owner_document.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/documents_providers.dart';
import '../../domain/owner_document_types.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  OwnerDocument? _currentDocumentFor(List<OwnerDocument> documents, String type) {
    final matches = documents.where((document) => document.documentType == type);
    if (matches.isEmpty) return null;
    final nonRejected = matches.where((document) => document.verificationStatus != 'rejected');
    return nonRejected.isNotEmpty ? nonRejected.first : matches.first;
  }

  Future<void> _uploadDocument(
    BuildContext context,
    WidgetRef ref, {
    required String ownerId,
    required OwnerDocumentTypeOption type,
  }) async {
    File? pickedFile;
    bool isSubmitting = false;
    String? error;

    Future<void> setPicked(StateSetter setSheetState, File file) async {
      final validationError = validateUploadFile(file);
      setSheetState(() {
        error = validationError;
        pickedFile = validationError == null ? file : null;
      });
    }

    Future<void> pickFromCamera(StateSetter setSheetState) async {
      try {
        final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
        if (image != null) await setPicked(setSheetState, File(image.path));
      } catch (_) {
        setSheetState(() => error = 'Could not access the camera.');
      }
    }

    Future<void> pickFromFiles(StateSetter setSheetState) async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: kUploadAllowedExtensions,
        );
        final path = result?.files.single.path;
        if (path != null) await setPicked(setSheetState, File(path));
      } catch (_) {
        setSheetState(() => error = 'Could not open the file picker.');
      }
    }

    await AppBottomSheet.show<void>(
      context,
      title: 'Upload ${type.label}',
      builder: (sheetContext, setSheetState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDF, JPG or PNG · up to 3 MB',
            style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.standard),
          if (pickedFile != null)
            _FilePreview(file: pickedFile!)
          else
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
                'No file selected',
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
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
                  onPressed: () => pickFromFiles(setSheetState),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Choose file'),
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
            label: 'Upload',
            isLoading: isSubmitting,
            onPressed: pickedFile == null
                ? null
                : () async {
                    setSheetState(() => isSubmitting = true);
                    try {
                      final uploaded = await ref.read(uploadsRepositoryProvider).upload(
                            pickedFile!,
                            category: 'owner-documents',
                          );
                      await ref.read(documentsRepositoryProvider).create(
                            ownerId,
                            documentType: type.value,
                            documentNumber: kDocumentNumberPendingAdminEntry,
                            documentUrl: uploaded.url,
                          );
                      ref.invalidate(ownerDocumentsProvider);
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    } on AppException catch (e) {
                      setSheetState(() {
                        error = e.message;
                        isSubmitting = false;
                      });
                    } catch (_) {
                      setSheetState(() {
                        error = 'Could not upload the document. Please try again.';
                        isSubmitting = false;
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(ownerDocumentsProvider);
    final owner = ref.watch(authControllerProvider).owner;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Documents',
          style: AppTextStyles.appHeader().copyWith(
            color: const Color(0xFF0F172A),
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
        child: owner == null
            ? const Center(child: CircularProgressIndicator())
            : documentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorStateView(
                  message: 'Unable to load documents.',
                  onRetry: () => ref.invalidate(ownerDocumentsProvider),
                ),
                data: (documents) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: kOwnerDocumentTypes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final type = kOwnerDocumentTypes[index];
                      final document = _currentDocumentFor(documents, type.value);
                      final isActionable = document == null || document.verificationStatus == 'rejected';

                      return InkWell(
                        onTap: isActionable
                            ? () => _uploadDocument(
                                  context,
                                  ref,
                                  ownerId: owner.id,
                                  type: type,
                                )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: AppRadius.cardRadius,
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: document == null
                                      ? Container(
                                          color: AppColors.tertiary,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.upload_outlined,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : AppNetworkImage(
                                          url: document.documentUrl,
                                          errorWidget: Container(
                                            color: AppColors.neutralTint,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.description_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.compact),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(type.label, style: AppTextStyles.cardTitle()),
                                        ),
                                        document == null
                                            ? StatusBadge.notUploaded
                                            : StatusBadge.forDocument(document.verificationStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      document == null
                                          ? 'Tap to upload'
                                          : (document.documentNumber == kDocumentNumberPendingAdminEntry
                                              ? 'Number to be verified by admin'
                                              : document.documentNumber),
                                      style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
                                    ),
                                    if (document?.verificationStatus == 'rejected' &&
                                        document?.rejectionReason != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        document!.rejectionReason!,
                                        style: AppTextStyles.bodySmall(color: AppColors.error),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to resubmit',
                                        style: AppTextStyles.bodySmall(color: AppColors.primary)
                                            .copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.file});

  final File file;

  bool get _isImage {
    final ext = file.path.split('.').last.toLowerCase();
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: Image.file(file, height: 140, width: double.infinity, fit: BoxFit.cover),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.compact),
      decoration: BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              file.path.split(Platform.pathSeparator).last,
              style: AppTextStyles.bodySmall(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
