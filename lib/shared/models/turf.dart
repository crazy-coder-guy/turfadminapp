import 'amenity.dart';
import 'court.dart';
import 'turf_location.dart';
import 'turf_media.dart';

enum TurfApprovalStatus { draft, submitted, underReview, approved, rejected }

TurfApprovalStatus approvalStatusFromString(String value) {
  switch (value) {
    case 'submitted':
      return TurfApprovalStatus.submitted;
    case 'under_review':
      return TurfApprovalStatus.underReview;
    case 'approved':
      return TurfApprovalStatus.approved;
    case 'rejected':
      return TurfApprovalStatus.rejected;
    case 'draft':
    default:
      return TurfApprovalStatus.draft;
  }
}

class Turf {
  const Turf({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.contactPhone,
    this.contactEmail,
    required this.status,
    required this.approvalStatus,
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    this.location,
    this.media = const [],
    this.courts = const [],
    this.amenities = const [],
    this.hasPendingChanges = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String contactPhone;
  final String? contactEmail;
  final String status;
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final TurfLocation? location;
  final List<TurfMedia> media;
  final List<Court> courts;
  final List<Amenity> amenities;

  /// True once an approved/live turf has been edited by the owner and is
  /// awaiting a super admin's re-review. The turf keeps showing as LIVE with
  /// its last-approved data - editing doesn't take the listing down, it just
  /// flags it for another look.
  final bool hasPendingChanges;

  final DateTime createdAt;
  final DateTime updatedAt;

  TurfApprovalStatus get approvalStatusEnum => approvalStatusFromString(approvalStatus);

  bool get isLive => approvalStatus == 'approved' && status == 'active';

  bool get isEditable => approvalStatus == 'draft' || approvalStatus == 'rejected';

  bool get canSubmit => approvalStatus == 'draft' || approvalStatus == 'rejected';

  /// The backend only locks media edits while a turf is actively being
  /// reviewed (submitted/under_review) - unlike [isEditable], which also
  /// covers turf details/courts and stays false once approved.
  bool get canEditMedia => approvalStatus != 'submitted' && approvalStatus != 'under_review';

  TurfMedia? get thumbnailMedia {
    for (final item in media) {
      if (item.isThumbnail) return item;
    }
    return null;
  }

  List<TurfMedia> get galleryMedia =>
      media.where((item) => item.isGallery).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<TurfMedia> get reviewMedia => media.where((item) => item.isReview).toList();

  TurfMedia? get primaryMedia => thumbnailMedia ?? (galleryMedia.isNotEmpty ? galleryMedia.first : null);

  factory Turf.fromJson(Map<String, dynamic> json) {
    final amenitiesJson = json['turfAmenities'] as List<dynamic>? ?? const [];
    final mediaJson = json['media'] as List<dynamic>? ?? const [];
    final courtsJson = json['courts'] as List<dynamic>? ?? const [];

    return Turf(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      contactPhone: json['contact_phone'] as String? ?? '',
      contactEmail: json['contact_email'] as String?,
      status: json['status'] as String? ?? 'active',
      approvalStatus: json['approval_status'] as String? ?? 'draft',
      rejectionReason: json['rejection_reason'] as String?,
      approvedAt:
          json['approved_at'] != null ? DateTime.tryParse(json['approved_at'] as String) : null,
      rejectedAt:
          json['rejected_at'] != null ? DateTime.tryParse(json['rejected_at'] as String) : null,
      location: json['location'] != null
          ? TurfLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      media: mediaJson.map((e) => TurfMedia.fromJson(e as Map<String, dynamic>)).toList(),
      courts: courtsJson.map((e) => Court.fromJson(e as Map<String, dynamic>)).toList(),
      amenities: amenitiesJson
          .map((e) => (e as Map<String, dynamic>)['amenity'])
          .whereType<Map<String, dynamic>>()
          .map(Amenity.fromJson)
          .toList(),
      hasPendingChanges: json['has_pending_changes'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
