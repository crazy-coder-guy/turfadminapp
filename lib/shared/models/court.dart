import 'sport.dart';
import 'amenity.dart';
import 'turf_media.dart';

class Court {
  const Court({
    required this.id,
    required this.turfId,
    required this.name,
    this.description,
    this.courtType,
    this.surfaceType,
    this.capacity,
    required this.isIndoor,
    required this.status,
    this.sports = const [],
    this.amenities = const [],
    this.media = const [],
  });

  final String id;
  final String turfId;
  final String name;
  final String? description;
  final String? courtType;
  final String? surfaceType;
  final int? capacity;
  final bool isIndoor;
  final String status;
  final List<Sport> sports;
  final List<Amenity> amenities;
  final List<TurfMedia> media;

  bool get isActive => status == 'active';

  TurfMedia? get thumbnailMedia {
    for (final item in media) {
      if (item.isThumbnail) return item;
    }
    return null;
  }

  List<TurfMedia> get galleryMedia =>
      media.where((item) => item.isGallery).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<TurfMedia> get reviewMedia => media.where((item) => item.isReview).toList();

  factory Court.fromJson(Map<String, dynamic> json) {
    final sportsJson = json['courtSports'] as List<dynamic>? ?? const [];
    final amenitiesJson = json['courtAmenities'] as List<dynamic>? ?? const [];
    final mediaJson = json['media'] as List<dynamic>? ?? const [];

    return Court(
      id: json['id'] as String,
      turfId: json['turf_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      courtType: json['court_type'] as String?,
      surfaceType: json['surface_type'] as String?,
      capacity: json['capacity'] as int?,
      isIndoor: json['is_indoor'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      sports: sportsJson
          .map((e) => (e as Map<String, dynamic>)['sport'])
          .whereType<Map<String, dynamic>>()
          .map(Sport.fromJson)
          .toList(),
      amenities: amenitiesJson
          .map((e) => (e as Map<String, dynamic>)['amenity'])
          .whereType<Map<String, dynamic>>()
          .map(Amenity.fromJson)
          .toList(),
      media: mediaJson.map((e) => TurfMedia.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
