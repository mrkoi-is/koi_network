import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/executors/request_executor.dart';
import 'package:koi_network/src/models/request_execution_options.dart';

void main() {
  setUp(() {
    KoiNetworkAdapters.registerDefaults();
  });

  tearDown(() {
    KoiNetworkAdapters.clear();
  });

  Response<dynamic> _successResponse(dynamic data) {
    return Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: {'code': 200, 'msg': 'ok', 'data': data},
    );
  }

  Response<dynamic> _failResponse({int code = 500, String msg = 'error'}) {
    return Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: {'code': code, 'msg': msg, 'data': null},
    );
  }

  group('KoiRequestExecutor.execute', () {
    test('should return data on success', () async {
      final result = await KoiRequestExecutor.execute<Map<String, dynamic>>(
        request: () async => _successResponse({'id': 1, 'name': 'test'}),
        options: RequestExecutionOptions<Map<String, dynamic>>(
          showLoading: false,
          showError: false,
        ),
      );

      expect(result, {'id': 1, 'name': 'test'});
    });

    test('should use fromJson to convert data', () async {
      final result = await KoiRequestExecutor.execute<String>(
        request: () async => _successResponse('hello'),
        fromJson: (json) => json.toString(),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: false,
        ),
      );

      expect(result, 'hello');
    });

    test('should return null on business error without rethrow', () async {
      final result = await KoiRequestExecutor.execute<String>(
        request: () async => _failResponse(),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: false,
          needRethrow: false,
        ),
      );

      expect(result, isNull);
    });

    test(
      'should throw RequestLogicException on business error with rethrow',
      () async {
        expect(
          () => KoiRequestExecutor.execute<String>(
            request: () async => _failResponse(code: 500, msg: 'Server error'),
            options: RequestExecutionOptions<String>(
              showLoading: false,
              showError: false,
              needRethrow: true,
            ),
          ),
          throwsA(isA<RequestLogicException>()),
        );
      },
    );

    test('should call onSuccess callback', () async {
      String? received;

      await KoiRequestExecutor.execute<String>(
        request: () async => _successResponse('data'),
        fromJson: (json) => json.toString(),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: false,
          onSuccess: (data) => received = data,
        ),
      );

      expect(received, 'data');
    });

    test('should call onError callback on failure', () async {
      String? errorMsg;

      await KoiRequestExecutor.execute<String>(
        request: () async => _failResponse(),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: false,
          needRethrow: false,
          onError: (e, msg) => errorMsg = msg,
        ),
      );

      expect(errorMsg, 'error');
    });

    test('should call onFinally callback in all cases', () async {
      var called = false;

      await KoiRequestExecutor.execute<String>(
        request: () async => _successResponse('data'),
        fromJson: (json) => json.toString(),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: false,
          onFinally: () => called = true,
        ),
      );

      expect(called, isTrue);
    });

    test('should throw when dataNotNull and data is null', () async {
      expect(
        () => KoiRequestExecutor.execute<String>(
          request: () async => _successResponse(null),
          options: RequestExecutionOptions<String>(
            showLoading: false,
            showError: false,
            dataNotNull: true,
            needRethrow: true,
          ),
        ),
        throwsA(isA<RequestLogicException>()),
      );
    });

    test('should handle successCheck failure', () async {
      expect(
        () => KoiRequestExecutor.execute<int>(
          request: () async => _successResponse(0),
          fromJson: (json) => json as int,
          options: RequestExecutionOptions<int>(
            showLoading: false,
            showError: false,
            needRethrow: true,
            successCheck: (data) => data != null && data > 0,
          ),
        ),
        throwsA(isA<RequestLogicException>()),
      );
    });

    test('should handle DioException', () async {
      String? errorMsg;

      await KoiRequestExecutor.execute<String>(
        request: () async => throw DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: false,
          needRethrow: false,
          onError: (e, msg) => errorMsg = msg,
        ),
      );

      expect(errorMsg, 'Connection timeout');
    });

    test('should handle non-Map response data (e.g. list)', () async {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: [1, 2, 3],
      );

      final result = await KoiRequestExecutor.execute<List<int>>(
        request: () async => response,
        fromJson: (json) => (json as List).cast<int>(),
        options: RequestExecutionOptions<List<int>>(
          showLoading: false,
          showError: false,
        ),
      );

      expect(result, [1, 2, 3]);
    });
  });

  group('KoiRequestExecutor.executeSilent', () {
    test('should not show loading or error', () async {
      final result = await KoiRequestExecutor.executeSilent<String>(
        request: () async => _successResponse('silent'),
        fromJson: (json) => json.toString(),
      );
      expect(result, 'silent');
    });
  });

  group('KoiRequestExecutor.executeQuick', () {
    test('should not show loading but handle result', () async {
      final result = await KoiRequestExecutor.executeQuick<String>(
        request: () async => _successResponse('quick'),
        fromJson: (json) => json.toString(),
      );
      expect(result, 'quick');
    });
  });

  group('KoiRequestExecutor.executeBatch', () {
    test('should execute multiple requests concurrently', () async {
      final results = await KoiRequestExecutor.executeBatch<int>(
        [
          () async => _successResponse(1),
          () async => _successResponse(2),
          () async => _successResponse(3),
        ],
        fromJson: (json) => json as int,
        options: const BatchRequestOptions(showLoading: false),
      );

      expect(results, [1, 2, 3]);
    });

    test('should execute sequentially when concurrent=false', () async {
      final order = <int>[];

      final results = await KoiRequestExecutor.executeBatch<String>(
        [
          () async {
            order.add(1);
            return _successResponse('a');
          },
          () async {
            order.add(2);
            return _successResponse('b');
          },
        ],
        fromJson: (json) => json.toString(),
        options: const BatchRequestOptions(
          concurrent: false,
          showLoading: false,
        ),
      );

      expect(results, ['a', 'b']);
      expect(order, [1, 2]);
    });

    test('should return null for failed requests in batch', () async {
      final results = await KoiRequestExecutor.executeBatch<String>(
        [() async => _successResponse('ok'), () async => _failResponse()],
        fromJson: (json) => json.toString(),
        options: const BatchRequestOptions(showLoading: false),
      );

      expect(results[0], 'ok');
      expect(results[1], isNull);
    });
  });

  group('RequestLogicException', () {
    test('should contain message and code', () {
      final ex = RequestLogicException<String>(
        'test error',
        errorCode: 500,
        data: 'context',
      );
      expect(ex.message, 'test error');
      expect(ex.errorCode, 500);
      expect(ex.data, 'context');
      expect(ex.toString(), contains('test error'));
      expect(ex.toString(), contains('500'));
    });
  });

  group('KoiRequestExecutor.getErrorMessage', () {
    test('should extract message from RequestLogicException', () {
      final msg = KoiRequestExecutor.getErrorMessage(
        RequestLogicException('custom error'),
      );
      expect(msg, 'custom error');
    });

    test('should format DioException', () {
      final msg = KoiRequestExecutor.getErrorMessage(
        DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
        ),
      );
      expect(msg, 'Receive timeout');
    });

    test('should return toString for generic exceptions', () {
      final msg = KoiRequestExecutor.getErrorMessage(Exception('generic'));
      expect(msg, contains('generic'));
    });
  });
}
