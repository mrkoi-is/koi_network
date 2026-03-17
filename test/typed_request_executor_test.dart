import 'package:koi_network/koi_network.dart';
import 'package:test/test.dart';

// ==================== 测试用 Mock 类 ====================

/// 模拟 BaseResult<T>，实现 KoiTypedResponse<T>
class MockTypedResult<T> implements KoiTypedResponse<T> {
  MockTypedResult({
    required this.isSuccess,
    this.code,
    this.message,
    this.data,
  });

  @override
  final bool isSuccess;

  @override
  final int? code;

  @override
  final String? message;

  @override
  final T? data;
}

/// 模拟加载适配器
class MockLoadingAdapter implements KoiLoadingAdapter {
  int showCount = 0;
  int hideCount = 0;

  @override
  void showLoading({String? message}) => showCount++;

  @override
  void hideLoading() => hideCount++;

  @override
  void showProgress({required double progress, String? message}) {}

  @override
  void hideProgress() {}

  @override
  bool isLoading() => false;
}

/// 模拟错误处理适配器
class MockErrorHandlerAdapter implements KoiErrorHandlerAdapter {
  final List<String> errors = [];

  @override
  void showError(String message) => errors.add(message);

  @override
  Future<bool> handleAuthError({int? statusCode, String? message}) async =>
      true;

  @override
  String formatErrorMessage(Object error) => error.toString();

  @override
  void showSuccess(String message) {}

  @override
  void showWarning(String message) {}

  @override
  void showInfo(String message) {}
}

