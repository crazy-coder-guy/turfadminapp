import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({required SecureStorageService storage, this.onSessionExpired})
      : _storage = storage,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        ),
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
          ),
        ) {
    _dio.interceptors.add(_authInterceptor());
    if (AppConfig.enableNetworkLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) {
            final text = obj.toString();
            if (text.contains('Authorization') || text.contains('refresh_token')) return;
            debugPrint(text);
          },
        ),
      );
    }
  }

  final Dio _dio;
  final Dio _refreshDio;
  final SecureStorageService _storage;

  VoidCallback? onSessionExpired;

  Completer<bool>? _refreshCompleter;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isRefreshCall = error.requestOptions.path.contains('/owners/refresh-token');

        if (!isUnauthorized || isRefreshCall) {
          handler.next(error);
          return;
        }

        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          onSessionExpired?.call();
          handler.next(error);
          return;
        }

        try {
          final retryResponse = await _retry(error.requestOptions);
          handler.resolve(retryResponse);
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    );
  }

  Future<bool> _refreshAccessToken() {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await _storage.readRefreshToken();
        if (refreshToken == null) {
          completer.complete(false);
          return;
        }

        final response = await _refreshDio.post(
          '/owners/refresh-token',
          data: {'refresh_token': refreshToken},
        );

        final data = response.data['data'] as Map<String, dynamic>;
        await _storage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        completer.complete(true);
      } catch (_) {
        completer.complete(false);
      } finally {
        _refreshCompleter = null;
      }
    }();

    return completer.future;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.readAccessToken();
    final options = Options(method: requestOptions.method, headers: {
      ...requestOptions.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    });
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, {Object? data}) =>
      _send(() => _dio.post(path, data: data));

  Future<Map<String, dynamic>> put(String path, {Object? data}) =>
      _send(() => _dio.put(path, data: data));

  Future<Map<String, dynamic>> patch(String path, {Object? data}) =>
      _send(() => _dio.patch(path, data: data));

  Future<Map<String, dynamic>> delete(String path, {Object? data}) =>
      _send(() => _dio.delete(path, data: data));

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) {
    return _send(() async {
      final formData = FormData.fromMap({
        ...?fields,
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      return _dio.post(path, data: formData);
    });
  }

  Future<Uint8List> getBytes(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (error) {
      throw AppException.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return <String, dynamic>{'success': true, 'data': body};
    } on DioException catch (error) {
      throw AppException.fromDioException(error);
    }
  }
}
