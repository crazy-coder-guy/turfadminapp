import '../../../core/network/api_client.dart';
import '../../../shared/models/owner_document.dart';
import '../../../shared/models/paginated_response.dart';

class DocumentsRepository {
  DocumentsRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<OwnerDocument>> list(String ownerId) async {
    final response = await _client.get('/owners/$ownerId/documents', query: {'pageSize': 50});
    return PaginatedResponse.fromJson(
      response['data'] as Map<String, dynamic>,
      OwnerDocument.fromJson,
    );
  }

  Future<OwnerDocument> create(
    String ownerId, {
    required String documentType,
    required String documentNumber,
    required String documentUrl,
  }) async {
    final response = await _client.post('/owners/$ownerId/documents', data: {
      'document_type': documentType,
      'document_number': documentNumber,
      'document_url': documentUrl,
    });
    return OwnerDocument.fromJson(response['data'] as Map<String, dynamic>);
  }
}