void main() {
  late MockLoadingAdapter mockLoading;
  late MockErrorHandlerAdapter mockErrorHandler;

  setUp(() {
    mockLoading = MockLoadingAdapter();
    mockErrorHandler = MockErrorHandlerAdapter();

    KoiNetworkAdapters.register(
      authAdapter: KoiDefaultAuthAdapter(),
      errorHandlerAdapter: mockErrorHandler,
      loadingAdapter: mockLoading,
      platformAdapter: KoiDefaultPlatformAdapter(),
    );
  });

  tearDown(() {
    KoiNetworkAdapters.clear();
  });

  group('KoiTypedRequestExecutor', () {
    group('execute', () {
      test('成功请求返回数据', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'hello',
          ),
        );

        expect(result, 'hello');
        expect(mockLoading.showCount, 1);
        expect(mockLoading.hideCount, 1);
      });

      test('成功请求触发 onSuccess 回调', () async {
        String? received;

        await KoiTypedRequestExecutor.execute<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'world',
          ),
          options: RequestExecutionOptions<String>(
            onSuccess: (data) => received = data,
          ),
        );

        expect(received, 'world');
      });

      test('业务失败抛出 RequestLogicException', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: false,
            code: 500,
            message: 'Server Error',
          ),
        );

        expect(result, isNull);
        expect(mockErrorHandler.errors, contains('Server Error'));
      });

      test('业务失败无消息使用默认消息', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async =>
              MockTypedResult<String>(isSuccess: false, code: 500),
        );

        expect(result, isNull);
        expect(mockErrorHandler.errors, contains('Operation failed'));
      });

      test('dataNotNull 为 true 时 data 为 null 抛出异常', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async =>
              MockTypedResult<String>(isSuccess: true, code: 200),
          options: const RequestExecutionOptions<String>(dataNotNull: true),
        );

        expect(result, isNull);
        expect(mockErrorHandler.errors, contains('No data available'));
      });

      test('dataNotNull 为 false 时 data 为 null 返回 null', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async =>
              MockTypedResult<String>(isSuccess: true, code: 200),
          options: const RequestExecutionOptions<String>(dataNotNull: false),
        );

        expect(result, isNull);
        expect(mockErrorHandler.errors, isEmpty);
      });

      test('异常触发 onError 回调', () async {
        String? errorMsg;

        await KoiTypedRequestExecutor.execute<String>(
          request: () async => throw Exception('Network error'),
          options: RequestExecutionOptions<String>(
            onError: (e, msg) => errorMsg = msg,
          ),
        );

        expect(errorMsg, isNotNull);
      });

      test('needRethrow 为 true 时重新抛出异常', () async {
        expect(
          () => KoiTypedRequestExecutor.execute<String>(
            request: () async => throw Exception('Boom'),
            options: const RequestExecutionOptions<String>(needRethrow: true),
          ),
          throwsException,
        );
      });

      test('onFinally 始终被调用', () async {
        var finallyCalled = false;

        await KoiTypedRequestExecutor.execute<String>(
          request: () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'test'),
          options: RequestExecutionOptions<String>(
            onFinally: () => finallyCalled = true,
          ),
        );

        expect(finallyCalled, isTrue);
      });

      test('错误时 onFinally 也被调用', () async {
        var finallyCalled = false;

        await KoiTypedRequestExecutor.execute<String>(
          request: () async => throw Exception('error'),
          options: RequestExecutionOptions<String>(
            onFinally: () => finallyCalled = true,
          ),
        );

        expect(finallyCalled, isTrue);
      });

      test('successCheck 失败抛出异常', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'bad'),
          options: RequestExecutionOptions<String>(
            successCheck: (data) => data == 'good',
          ),
        );

        expect(result, isNull);
        expect(mockErrorHandler.errors, contains('Operation failed'));
      });

      test('dataCheck 失败抛出异常', () async {
        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: ''),
          options: RequestExecutionOptions<String>(
            dataCheck: (data) => data != null && data.isNotEmpty,
          ),
        );

        expect(result, isNull);
        expect(mockErrorHandler.errors, contains('Invalid data format'));
      });

      test('dataCheck 成功返回数据并调用 onSuccess', () async {
        String? received;

        final result = await KoiTypedRequestExecutor.execute<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'valid',
          ),
          options: RequestExecutionOptions<String>(
            dataCheck: (data) => data != null && data.isNotEmpty,
            onSuccess: (data) => received = data,
          ),
        );

        expect(result, 'valid');
        expect(received, 'valid');
      });

      test('showLoading 为 false 时不调用加载适配器', () async {
        await KoiTypedRequestExecutor.execute<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'no-loading',
          ),
          options: const RequestExecutionOptions<String>(showLoading: false),
        );

        expect(mockLoading.showCount, 0);
        expect(mockLoading.hideCount, 0);
      });

      test('showError 为 false 时不显示错误', () async {
        await KoiTypedRequestExecutor.execute<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: false,
            code: 500,
            message: 'hidden error',
          ),
          options: const RequestExecutionOptions<String>(showError: false),
        );

        expect(mockErrorHandler.errors, isEmpty);
      });
    });

    group('executeSilent', () {
      test('不显示加载和错误', () async {
        final result = await KoiTypedRequestExecutor.executeSilent<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: false,
            code: 500,
            message: 'silent error',
          ),
        );

        expect(result, isNull);
        expect(mockLoading.showCount, 0);
        expect(mockErrorHandler.errors, isEmpty);
      });

      test('成功时调用 onSuccess', () async {
        String? received;

        await KoiTypedRequestExecutor.executeSilent<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'silent-ok',
          ),
          onSuccess: (data) => received = data,
        );

        expect(received, 'silent-ok');
      });
    });

    group('executeQuick', () {
      test('不显示加载但显示错误', () async {
        await KoiTypedRequestExecutor.executeQuick<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: false,
            code: 500,
            message: 'quick error',
          ),
        );

        expect(mockLoading.showCount, 0);
        expect(mockErrorHandler.errors, contains('quick error'));
      });
    });

    group('executeBatch', () {
      test('并发执行多个请求', () async {
        final results = await KoiTypedRequestExecutor.executeBatch<String>([
          () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'a'),
          () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'b'),
        ]);

        expect(results, ['a', 'b']);
      });

      test('顺序执行多个请求', () async {
        final results = await KoiTypedRequestExecutor.executeBatch<String>([
          () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'x'),
          () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'y'),
        ], options: const TypedBatchRequestOptions(concurrent: false));

        expect(results, ['x', 'y']);
      });

      test('失败请求返回 null（stopOnFirstError=false）', () async {
        final results = await KoiTypedRequestExecutor.executeBatch<String>([
          () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'ok'),
          () async => MockTypedResult<String>(
            isSuccess: false,
            code: 500,
            message: 'Failed',
          ),
        ]);

        expect(results, ['ok', null]);
      });

      test('stopOnFirstError=true 并发模式抛出异常', () async {
        expect(
          () => KoiTypedRequestExecutor.executeBatch<String>([
            () async => MockTypedResult<String>(
              isSuccess: false,
              code: 500,
              message: 'Stop!',
            ),
          ], options: const TypedBatchRequestOptions(stopOnFirstError: true)),
          throwsA(isA<RequestLogicException<String>>()),
        );
      });

      test('stopOnFirstError=true 顺序模式抛出异常', () async {
        expect(
          () => KoiTypedRequestExecutor.executeBatch<String>(
            [
              () async => MockTypedResult<String>(
                isSuccess: false,
                code: 500,
                message: 'Stop!',
              ),
            ],
            options: const TypedBatchRequestOptions(
              stopOnFirstError: true,
              concurrent: false,
            ),
          ),
          throwsA(isA<RequestLogicException<String>>()),
        );
      });

      test('顺序执行失败不中断（stopOnFirstError=false）', () async {
        final results = await KoiTypedRequestExecutor.executeBatch<String>([
          () async => throw Exception('oops'),
          () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'still-ok',
          ),
        ], options: const TypedBatchRequestOptions(concurrent: false));

        expect(results, [null, 'still-ok']);
      });

      test('showLoading 控制', () async {
        await KoiTypedRequestExecutor.executeBatch<String>([
          () async =>
              MockTypedResult<String>(isSuccess: true, code: 200, data: 'ok'),
        ], options: const TypedBatchRequestOptions(showLoading: false));

        expect(mockLoading.showCount, 0);
      });
    });

    group('executeWithRetry', () {
      test('首次成功直接返回', () async {
        final result = await KoiTypedRequestExecutor.executeWithRetry<String>(
          request: () async => MockTypedResult<String>(
            isSuccess: true,
            code: 200,
            data: 'first-try',
          ),
          maxRetries: 3,
          delay: Duration.zero,
        );

        expect(result, 'first-try');
      });

      test('全部失败后抛出异常', () async {
        expect(
          () => KoiTypedRequestExecutor.executeWithRetry<String>(
            request: () async => MockTypedResult<String>(
              isSuccess: false,
              code: 500,
              message: 'always-fail',
            ),
            maxRetries: 2,
            delay: Duration.zero,
            options: const RequestExecutionOptions<String>(needRethrow: true),
          ),
          throwsA(isA<RequestLogicException<String>>()),
        );
      });

      test('重试后成功返回', () async {
        var attempt = 0;

        final result = await KoiTypedRequestExecutor.executeWithRetry<String>(
          request: () async {
            attempt++;
            if (attempt < 3) {
              throw Exception('not yet');
            }
            return MockTypedResult<String>(
              isSuccess: true,
              code: 200,
              data: 'ok-after-retry',
            );
          },
          maxRetries: 3,
          delay: Duration.zero,
        );

        expect(result, 'ok-after-retry');
        expect(attempt, 3);
      });
    });
  });

  group('KoiTypedResponse', () {
    test('MockTypedResult 正确实现接口', () {
      final result = MockTypedResult<int>(
        isSuccess: true,
        code: 200,
        message: 'OK',
        data: 42,
      );

      expect(result.isSuccess, isTrue);
      expect(result.code, 200);
      expect(result.message, 'OK');
      expect(result.data, 42);
    });
  });
}
