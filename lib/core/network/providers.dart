import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';
import 'api_client.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.read(secureStorageProvider));
});
