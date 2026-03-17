import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:koi_network/src/adapters/auth_adapter.dart';
import 'package:koi_network/src/adapters/error_handler_adapter.dart';
import 'package:koi_network/src/adapters/loading_adapter.dart';
import 'package:koi_network/src/adapters/logger_adapter.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart';
import 'package:koi_network/src/interceptors/auth_interceptor.dart';

// Mock 类
class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

class MockErrorHandlerAdapter extends Mock implements KoiErrorHandlerAdapter {}

class MockLoggerAdapter extends Mock implements KoiLoggerAdapter {}

class MockLoadingAdapter extends Mock implements KoiLoadingAdapter {}

class MockPlatformAdapter extends Mock implements KoiPlatformAdapter {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

// Fake 类
class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  group('KoiAuthInterceptor', () {
    late MockAuthAdapter mockAuthAdapter;
    late MockErrorHandlerAdapter mockErrorHandler;
    late MockLoggerAdapter mockLogger;
    late MockLoadingAdapter mockLoading;
    late MockPlatformAdapter mockPlatform;
    late KoiAuthInterceptor interceptor;

    setUp(() {
      mockAuthAdapter = MockAuthAdapter();
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

      // Mock platform 方法
      when(() => mockPlatform.platform).thenReturn('ios');
      when(() => mockPlatform.platformDisplayName).thenReturn('iOS');
      when(() => mockPlatform.userAgent).thenReturn('KoiApp/1.0.0');
      when(() => mockPlatform.appVersion).thenReturn('1.0.0');

      // Mock logger 方法
      when(() => mockLogger.debug(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.info(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.warning(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.error(any(), any(), any())).thenReturn(null);

      interceptor = KoiAuthInterceptor();
    });

    tearDown(() {
      Future.microtask(KoiNetworkAdapters.clear);
    });

    group('Token 添加', () {
      test('有 Token 时应添加到请求头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('test_token');
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers['Authorization'], 'Bearer test_token');
        verify(() => handler.next(options)).called(1);
      });

      test('Token 为空时不应添加请求头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('');
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => handler.next(options)).called(1);
      });

      test('Token 为 null 时不应添加请求头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => handler.next(options)).called(1);
      });

      test('已有 Authorization 头时应覆盖', () async {
        // Arrange
        final options = RequestOptions(
          path: '/api/test',
          headers: {'Authorization': 'Bearer old_token'},
        );
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('new_token');
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers['Authorization'], 'Bearer new_token');
        verify(() => handler.next(options)).called(1);
      });
    });

    group('通用请求头', () {
      test('应添加通用请求头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        // 注意：Accept / Content-Type 通常由 Dio BaseOptions 注入；
        // 此测试直接 new RequestOptions，故不强依赖这些 Header。
        expect(options.headers['X-Platform'], 'ios');
        expect(options.headers['X-Platform-Name'], 'iOS');
        expect(options.headers.containsKey('X-Request-ID'), isTrue);
        expect(options.headers.containsKey('X-Request-Timestamp'), isTrue);
        verify(() => handler.next(options)).called(1);
      });

      test('当已存在 Accept 时不应覆盖', () async {
        // Arrange
        final options = RequestOptions(
          path: '/api/test',
          headers: {'Accept': 'application/json'},
        );
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers['Accept'], 'application/json');
        verify(() => handler.next(options)).called(1);
      });

      test('应添加 Accept-Charset 和 Connection 头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        // Accept-Charset/Connection 不作为通用默认头强行注入（避免影响上传/代理链路）
        expect(options.headers.containsKey('Accept-Charset'), isFalse);
        expect(options.headers.containsKey('Connection'), isFalse);
        verify(() => handler.next(options)).called(1);
      });

      test('应添加 User-Agent 头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers.containsKey('User-Agent'), isTrue);
        final userAgent = options.headers['User-Agent'] as String;
        expect(userAgent, contains('KoiApp/'));
        verify(() => handler.next(options)).called(1);
      });

      test('应添加 X-App-Version 头', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers.containsKey('X-App-Version'), isTrue);
        verify(() => handler.next(options)).called(1);
      });

      test('X-Request-ID 应该是唯一的', () async {
        // Arrange
        final options1 = RequestOptions(path: '/api/test1');
        final options2 = RequestOptions(path: '/api/test2');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options1, handler);
        await Future.delayed(const Duration(milliseconds: 10));
        interceptor.onRequest(options2, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final requestId1 = options1.headers['X-Request-ID'];
        final requestId2 = options2.headers['X-Request-ID'];
        expect(requestId1, isNot(equals(requestId2)));
        expect(requestId1, startsWith('koi_'));
        expect(requestId2, startsWith('koi_'));
      });

      test('X-Request-Timestamp 应该是有效的时间戳', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();
        final beforeTimestamp = DateTime.now().millisecondsSinceEpoch;

        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        final afterTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Assert
        final timestamp = int.parse(
          options.headers['X-Request-Timestamp'] as String,
        );
        expect(timestamp, greaterThanOrEqualTo(beforeTimestamp));
        expect(timestamp, lessThanOrEqualTo(afterTimestamp));
      });
    });

    group('异常处理', () {
      test('获取 Token 失败时应继续请求', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(
          () => mockAuthAdapter.getToken(),
        ).thenThrow(Exception('Token error'));
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => handler.next(options)).called(1);
      });

      test('添加认证信息失败时应继续请求', () async {
        // Arrange
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();

        when(
          () => mockAuthAdapter.getToken(),
        ).thenThrow(Exception('Auth error'));
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => handler.next(options)).called(1);
      });
    });

    group('多次请求', () {
      test('多次请求应复用缓存信息', () async {
        // Arrange
        final options1 = RequestOptions(path: '/api/test1');
        final options2 = RequestOptions(path: '/api/test2');
        final handler = MockRequestInterceptorHandler();

        when(() => mockAuthAdapter.getToken()).thenReturn('test_token');
        when(() => handler.next(any())).thenReturn(null);

        // Act
        interceptor.onRequest(options1, handler);
        await Future.delayed(const Duration(milliseconds: 100));
        interceptor.onRequest(options2, handler);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(
          options1.headers['X-App-Version'],
          equals(options2.headers['X-App-Version']),
        );
        expect(
          options1.headers['X-Platform'],
          equals(options2.headers['X-Platform']),
        );
        expect(
          options1.headers['X-Platform-Name'],
          equals(options2.headers['X-Platform-Name']),
        );
        verify(() => handler.next(any())).called(2);
      });
    });
  });
}
