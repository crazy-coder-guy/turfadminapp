const String kMediaCategoryThumbnail = 'thumbnail';
const String kMediaCategoryGallery = 'gallery';
const String kMediaCategoryReview = 'review';

class TurfMedia {
  const TurfMedia({
    required this.id,
    required this.mediaType,
    required this.mediaUrl,
    required this.category,
    required this.isPrimary,
    required this.sortOrder,
  });

  final String id;
  final String mediaType;
  final String mediaUrl;
  final String category;
  final bool isPrimary;
  final int sortOrder;

  bool get isImage => mediaType == 'image';
  bool get isThumbnail => category == kMediaCategoryThumbnail;
  bool get isGallery => category == kMediaCategoryGallery;
  bool get isReview => category == kMediaCategoryReview;

  factory TurfMedia.fromJson(Map<String, dynamic> json) {
    return TurfMedia(
      id: json['id'] as String,
      mediaType: json['media_type'] as String,
      mediaUrl: json['media_url'] as String,
      category: json['category'] as String? ?? kMediaCategoryGallery,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
