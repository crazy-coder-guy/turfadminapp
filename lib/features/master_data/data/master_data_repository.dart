import '../../../core/network/api_client.dart';
import '../../../shared/models/amenity.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/sport.dart';

class MasterDataRepository {
  MasterDataRepository(this._client);

  final ApiClient _client;

  Future<List<Sport>> getSports() async {
    final response = await _client.get('/sports', query: {'pageSize': 100});
    final page = PaginatedResponse.fromJson(response['data'] as Map<String, dynamic>, Sport.fromJson);
    return page.items;
  }

  Future<List<Amenity>> getAmenities() async {
    final response = await _client.get('/amenities', query: {'pageSize': 100});
    final page =
        PaginatedResponse.fromJson(response['data'] as Map<String, dynamic>, Amenity.fromJson);
    return page.items;
  }
}
