import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:koi_network/src/adapters/error_handler_adapter.dart';

void main() {
  group('KoiDefaultErrorHandlerAdapter', () {
    late KoiDefaultErrorHandlerAdapter adapter;

    setUp(() {
      adapter = KoiDefaultErrorHandlerAdapter();
    });

    group('formatErrorMessage', () {
      test('should format connectionTimeout', () {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), 'Connection timeout');
      });

      test('should format sendTimeout', () {
        final error = DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), 'Send timeout');
      });

      test('should format receiveTimeout', () {
        final error = DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), 'Receive timeout');
      });

      test('should format badResponse with status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 404),
        );
        expect(adapter.formatErrorMessage(error), 'Server error: 404');
      });

      test('should format cancel', () {
        final error = DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), 'Request cancelled');
      });

      test('should format connectionError', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), 'Connection failed');
      });

      test('should format unknown error', () {
        final error = DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(),
          message: 'Something went wrong',
        );
        expect(
          adapter.formatErrorMessage(error),
          'Unknown error: Something went wrong',
        );
      });
    });

    group('handleAuthError', () {
      test('should return false by default', () async {
        final result = await adapter.handleAuthError(
          statusCode: 401,
          message: 'Unauthorized',
        );
        expect(result, isFalse);
      });
    });

    group('show methods should not throw', () {
      test('showError should not throw', () {
        expect(() => adapter.showError('test error'), returnsNormally);
      });

      test('showSuccess should not throw', () {
        expect(() => adapter.showSuccess('test success'), returnsNormally);
      });

      test('showWarning should not throw', () {
        expect(() => adapter.showWarning('test warning'), returnsNormally);
      });

      test('showInfo should not throw', () {
        expect(() => adapter.showInfo('test info'), returnsNormally);
      });
    });
  });
}
