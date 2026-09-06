import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/providers.dart';

const List<String> kUploadAllowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
const List<String> kUploadImageOnlyExtensions = ['jpg', 'jpeg', 'png'];
const int kUploadMaxSizeBytes = 3 * 1024 * 1024;

String? validateUploadFile(File file, {List<String> allowedExtensions = kUploadAllowedExtensions}) {
  final ext = file.path.split('.').last.toLowerCase();
  if (!allowedExtensions.contains(ext)) {
    final label = allowedExtensions.map((e) => e.toUpperCase()).toSet().join(', ');
    return 'Only $label files are allowed.';
  }
  final size = file.lengthSync();
  if (size > kUploadMaxSizeBytes) {
    return 'File must be 3 MB or smaller.';
  }
  return null;
}

class UploadedFile {
  const UploadedFile({required this.url, required this.key});

  final String url;
  final String key;
}

class UploadsRepository {
  UploadsRepository(this._client);

  final ApiClient _client;

  Future<UploadedFile> upload(File file, {required String category}) async {
    final response = await _client.postMultipart(
      '/uploads',
      file: file,
      fieldName: 'file',
      fields: {'category': category},
    );
    final data = response['data'] as Map<String, dynamic>;
    return UploadedFile(url: data['url'] as String, key: data['key'] as String);
  }
}

final uploadsRepositoryProvider = Provider<UploadsRepository>((ref) {
  return UploadsRepository(ref.read(apiClientProvider));
});
