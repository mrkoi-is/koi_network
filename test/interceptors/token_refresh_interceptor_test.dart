import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:koi_network/src/adapters/auth_adapter.dart';
import 'package:koi_network/src/adapters/error_handler_adapter.dart';
import 'package:koi_network/src/adapters/loading_adapter.dart';
import 'package:koi_network/src/adapters/logger_adapter.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart';
import 'package:koi_network/src/interceptors/token_refresh_interceptor.dart';

// Mock 类
class MockDio extends Mock implements Dio {}

class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

class MockAuthAdapterWithJwt extends Mock
    implements KoiAuthAdapter, KoiJwtTokenMixin {}

class MockErrorHandlerAdapter extends Mock implements KoiErrorHandlerAdapter {}

class MockLoggerAdapter extends Mock implements KoiLoggerAdapter {}

class MockLoadingAdapter extends Mock implements KoiLoadingAdapter {}

class MockPlatformAdapter extends Mock implements KoiPlatformAdapter {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

// Fake 类（用于 when 参数匹配）
class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

class FakeResponse extends Fake implements Response<dynamic> {}

void main() {
  setUpAll(() {
    // 注册 Fake 类
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(const Duration(minutes: 5)); // 注册 Duration fallback
  });

  group('KoiTokenRefreshInterceptor', () {
    late MockDio mockDio;
    late MockAuthAdapterWithJwt mockAuthAdapter;
    late MockErrorHandlerAdapter mockErrorHandler;
    late MockLoggerAdapter mockLogger;
    late MockLoadingAdapter mockLoading;
    late MockPlatformAdapter mockPlatform;
    late KoiTokenRefreshInterceptor interceptor;

    setUp(() {
      mockDio = MockDio();
      mockAuthAdapter = MockAuthAdapterWithJwt();
      mockErrorHandler = MockErrorHandlerAdapter();
      mockLogger = MockLoggerAdapter();
      mockLoading = MockLoadingAdapter();
      mockPlatform = MockPlatformAdapter();

      // 注册全局适配器
      KoiNetworkAdapters.register(
        authAdapter: mockAuthAdapter,
        errorHandlerAdapter: mockErrorHandler,
        loadingAdapter: mockLoading,
        platformAdapter: mockPlatform,
        loggerAdapter: mockLogger,
      );

      // 创建拦截器
      interceptor = KoiTokenRefreshInterceptor(mockDio);

      // 默认 mock 行为 - logger 方法有可选参数
      when(() => mockLogger.debug(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.info(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.warning(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.error(any(), any(), any())).thenReturn(null);
    });

    tearDown(() {
      // 清除适配器（在下一个微任务中执行，避免与 verify 冲突）
      Future.microtask(KoiNetworkAdapters.clear);
    });

    group('主动刷新（onRequest）', () {
      test('当 Token 软过期时应触发主动刷新并重试请求', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(
          () => mockAuthAdapter.isTokenExpiringSoon(
            threshold: any(named: "threshold"),
          ),
        ).thenReturn(true);
        when(() => mockAuthAdapter.refresh()).thenAnswer((_) async => true);
        when(() => mockAuthAdapter.getToken()).thenReturn('new_token');
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: 验证刷新被调用，并且请求最终被传递下去（通过队列）
        verify(
          () => mockAuthAdapter.isTokenExpiringSoon(
            threshold: any(named: "threshold"),
          ),
        ).called(1);
        verify(() => mockAuthAdapter.refresh()).called(1);
        verify(
          () => handler.next(
            any(
              that: isA<RequestOptions>().having(
                (o) => o.headers['Authorization'],
                'Authorization header',
                'Bearer new_token',
              ),
            ),
          ),
        ).called(1);
      });

      test('当 Token 未软过期时不应触发主动刷新', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(
          () => mockAuthAdapter.isTokenExpiringSoon(
            threshold: any(named: "threshold"),
          ),
        ).thenReturn(false);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verify(
          () => mockAuthAdapter.isTokenExpiringSoon(
            threshold: any(named: "threshold"),
          ),
        ).called(1);
        verifyNever(() => mockAuthAdapter.refresh());
        verify(() => handler.next(options)).called(1);
      });

      test('禁用主动刷新时不应检查 Token', () async {
        // Arrange
        final interceptorWithoutProactive = KoiTokenRefreshInterceptor(
          mockDio,
          enableProactiveRefresh: false,
        );
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptorWithoutProactive.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verifyNever(
          () => mockAuthAdapter.isTokenExpiringSoon(
            threshold: any(named: "threshold"),
          ),
        );
        verifyNever(() => mockAuthAdapter.refresh());
        verify(() => handler.next(options)).called(1);
      });
    });

    group('被动刷新（onError）', () {
      test('收到401且Token未硬过期时应触发刷新', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('old_token');
        when(() => mockAuthAdapter.isTokenExpired()).thenReturn(false);
        when(() => mockAuthAdapter.refresh()).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(requestOptions: options, statusCode: 200),
        );
        when(() => handler.resolve(any())).thenReturn(null);

        // Act
        interceptor.onError(error, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockAuthAdapter.isTokenExpired()).called(1);
        verify(() => mockAuthAdapter.refresh()).called(1);
        verify(() => mockDio.fetch<dynamic>(any())).called(1);
        verify(() => handler.resolve(any())).called(1);
      });

      test('收到401且Token已硬过期时，不应刷新并应登出', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('hard_expired_token');
        when(() => mockAuthAdapter.isTokenExpired()).thenReturn(true);
        when(
          () => mockErrorHandler.handleAuthError(
            statusCode: any(named: 'statusCode'),
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async => true);
        when(() => handler.reject(any())).thenReturn(null);

        // Act
        interceptor.onError(error, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockAuthAdapter.isTokenExpired()).called(1);
        verifyNever(() => mockAuthAdapter.refresh());
        verify(
          () => mockErrorHandler.handleAuthError(
            statusCode: 401,
            message: 'Session expired, please log in again',
          ),
        ).called(1);
        verify(() => handler.reject(error)).called(1);
      });

      test('收到其他错误码时不应触发刷新', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 500),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onError(error, handler);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verifyNever(() => mockAuthAdapter.refresh());
        verify(() => handler.next(error)).called(1);
      });

      test('流/表单请求体收到401时应跳过自动重试', () async {
        // Arrange
        final options = RequestOptions(
          path: '/api/upload',
          data: FormData.fromMap({'file': MultipartFile.fromString('demo')}),
        );
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );
        final handler = MockErrorInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('old_token');
        when(() => mockAuthAdapter.isTokenExpired()).thenReturn(false);
        when(() => mockAuthAdapter.refresh()).thenAnswer((_) async => true);
        when(() => handler.reject(any())).thenReturn(null);

        // Act
        await interceptor.onError(error, handler);

        // Assert
        verify(() => mockAuthAdapter.refresh()).called(1);
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => handler.reject(error)).called(1);
      });
    });

    group('并发刷新控制', () {
      test('并发请求应只触发一次刷新', () async {
        // Arrange
        final options1 = RequestOptions(path: '/api/test1');
        final options2 = RequestOptions(path: '/api/test2');
        final error1 = DioException(
          requestOptions: options1,
          response: Response(requestOptions: options1, statusCode: 401),
        );
        final error2 = DioException(
          requestOptions: options2,
          response: Response(requestOptions: options2, statusCode: 401),
        );
        final handler1 = MockErrorInterceptorHandler();
        final handler2 = MockErrorInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('old_token');
        when(() => mockAuthAdapter.isTokenExpired()).thenReturn(false);
        when(() => mockAuthAdapter.refresh()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        });
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(requestOptions: options1, statusCode: 200),
        );
        when(() => handler1.resolve(any())).thenReturn(null);
        when(() => handler2.resolve(any())).thenReturn(null);

        // Act
        interceptor.onError(error1, handler1);
        interceptor.onError(error2, handler2);
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        verify(() => mockAuthAdapter.refresh()).called(1);
        verify(() => handler1.resolve(any())).called(1);
        verify(() => handler2.resolve(any())).called(1);
      });
    });

    group('请求克隆与重试', () {
      test('应克隆可变数据并保留取消与回调配置', () async {
        // Arrange
        final cancelToken = CancelToken();
        void onSend(int a, int b) {}
        void onReceive(int a, int b) {}
        Future<List<int>> requestEncoder(
          String value,
          RequestOptions _,
        ) async => utf8.encode('encoded_$value');
        Future<String?> responseDecoder(
          List<int> value,
          RequestOptions _,
          ResponseBody? __,
        ) async => 'decoded_${utf8.decode(value)}';

        final options = RequestOptions(
          path: '/api/test',
          method: 'POST',
          baseUrl: 'https://example.com',
          data: <String, dynamic>{'a': 1},
          queryParameters: <String, dynamic>{'q': '1'},
          headers: <String, dynamic>{'h': '1'},
          cancelToken: cancelToken,
          onSendProgress: onSend,
          onReceiveProgress: onReceive,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
          listFormat: ListFormat.multiCompatible,
          extra: <String, dynamic>{},
          connectTimeout: const Duration(seconds: 1),
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 3),
        );
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );
        final handler = MockErrorInterceptorHandler();

        late RequestOptions retriedOptions;
        when(() => mockAuthAdapter.getToken()).thenReturn('new_token');
        when(() => mockAuthAdapter.isTokenExpired()).thenReturn(false);
        when(() => mockAuthAdapter.refresh()).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer((
          invocation,
        ) async {
          retriedOptions =
              invocation.positionalArguments.first as RequestOptions;
          return Response(requestOptions: options, statusCode: 200);
        });
        when(() => handler.resolve(any())).thenReturn(null);

        // Act
        await interceptor.onError(error, handler);

        // Assert
        expect(retriedOptions.cancelToken, same(cancelToken));
        expect(retriedOptions.onSendProgress, same(onSend));
        expect(retriedOptions.onReceiveProgress, same(onReceive));
        expect(retriedOptions.requestEncoder, same(requestEncoder));
        expect(retriedOptions.responseDecoder, same(responseDecoder));
        expect(retriedOptions.listFormat, ListFormat.multiCompatible);
        expect(retriedOptions.data, isA<Map<String, dynamic>>());
        expect(identical(retriedOptions.data, options.data), isFalse);
      });
    });
  });
}
