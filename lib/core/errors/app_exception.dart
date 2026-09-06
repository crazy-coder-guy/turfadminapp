import 'package:dio/dio.dart';

enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  unknown,
}

class AppException implements Exception {
  const AppException(this.type, this.message, {this.fieldErrors, this.statusCode});

  final AppErrorType type;
  final String message;
  final Map<String, String>? fieldErrors;
  final int? statusCode;

  bool get isUnauthorized => type == AppErrorType.unauthorized;

  static const Map<String, String> _codeMessages = {
    'invalid-credentials': 'Incorrect email or password.',
    'invalid-refresh-token': 'Your session has expired. Please sign in again.',
    'owner-not-found': 'Account not found.',
    'owner-forbidden': 'You don’t have permission to access this resource.',
    'turf-not-found': 'This turf could not be found.',
    'turf-forbidden': 'You don’t have permission to access this turf.',
    'turf-locked-for-review':
        'This turf can’t be edited while it’s submitted or under review.',
    'turf-not-eligible-for-submission': 'This turf can’t be submitted in its current state.',
    'invalid-sport': 'One of the selected sports is invalid or inactive.',
    'invalid-amenity': 'One of the selected amenities is invalid or inactive.',
    'court-not-found': 'This court could not be found.',
    'owner-document-not-found': 'This document could not be found.',
    'turf-media-not-found': 'This media item could not be found.',
  };

  static AppException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          AppErrorType.timeout,
          'The request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          AppErrorType.network,
          'Unable to connect. Check your internet connection.',
        );
      case DioExceptionType.cancel:
        return const AppException(AppErrorType.unknown, 'Request was cancelled.');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return const AppException(
          AppErrorType.network,
          'Unable to connect. Check your internet connection.',
        );
    }
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode ?? 0;
    final body = response?.data;
    final Map<String, dynamic>? data = body is Map<String, dynamic> ? body : null;

    Map<String, String>? fieldErrors;
    final dynamic hint = data?['hint'];
    if (hint is Map) {
      fieldErrors = hint.map((key, value) => MapEntry(key.toString(), value.toString()));
    }

    final String? code = (data?['message'] ?? data?['errorCode'])?.toString();
    final AppErrorType type = _typeForStatus(statusCode);

    if (code != null && _codeMessages.containsKey(code)) {
      return AppException(type, _codeMessages[code]!, fieldErrors: fieldErrors, statusCode: statusCode);
    }

    return AppException(type, _genericMessageForStatus(statusCode), fieldErrors: fieldErrors, statusCode: statusCode);
  }

  static AppErrorType _typeForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return AppErrorType.unauthorized;
      case 403:
        return AppErrorType.forbidden;
      case 404:
        return AppErrorType.notFound;
      case 409:
        return AppErrorType.conflict;
      case 400:
      case 422:
        return AppErrorType.validation;
      default:
        return statusCode >= 500 ? AppErrorType.server : AppErrorType.unknown;
    }
  }

  static String _genericMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You don’t have permission to access this resource.';
      case 404:
        return 'The requested item could not be found.';
      case 409:
        return 'These details already exist.';
      case 400:
      case 422:
        return 'Please check the highlighted fields and try again.';
      default:
        return statusCode >= 500
            ? 'Something went wrong. Please try again.'
            : 'Something went wrong. Please try again.';
    }
  }
}
