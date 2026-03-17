// 覆盖率补充测试 - KoiTypedRequestExecutor debug 分支 & KoiNetworkRequestMixin typed 方法
// Coverage gap tests for typed executor debug branches and mixin typed methods

import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';
import 'package:test/test.dart';

/// 模拟 BaseResult<T>
class _MockResult<T> implements KoiTypedResponse<T> {
  _MockResult({required this.isSuccess, this.code, this.message, this.data});

  @override
  final bool isSuccess;
  @override
  final int? code;
  @override
  final String? message;
  @override
  final T? data;
}

/// Mock 加载适配器
class _MockLoading implements KoiLoadingAdapter {
  @override
  void showLoading({String? message}) {}
  @override
  void hideLoading() {}
  @override
  void showProgress({required double progress, String? message}) {}
  @override
  void hideProgress() {}
  @override
  bool isLoading() => false;
}

/// Mock 错误处理适配器
class _MockErrorHandler implements KoiErrorHandlerAdapter {
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

/// 使用 mixin 的测试类
class _TestController with KoiNetworkRequestMixin {}

void main() {
  late _MockErrorHandler mockErrorHandler;

  setUp(() {
    mockErrorHandler = _MockErrorHandler();
    KoiNetworkAdapters.register(
      authAdapter: KoiDefaultAuthAdapter(),
      errorHandlerAdapter: mockErrorHandler,
      loadingAdapter: _MockLoading(),
      platformAdapter: KoiDefaultPlatformAdapter(),
    );
  });

  tearDown(() {
    KoiNetworkConstants.debugEnabled = false;
    KoiNetworkAdapters.clear();
  });

  // =====================================================
  // KoiTypedRequestExecutor - debugEnabled 分支覆盖
  // =====================================================
  group('KoiTypedRequestExecutor debugEnabled 分支', () {
    test('executeBatch 并发失败时 debugEnabled=true 输出日志 (line 261)', () async {
      KoiNetworkConstants.debugEnabled = true;

      expect(
        () => KoiTypedRequestExecutor.executeBatch<String>([
          () async =>
              _MockResult<String>(isSuccess: false, code: 500, message: 'Fail'),
        ], options: const TypedBatchRequestOptions(stopOnFirstError: true)),
        throwsA(isA<RequestLogicException<String>>()),
      );
    });

    test('executeBatch 顺序失败时 debugEnabled=true 输出日志 (line 261)', () async {
      KoiNetworkConstants.debugEnabled = true;

      expect(
        () => KoiTypedRequestExecutor.executeBatch<String>(
          [
            () async => _MockResult<String>(
              isSuccess: false,
              code: 500,
              message: 'Fail',
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

    test('_executeSingleInBatch 异常不中断时 debugEnabled=true (line 294)', () async {
      KoiNetworkConstants.debugEnabled = true;

      final results = await KoiTypedRequestExecutor.executeBatch<String>([
        () async => throw Exception('oops'),
        () async => _MockResult<String>(isSuccess: true, code: 200, data: 'ok'),
      ]);

      expect(results, [null, 'ok']);
    });

    test(
      'executeWithRetry debugEnabled=true 输出重试日志 (lines 317-318, 343-344)',
      () async {
        KoiNetworkConstants.debugEnabled = true;
        var attempt = 0;

        final result = await KoiTypedRequestExecutor.executeWithRetry<String>(
          request: () async {
            attempt++;
            if (attempt < 2) {
              throw Exception('retry');
            }
            return _MockResult<String>(isSuccess: true, code: 200, data: 'ok');
          },
          maxRetries: 2,
          delay: Duration.zero,
        );

        expect(result, 'ok');
      },
    );

    test(
      'executeWithRetry debugEnabled=true 全部失败输出最终失败日志 (lines 335-336)',
      () async {
        KoiNetworkConstants.debugEnabled = true;

        expect(
          () => KoiTypedRequestExecutor.executeWithRetry<String>(
            request: () async => _MockResult<String>(
              isSuccess: false,
              code: 500,
              message: 'always-fail',
            ),
            maxRetries: 1,
            delay: Duration.zero,
            options: const RequestExecutionOptions<String>(needRethrow: true),
          ),
          throwsA(isA<RequestLogicException<String>>()),
        );
      },
    );

    test('executeWithRetry delay > 0 时等待后重试 (line 350)', () async {
      var attempt = 0;

      final result = await KoiTypedRequestExecutor.executeWithRetry<String>(
        request: () async {
          attempt++;
          if (attempt < 2) {
            throw Exception('retry');
          }
          return _MockResult<String>(
            isSuccess: true,
            code: 200,
            data: 'delayed-ok',
          );
        },
        maxRetries: 2,
        delay: const Duration(milliseconds: 10),
      );

      expect(result, 'delayed-ok');
    });

    test('executeBatch 顺序执行异常 catch 分支 (line 243)', () async {
      // 顺序执行 + stopOnFirstError=false + 请求抛出非 RequestLogicException
      final results = await KoiTypedRequestExecutor.executeBatch<String>([
        () async => throw Exception('unexpected'),
        () async =>
            _MockResult<String>(isSuccess: true, code: 200, data: 'second-ok'),
      ], options: const TypedBatchRequestOptions(concurrent: false));

      expect(results, [null, 'second-ok']);
    });
  });

  // =====================================================
  // KoiNetworkRequestMixin - typed 方法覆盖
  // =====================================================
  group('KoiNetworkRequestMixin typed 方法', () {
    late _TestController controller;

    setUp(() => controller = _TestController());

    test(
      'typedRequest 转发至 KoiTypedRequestExecutor.execute (line 149-164)',
      () async {
        final result = await controller.typedRequest<String>(
          request: () async => _MockResult<String>(
            isSuccess: true,
            code: 200,
            data: 'typed-value',
          ),
        );

        expect(result, 'typed-value');
      },
    );

    test('typedSilentRequest 转发至 executeSilent (line 180-187)', () async {
      final result = await controller.typedSilentRequest<String>(
        request: () async => _MockResult<String>(
          isSuccess: true,
          code: 200,
          data: 'silent-value',
        ),
      );

      expect(result, 'silent-value');
    });

    test('typedQuickRequest 转发至 executeQuick (line 197-206)', () async {
      final result = await controller.typedQuickRequest<String>(
        request: () async => _MockResult<String>(
          isSuccess: true,
          code: 200,
          data: 'quick-value',
        ),
      );

      expect(result, 'quick-value');
    });
  });

  // =====================================================
  // NetworkRequestUtils - typed 静态方法覆盖
  // =====================================================
  group('NetworkRequestUtils typed 静态方法', () {
    test('typedRequest 静态方法 (line 284-297)', () async {
      final result = await NetworkRequestUtils.typedRequest<String>(
        request: () async => _MockResult<String>(
          isSuccess: true,
          code: 200,
          data: 'static-typed',
        ),
      );

      expect(result, 'static-typed');
    });

    test('typedSilentRequest 静态方法 (line 311-317)', () async {
      final result = await NetworkRequestUtils.typedSilentRequest<String>(
        request: () async => _MockResult<String>(
          isSuccess: true,
          code: 200,
          data: 'static-silent',
        ),
      );

      expect(result, 'static-silent');
    });
  });
}
