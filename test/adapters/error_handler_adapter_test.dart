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
        expect(adapter.formatErrorMessage(error), '连接超时，请检查网络');
      });

      test('should format sendTimeout', () {
        final error = DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), '发送超时，请检查网络');
      });

      test('should format receiveTimeout', () {
        final error = DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), '接收超时，请检查网络');
      });

      test('should format badResponse with status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 404),
        );
        expect(adapter.formatErrorMessage(error), '服务器响应错误: 404');
      });

      test('should format cancel', () {
        final error = DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), '请求已取消');
      });

      test('should format connectionError', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), '网络连接失败，请检查网络');
      });

      test('should format badCertificate', () {
        final error = DioException(
          type: DioExceptionType.badCertificate,
          requestOptions: RequestOptions(),
        );
        expect(adapter.formatErrorMessage(error), 'SSL 证书验证失败，请检查网络配置');
      });

      test('should format unknown error', () {
        final error = DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(),
          message: 'Something went wrong',
        );
        expect(adapter.formatErrorMessage(error), '未知错误: Something went wrong');
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
