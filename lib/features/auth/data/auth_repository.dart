import '../../../core/network/api_client.dart';
import '../../../shared/models/auth_tokens.dart';
import '../../../shared/models/owner.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<Owner> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String profileImageUrl,
    required String ownerType,
    required String businessName,
    required String panNumber,
    String? gstin,
  }) async {
    final response = await _client.post('/owners', data: {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'password': password,
      'profile_image_url': profileImageUrl,
      'owner_type': ownerType,
      'business_name': businessName,
      'pan_number': panNumber,
      if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
    });
    return Owner.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<(AuthTokens, Owner)> login({required String email, required String password}) async {
    final response = await _client.post('/owners/login', data: {
      'email': email,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(data);
    final owner = Owner.fromJson(data['owner'] as Map<String, dynamic>);
    return (tokens, owner);
  }

  Future<void> logout(String refreshToken) async {
    await _client.post('/owners/logout', data: {'refresh_token': refreshToken});
  }

  Future<Owner> me() async {
    final response = await _client.get('/owners/me');
    return Owner.fromJson(response['data'] as Map<String, dynamic>);
  }
}
