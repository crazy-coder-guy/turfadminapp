import '../../../core/network/api_client.dart';
import '../../../shared/models/court.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/turf.dart';
import '../../../shared/models/turf_location.dart';
import '../../../shared/models/turf_media.dart';

class TurfRepository {
  TurfRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<Turf>> listTurfs({
    String? approvalStatus,
    int page = 1,
    int pageSize = 25,
  }) async {
    final response = await _client.get('/turfs', query: {
      if (approvalStatus != null) 'approval_status': approvalStatus,
      'page': page,
      'pageSize': pageSize,
    });
    return PaginatedResponse.fromJson(response['data'] as Map<String, dynamic>, Turf.fromJson);
  }

  Future<Turf> getTurf(String turfId) async {
    final response = await _client.get('/turfs/$turfId');
    return Turf.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Turf> createTurf({
    required String name,
    String? description,
    required String contactPhone,
    String? contactEmail,
    TurfLocation? location,
    List<String> amenityIds = const [],
  }) async {
    final response = await _client.post('/turfs', data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'contact_phone': contactPhone,
      if (contactEmail != null && contactEmail.isNotEmpty) 'contact_email': contactEmail,
      if (location != null) 'location': location.toJson(),
      if (amenityIds.isNotEmpty) 'amenity_ids': amenityIds,
    });
    return Turf.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Turf> updateTurf(
    String turfId, {
    String? name,
    String? description,
    String? contactPhone,
    String? contactEmail,
    TurfLocation? location,
    List<String>? amenityIds,
  }) async {
    final response = await _client.patch('/turfs/$turfId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (contactEmail != null) 'contact_email': contactEmail,
      if (location != null) 'location': location.toJson(),
      if (amenityIds != null) 'amenity_ids': amenityIds,
    });
    return Turf.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deactivateTurf(String turfId) => _client.delete('/turfs/$turfId');

  Future<Turf> submitTurf(String turfId) async {
    final response = await _client.post('/turfs/$turfId/submit');
    return Turf.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Court> createCourt(
    String turfId, {
    required String name,
    String? description,
    String? courtType,
    String? surfaceType,
    int? capacity,
    bool isIndoor = false,
    List<String> sportIds = const [],
    List<String> amenityIds = const [],
  }) async {
    final response = await _client.post('/turfs/$turfId/courts', data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (courtType != null && courtType.isNotEmpty) 'court_type': courtType,
      if (surfaceType != null && surfaceType.isNotEmpty) 'surface_type': surfaceType,
      if (capacity != null) 'capacity': capacity,
      'is_indoor': isIndoor,
      if (sportIds.isNotEmpty) 'sport_ids': sportIds,
      if (amenityIds.isNotEmpty) 'amenity_ids': amenityIds,
    });
    return Court.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Court> updateCourt(
    String turfId,
    String courtId, {
    String? name,
    String? description,
    String? courtType,
    String? surfaceType,
    int? capacity,
    bool? isIndoor,
    String? status,
    List<String>? sportIds,
    List<String>? amenityIds,
  }) async {
    final response = await _client.patch('/turfs/$turfId/courts/$courtId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (courtType != null) 'court_type': courtType,
      if (surfaceType != null) 'surface_type': surfaceType,
      if (capacity != null) 'capacity': capacity,
      if (isIndoor != null) 'is_indoor': isIndoor,
      if (status != null) 'status': status,
      if (sportIds != null) 'sport_ids': sportIds,
      if (amenityIds != null) 'amenity_ids': amenityIds,
    });
    return Court.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deactivateCourt(String turfId, String courtId) =>
      _client.delete('/turfs/$turfId/courts/$courtId');

  Future<TurfMedia> addMedia(
    String turfId, {
    required String mediaType,
    required String mediaUrl,
    required String category,
    bool isPrimary = false,
    int sortOrder = 0,
  }) async {
    final response = await _client.post('/turfs/$turfId/media', data: {
      'media_type': mediaType,
      'media_url': mediaUrl,
      'category': category,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    });
    return TurfMedia.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMedia(String turfId, String mediaId) =>
      _client.delete('/turfs/$turfId/media/$mediaId');

  Future<TurfMedia> addCourtMedia(
    String turfId,
    String courtId, {
    required String mediaType,
    required String mediaUrl,
    required String category,
    bool isPrimary = false,
    int sortOrder = 0,
  }) async {
    final response = await _client.post('/turfs/$turfId/courts/$courtId/media', data: {
      'media_type': mediaType,
      'media_url': mediaUrl,
      'category': category,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    });
    return TurfMedia.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCourtMedia(String turfId, String courtId, String mediaId) =>
      _client.delete('/turfs/$turfId/courts/$courtId/media/$mediaId');
}
