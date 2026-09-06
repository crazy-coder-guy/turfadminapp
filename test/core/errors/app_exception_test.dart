import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turf_admin_app/core/errors/app_exception.dart';

DioException _responseError(int statusCode, Map<String, dynamic> body) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: requestOptions, statusCode: statusCode, data: body),
  );
}

void main() {
  group('AppException.fromDioException', () {
    test('maps a known error code to a friendly message', () {
      final exception = AppException.fromDioException(
        _responseError(401, {'success': false, 'message': 'invalid-credentials'}),
      );
      expect(exception.type, AppErrorType.unauthorized);
      expect(exception.message, 'Incorrect email or password.');
    });

    test('falls back to a generic message for an unknown error code', () {
      final exception = AppException.fromDioException(
        _responseError(500, {'success': false, 'message': 'some-unmapped-code'}),
      );
      expect(exception.type, AppErrorType.server);
      expect(exception.message, 'Something went wrong. Please try again.');
    });

    test('extracts field errors from a validation (hint) response', () {
      final exception = AppException.fromDioException(
        _responseError(400, {
          'errorCode': 'invalid-request',
          'hint': {'email': 'Invalid value'},
        }),
      );
      expect(exception.type, AppErrorType.validation);
      expect(exception.fieldErrors, {'email': 'Invalid value'});
    });

    test('maps a connection timeout to a network-friendly message', () {
      final requestOptions = RequestOptions(path: '/test');
      final exception = AppException.fromDioException(
        DioException(requestOptions: requestOptions, type: DioExceptionType.connectionTimeout),
      );
      expect(exception.type, AppErrorType.timeout);
    });

    test('maps a connection error to network type', () {
      final requestOptions = RequestOptions(path: '/test');
      final exception = AppException.fromDioException(
        DioException(requestOptions: requestOptions, type: DioExceptionType.connectionError),
      );
      expect(exception.type, AppErrorType.network);
      expect(exception.message, contains('Unable to connect'));
    });

    test('maps 403 to forbidden', () {
      final exception = AppException.fromDioException(_responseError(403, {}));
      expect(exception.type, AppErrorType.forbidden);
    });

    test('maps 404 to notFound', () {
      final exception = AppException.fromDioException(_responseError(404, {}));
      expect(exception.type, AppErrorType.notFound);
    });
  });
}
