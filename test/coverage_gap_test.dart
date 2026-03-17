// 覆盖率补全测试
// 目标：覆盖所有之前未覆盖的分支和代码路径
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/interceptors/error_handling_interceptor.dart';
import 'package:koi_network/src/interceptors/token_refresh_interceptor.dart';
import 'package:koi_network/src/mixins/network_request_mixin.dart';
import 'package:koi_network/src/utils/jwt_decoder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ── Mock 类 ──
class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

class MockErrorHandlerAdapter extends Mock implements KoiErrorHandlerAdapter {}

class MockLoadingAdapter extends Mock implements KoiLoadingAdapter {}

class MockLoggerAdapter extends Mock implements KoiLoggerAdapter {}

class MockPlatformAdapter extends Mock implements KoiPlatformAdapter {}

class MockResponseParser extends Mock implements KoiResponseParser {}

class MockRequestEncoder extends Mock implements KoiRequestEncoder {}

class FakeRequestOptions extends Fake implements RequestOptions {}

// ── Fake handlers ──
class _FakeErrorHandler extends Fake implements ErrorInterceptorHandler {
  _FakeErrorHandler({this.onNext, this.onResolve, this.onReject});

  final void Function(DioException)? onNext;
  final void Function(Response<dynamic>)? onResolve;
  final void Function(DioException)? onReject;

  @override
  void next(DioException err) => onNext?.call(err);

  @override
  void resolve(Response<dynamic> response) => onResolve?.call(response);

  @override
  void reject(DioException err) => onReject?.call(err);
}

class _FakeRequestHandler extends Fake implements RequestInterceptorHandler {
  _FakeRequestHandler({this.onNext, this.onResolve, this.onReject});

  final void Function(RequestOptions)? onNext;
  final void Function(Response<dynamic>)? onResolve;
  final void Function(DioException)? onReject;

  @override
  void next(RequestOptions options) => onNext?.call(options);

  @override
  void resolve(
    Response<dynamic> response, [
    bool callFollowingResponseInterceptor = false,
  ]) => onResolve?.call(response);

  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) =>
      onReject?.call(err);
}

// ── 辅助函数 ──
void _registerAdapters({
  MockAuthAdapter? auth,
  MockErrorHandlerAdapter? errorHandler,
  MockLoadingAdapter? loading,
  MockLoggerAdapter? logger,
  MockPlatformAdapter? platform,
  MockResponseParser? responseParser,
  MockRequestEncoder? requestEncoder,
}) {
  final a = auth ?? MockAuthAdapter();
  final e = errorHandler ?? MockErrorHandlerAdapter();
  final lo = loading ?? MockLoadingAdapter();
  final lg = logger ?? MockLoggerAdapter();
  final p = platform ?? MockPlatformAdapter();

  KoiNetworkAdapters.register(
    authAdapter: a,
    errorHandlerAdapter: e,
    loadingAdapter: lo,
    loggerAdapter: lg,
    platformAdapter: p,
    responseParser: responseParser,
    requestEncoder: requestEncoder,
  );

  // 设置通用 stub
  when(() => lg.debug(any(), any(), any())).thenReturn(null);
  when(() => lg.info(any(), any(), any())).thenReturn(null);
  when(() => lg.warning(any(), any(), any())).thenReturn(null);
  when(() => lg.error(any(), any(), any())).thenReturn(null);
  when(() => lg.fatal(any(), any(), any())).thenReturn(null);

  when(() => p.platform).thenReturn('test');
  when(() => p.platformDisplayName).thenReturn('Test');
  when(() => p.appVersion).thenReturn('1.0.0');
  when(() => p.userAgent).thenReturn('Test/1.0.0');
  when(() => p.isMobile).thenReturn(false);
  when(() => p.isDesktop).thenReturn(true);
  when(() => p.isWeb).thenReturn(false);
  when(() => p.getPlatformConfig()).thenReturn({'platform': 'test'});
}

/// JWT 辅助函数
String _makeJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(json.encode(payload)));
  return '$header.$body.signature';
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/')),
    );
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '/')),
    );
  });

  tearDown(() {
    KoiNetworkConstants.debugEnabled = false;
    KoiNetworkAdapters.clear();
    KoiDioFactory.disposeAll();
  });

  // ═══════════════════════════════════════════════════════════════════
  // RequestExecutionOptions
  // ═══════════════════════════════════════════════════════════════════
  group('RequestExecutionOptions', () {
    test('silent factory', () {
      final opts = RequestExecutionOptions<String>.silent();
      expect(opts.showLoading, false);
      expect(opts.showError, false);
    });

    test('quick factory', () {
      final opts = RequestExecutionOptions<String>.quick();
      expect(opts.showLoading, false);
      expect(opts.showError, true);
    });

    test('copyWith 替换所有字段', () {
      var successCalled = false;
      var errorCalled = false;
      var finallyCalled = false;

      final original = RequestExecutionOptions<String>(
        onSuccess: (_) => successCalled = true,
        onError: (_, __) => errorCalled = true,
        onFinally: () => finallyCalled = true,
        needRethrow: false,
        showLoading: true,
        showError: true,
        loadingText: 'Loading',
        dataNotNull: true,
      );

      final copied = original.copyWith(
        needRethrow: true,
        showLoading: false,
        showError: false,
        loadingText: 'Processing',
        dataNotNull: false,
      );

      expect(copied.needRethrow, true);
      expect(copied.showLoading, false);
      expect(copied.showError, false);
      expect(copied.loadingText, 'Processing');
      expect(copied.dataNotNull, false);

      copied.onSuccess?.call('test');
      expect(successCalled, true);
      copied.onError?.call(Exception('x'), 'x');
      expect(errorCalled, true);
      copied.onFinally?.call();
      expect(finallyCalled, true);
    });

    test('copyWith 不传参数时保持原值', () {
      final original = RequestExecutionOptions<int>(
        needRethrow: true,
        showLoading: false,
        showError: false,
        loadingText: 'Wait',
        dataNotNull: false,
      );
      final copied = original.copyWith();
      expect(copied.needRethrow, true);
      expect(copied.showLoading, false);
      expect(copied.showError, false);
      expect(copied.loadingText, 'Wait');
      expect(copied.dataNotNull, false);
    });

    test('copyWith 替换回调和检查函数', () {
      final original = RequestExecutionOptions<String>();
      final copied = original.copyWith(
        onSuccess: (_) {},
        onError: (_, __) {},
        onFinally: () {},
        successCheck: (data) => data != null,
        dataCheck: (data) => data != null && data.isNotEmpty,
      );
      expect(copied.successCheck?.call('test'), true);
      expect(copied.dataCheck?.call('hello'), true);
      expect(copied.dataCheck?.call(''), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiNetworkConfig
  // ═══════════════════════════════════════════════════════════════════
  group('KoiNetworkConfig', () {
    test('isProduction / isDevelopment / isTesting', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      expect(config.environment, 'development');
      expect(config.isProduction, false);
      expect(config.isDevelopment, true);
      expect(config.isTesting, false);
    });

    test('summary 返回配置摘要', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      final summary = config.summary;
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary['baseUrl'], 'https://test.com');
      expect(summary.containsKey('environment'), true);
    });

    test('warnings 在超长超时时返回警告', () {
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://test.com',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        maxRetries: 10,
        maxCacheSize: 200 * 1024 * 1024,
      );
      final warnings = config.warnings;
      expect(warnings.length, greaterThanOrEqualTo(4));
      expect(warnings.any((w) => w.contains('Connection timeout')), true);
      expect(warnings.any((w) => w.contains('Receive timeout')), true);
      expect(warnings.any((w) => w.contains('Too many retries')), true);
      expect(warnings.any((w) => w.contains('Cache size too large')), true);
    });

    test('warnings 默认正常配置返回空或少量', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      expect(config.warnings.length, lessThanOrEqualTo(1));
    });

    test('printSummary 不抛异常', () {
      _registerAdapters();
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      expect(() => config.printSummary(), returnsNormally);
    });

    test('copyWith 复制全部字段', () {
      final original = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      final copied = original.copyWith(
        baseUrl: 'https://new.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 20),
        enableLogging: true,
        enableRetry: false,
        maxRetries: 5,
        retryDelay: const Duration(seconds: 2),
        validateCertificate: true,
        maxConnectionsPerHost: 8,
        customHeaders: {'X-Custom': 'test'},
        enableCache: true,
        maxCacheSize: 20 * 1024 * 1024,
        enableProactiveTokenRefresh: false,
        tokenRefreshThreshold: const Duration(minutes: 10),
        tokenRefreshWhiteList: ['login'],
      );

      expect(copied.baseUrl, 'https://new.com');
      expect(copied.connectTimeout, const Duration(seconds: 30));
      expect(copied.receiveTimeout, const Duration(seconds: 60));
      expect(copied.sendTimeout, const Duration(seconds: 20));
      expect(copied.enableLogging, true);
      expect(copied.enableRetry, false);
      expect(copied.maxRetries, 5);
      expect(copied.retryDelay, const Duration(seconds: 2));
      expect(copied.validateCertificate, true);
      expect(copied.maxConnectionsPerHost, 8);
      expect(copied.customHeaders, {'X-Custom': 'test'});
      expect(copied.enableCache, true);
      expect(copied.maxCacheSize, 20 * 1024 * 1024);
      expect(copied.enableProactiveTokenRefresh, false);
      expect(copied.tokenRefreshThreshold, const Duration(minutes: 10));
      expect(copied.tokenRefreshWhiteList, ['login']);
    });

    test('toString', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      expect(config.toString(), contains('KoiNetworkConfig'));
    });

    test('operator == 和 hashCode', () {
      final a = KoiNetworkConfig.create(baseUrl: 'https://a.com');
      final b = KoiNetworkConfig.create(baseUrl: 'https://a.com');
      final c = KoiNetworkConfig.create(baseUrl: 'https://c.com');
      expect(a == b, true);
      expect(a.hashCode == b.hashCode, true);
      expect(a == c, false);
      expect(a == a, true); // identical
      expect(a == Object(), false); // 不同类型
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiDefaultLoadingAdapter
  // ═══════════════════════════════════════════════════════════════════
  group('KoiDefaultLoadingAdapter', () {
    test('showProgress / hideProgress / isLoading', () {
      final adapter = KoiDefaultLoadingAdapter();
      expect(adapter.isLoading(), false);
      adapter.showLoading(message: 'test');
      expect(adapter.isLoading(), true);
      adapter.hideLoading();
      expect(adapter.isLoading(), false);
      expect(() => adapter.showProgress(progress: 0.5), returnsNormally);
      expect(() => adapter.hideProgress(), returnsNormally);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiDefaultErrorHandlerAdapter
  // ═══════════════════════════════════════════════════════════════════
  group('KoiDefaultErrorHandlerAdapter', () {
    late KoiDefaultErrorHandlerAdapter adapter;
    setUp(() => adapter = KoiDefaultErrorHandlerAdapter());

    test('showSuccess / showWarning / showInfo', () {
      expect(() => adapter.showSuccess('OK'), returnsNormally);
      expect(() => adapter.showWarning('Warn'), returnsNormally);
      expect(() => adapter.showInfo('Info'), returnsNormally);
    });

    test('handleAuthError 返回 false', () async {
      final result = await adapter.handleAuthError(
        statusCode: 401,
        message: 'Unauthorized',
      );
      expect(result, false);
    });

    test('formatErrorMessage 各种 DioExceptionType', () {
      final types = {
        DioExceptionType.connectionTimeout: 'Connection timeout',
        DioExceptionType.sendTimeout: 'Send timeout',
        DioExceptionType.receiveTimeout: 'Receive timeout',
        DioExceptionType.badResponse: 'Server error',
        DioExceptionType.cancel: 'Request cancelled',
        DioExceptionType.connectionError: 'Connection failed',
        DioExceptionType.unknown: 'Unknown error',
        DioExceptionType.badCertificate: 'Network request failed',
      };

      for (final entry in types.entries) {
        final err = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: entry.key,
          response: entry.key == DioExceptionType.badResponse
              ? Response(
                  statusCode: 500,
                  requestOptions: RequestOptions(path: '/test'),
                )
              : null,
        );
        expect(
          adapter.formatErrorMessage(err),
          contains(entry.value),
          reason: 'Failed for ${entry.key}',
        );
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiDefaultAuthAdapter
  // ═══════════════════════════════════════════════════════════════════
  group('KoiDefaultAuthAdapter', () {
    test('完整生命周期', () async {
      final adapter = KoiDefaultAuthAdapter();
      expect(adapter.isLoggedIn(), false);
      expect(adapter.getUserId(), null);
      expect(adapter.getUsername(), null);
      expect(adapter.getRefreshToken(), null);

      await adapter.saveToken('test_token');
      expect(adapter.isLoggedIn(), true);
      expect(adapter.getToken(), 'test_token');

      await adapter.saveRefreshToken('refresh_token');
      expect(adapter.getRefreshToken(), 'refresh_token');

      await adapter.clearToken();
      expect(adapter.isLoggedIn(), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiDefaultPlatformAdapter
  // ═══════════════════════════════════════════════════════════════════
  group('KoiDefaultPlatformAdapter', () {
    test('属性可访问', () {
      final adapter = KoiDefaultPlatformAdapter();
      expect(adapter.platform, isNotEmpty);
      expect(adapter.platformDisplayName, isNotEmpty);
      expect(adapter.appVersion, '1.0.0');
      expect(adapter.userAgent, contains('KoiApp'));
      expect(adapter.isWeb, false);
      expect(adapter.isMobile || adapter.isDesktop, true);
      final config = adapter.getPlatformConfig();
      expect(config, isA<Map<String, dynamic>>());
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiDefaultLoggerAdapter
  // ═══════════════════════════════════════════════════════════════════
  group('KoiDefaultLoggerAdapter', () {
    test('fatal 方法带 error 和 stackTrace', () {
      final adapter = KoiDefaultLoggerAdapter();
      expect(
        () =>
            adapter.fatal('Fatal error', Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiJwtDecoder 补充
  // ═══════════════════════════════════════════════════════════════════
  group('KoiJwtDecoder 补充', () {
    test('getIssuedAt 解析字符串 iat', () {
      final iat = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final token = _makeJwt({'iat': iat.toString()});
      expect(KoiJwtDecoder.getIssuedAt(token), isNotNull);
    });

    test('getIssuedAt 不可解析字符串返回 null', () {
      final token = _makeJwt({'iat': 'not-a-number'});
      expect(KoiJwtDecoder.getIssuedAt(token), isNull);
    });

    test('getExpiration 解析字符串 exp', () {
      final exp =
          (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 3600;
      final token = _makeJwt({'exp': exp.toString()});
      final result = KoiJwtDecoder.getExpiration(token);
      expect(result, isNotNull);
      expect(result!.isAfter(DateTime.now().toUtc()), true);
    });

    test('getExpiration 不可解析字符串返回 null', () {
      final token = _makeJwt({'exp': 'bad'});
      expect(KoiJwtDecoder.getExpiration(token), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiErrorHandlingInterceptor
  // ═══════════════════════════════════════════════════════════════════
  group('KoiErrorHandlingInterceptor', () {
    late KoiErrorHandlingInterceptor interceptor;
    late MockLoggerAdapter mockLogger;
    late MockErrorHandlerAdapter mockErrorHandler;
    late MockResponseParser mockParser;

    setUp(() {
      mockLogger = MockLoggerAdapter();
      mockErrorHandler = MockErrorHandlerAdapter();
      mockParser = MockResponseParser();

      KoiNetworkConstants.debugEnabled = true;

      _registerAdapters(
        logger: mockLogger,
        errorHandler: mockErrorHandler,
        responseParser: mockParser,
      );

      interceptor = KoiErrorHandlingInterceptor(KoiNetworkConfig.testing());
    });

    test('onError 非认证错误记录详情', () async {
      when(() => mockParser.isAuthError(any(), any())).thenReturn(false);

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'Timeout',
      );

      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;
      verify(
        () => mockLogger.error(any(), any(), any()),
      ).called(greaterThanOrEqualTo(1));
    });

    test('onError 认证错误使用 Map response data', () async {
      when(() => mockParser.isAuthError(any(), any())).thenReturn(true);
      when(() => mockParser.getMessage(any())).thenReturn('Auth failed');
      when(
        () => mockErrorHandler.handleAuthError(
          statusCode: any(named: 'statusCode'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => true);

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          data: <String, dynamic>{'error': 'Auth failed'},
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;

      verify(
        () => mockErrorHandler.handleAuthError(
          statusCode: 401,
          message: 'Auth failed',
        ),
      ).called(1);
    });

    test('onError 认证错误 non-Map response 使用 Dio message', () async {
      when(() => mockParser.isAuthError(any(), any())).thenReturn(true);
      when(
        () => mockErrorHandler.handleAuthError(
          statusCode: any(named: 'statusCode'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => true);

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        message: 'Custom error message',
        response: Response(
          statusCode: 401,
          data: 'Not a map',
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;

      verify(
        () => mockErrorHandler.handleAuthError(
          statusCode: 401,
          message: 'Custom error message',
        ),
      ).called(1);
    });

    test('onError 认证错误 message 为空用默认消息', () async {
      when(() => mockParser.isAuthError(any(), any())).thenReturn(true);
      when(() => mockParser.getMessage(any())).thenReturn(null);
      when(
        () => mockErrorHandler.handleAuthError(
          statusCode: any(named: 'statusCode'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => true);

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        response: Response(
          statusCode: 401,
          data: <String, dynamic>{'rs': false},
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;

      verify(
        () => mockErrorHandler.handleAuthError(
          statusCode: 401,
          message: 'Connection timeout',
        ),
      ).called(1);
    });

    test('onError _tryHandleAuthError 抛异常时优雅降级', () async {
      when(
        () => mockParser.isAuthError(any(), any()),
      ).thenThrow(Exception('boom'));

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.unknown,
      );

      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;
    });

    test('onError 带 response 记录 statusCode 和 data', () async {
      when(() => mockParser.isAuthError(any(), any())).thenReturn(false);

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          data: {'error': 'Internal Server Error'},
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiAuthInterceptor
  // ═══════════════════════════════════════════════════════════════════
  group('KoiAuthInterceptor', () {
    late KoiAuthInterceptor interceptor;
    late MockAuthAdapter mockAuth;
    late MockLoggerAdapter mockLogger;

    setUp(() {
      mockAuth = MockAuthAdapter();
      mockLogger = MockLoggerAdapter();

      KoiNetworkConstants.debugEnabled = true;

      _registerAdapters(auth: mockAuth, logger: mockLogger);
      interceptor = KoiAuthInterceptor();
    });

    test('onRequest debug 模式下记录日志', () async {
      when(() => mockAuth.getToken()).thenReturn('test_token');

      final options = RequestOptions(path: '/test');
      final completer = Completer<void>();
      final handler = _FakeRequestHandler(onNext: (_) => completer.complete());

      await interceptor.onRequest(options, handler);
      await completer.future;

      expect(options.headers['Authorization'], 'Bearer test_token');
      verify(
        () => mockLogger.info(any(), any(), any()),
      ).called(greaterThanOrEqualTo(1));
    });

    test('onRequest getToken 抛异常时优雅降级', () async {
      when(() => mockAuth.getToken()).thenThrow(Exception('No token'));

      final options = RequestOptions(path: '/test');
      final completer = Completer<void>();
      final handler = _FakeRequestHandler(onNext: (_) => completer.complete());

      await interceptor.onRequest(options, handler);
      await completer.future;

      expect(options.headers.containsKey('Authorization'), false);
    });

    test('onRequest _addCommonHeaders 抛异常时捕获并继续', () async {
      final badPlatform = MockPlatformAdapter();
      when(() => badPlatform.userAgent).thenThrow(Exception('Platform error'));
      when(() => badPlatform.appVersion).thenThrow(Exception('Platform error'));
      when(() => badPlatform.platform).thenThrow(Exception('Platform error'));
      when(
        () => badPlatform.platformDisplayName,
      ).thenThrow(Exception('Platform error'));

      KoiNetworkAdapters.register(
        authAdapter: mockAuth,
        errorHandlerAdapter: MockErrorHandlerAdapter(),
        loadingAdapter: MockLoadingAdapter(),
        loggerAdapter: mockLogger,
        platformAdapter: badPlatform,
      );

      final options = RequestOptions(path: '/test');
      final completer = Completer<void>();
      final handler = _FakeRequestHandler(onNext: (_) => completer.complete());

      await interceptor.onRequest(options, handler);
      await completer.future;
      verify(
        () => mockLogger.error(any(), any(), any()),
      ).called(greaterThanOrEqualTo(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiTokenRefreshInterceptor
  // ═══════════════════════════════════════════════════════════════════
  group('KoiTokenRefreshInterceptor', () {
    late MockAuthAdapter mockAuth;
    late MockLoggerAdapter mockLogger;
    late MockResponseParser mockParser;
    late MockErrorHandlerAdapter mockErrorHandler;
    late Dio dio;

    setUp(() {
      mockAuth = MockAuthAdapter();
      mockLogger = MockLoggerAdapter();
      mockParser = MockResponseParser();
      mockErrorHandler = MockErrorHandlerAdapter();

      _registerAdapters(
        auth: mockAuth,
        logger: mockLogger,
        errorHandler: mockErrorHandler,
        responseParser: mockParser,
      );

      dio = Dio(BaseOptions(baseUrl: 'https://test.com'));
    });

    test('onRequest 跳过白名单', () async {
      final interceptor = KoiTokenRefreshInterceptor(
        dio,
        whiteList: ['login', 'register'],
      );

      final options = RequestOptions(path: 'login');
      final completer = Completer<void>();
      final handler = _FakeRequestHandler(onNext: (_) => completer.complete());
      await interceptor.onRequest(options, handler);
      await completer.future;
    });

    test('onRequest 跳过 skip 标记', () async {
      final interceptor = KoiTokenRefreshInterceptor(dio);

      final options = RequestOptions(
        path: '/test',
        extra: {'koi_skip_token_refresh': true},
      );
      final completer = Completer<void>();
      final handler = _FakeRequestHandler(onNext: (_) => completer.complete());
      await interceptor.onRequest(options, handler);
      await completer.future;
    });

    test('onError 跳过非认证错误', () async {
      final interceptor = KoiTokenRefreshInterceptor(dio);
      when(() => mockParser.isAuthError(any(), any())).thenReturn(false);

      final err = DioException(requestOptions: RequestOptions(path: '/test'));
      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;
    });

    test('onError 跳过 skip 标记', () async {
      final interceptor = KoiTokenRefreshInterceptor(dio);

      final err = DioException(
        requestOptions: RequestOptions(
          path: '/test',
          extra: {'koi_skip_token_refresh': true},
        ),
      );
      final completer = Completer<void>();
      final handler = _FakeErrorHandler(onNext: (_) => completer.complete());
      await interceptor.onError(err, handler);
      await completer.future;
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // KoiRequestExecutor 补充
  // ═══════════════════════════════════════════════════════════════════
  group('KoiRequestExecutor 补充', () {
    late MockLoggerAdapter mockLogger;
    late MockLoadingAdapter mockLoading;
    late MockErrorHandlerAdapter mockErrorHandler;
    late MockResponseParser mockParser;

    setUp(() {
      mockLogger = MockLoggerAdapter();
      mockLoading = MockLoadingAdapter();
      mockErrorHandler = MockErrorHandlerAdapter();
      mockParser = MockResponseParser();

      KoiNetworkConstants.debugEnabled = true;

      _registerAdapters(
        logger: mockLogger,
        loading: mockLoading,
        errorHandler: mockErrorHandler,
        responseParser: mockParser,
      );

      when(() => mockParser.isSuccess(any())).thenReturn(true);
      when(() => mockParser.isAuthError(any(), any())).thenReturn(false);
      when(() => mockParser.getData(any())).thenReturn('data');
      when(() => mockParser.getMessage(any())).thenReturn(null);
      when(() => mockParser.getCode(any())).thenReturn(200);
      when(
        () => mockErrorHandler.formatErrorMessage(any()),
      ).thenReturn('error');
      when(() => mockErrorHandler.showError(any())).thenReturn(null);
    });

    test('execute 失败时调用 onError', () async {
      when(() => mockParser.isSuccess(any())).thenReturn(false);
      when(() => mockParser.getMessage(any())).thenReturn('Business error');
      when(() => mockParser.getCode(any())).thenReturn(400);

      var errorCalled = false;
      var finallyCalled = false;

      final result = await KoiRequestExecutor.execute<String>(
        request: () async => Response(
          requestOptions: RequestOptions(path: '/test'),
          data: <String, dynamic>{'rs': false, 'error': 'Business error'},
          statusCode: 200,
        ),
        options: RequestExecutionOptions<String>(
          showLoading: false,
          showError: true,
          onError: (e, msg) => errorCalled = true,
          onFinally: () => finallyCalled = true,
        ),
      );

      expect(result, isNull);
      expect(errorCalled, true);
      expect(finallyCalled, true);
    });

    test('executeBatch 带 showLoading', () async {
      final results = await KoiRequestExecutor.executeBatch<String>(
        [
          () async => Response(
            requestOptions: RequestOptions(path: '/test1'),
            data: <String, dynamic>{'rs': true, 'data': 'r1'},
            statusCode: 200,
          ),
        ],
        options: const BatchRequestOptions(
          showLoading: true,
          loadingText: 'Batch...',
        ),
      );

      expect(results.length, 1);
      verify(() => mockLoading.showLoading(message: 'Batch...')).called(1);
      verify(() => mockLoading.hideLoading()).called(1);
    });

    test('executeBatch stopOnFirstError 顺序执行时抛出', () async {
      when(() => mockParser.isSuccess(any())).thenReturn(false);
      when(() => mockParser.getMessage(any())).thenReturn('Fail');
      when(() => mockParser.getCode(any())).thenReturn(500);

      expect(
        () => KoiRequestExecutor.executeBatch<String>(
          [
            () async => Response(
              requestOptions: RequestOptions(path: '/test'),
              data: <String, dynamic>{'rs': false},
              statusCode: 200,
            ),
          ],
          options: const BatchRequestOptions(
            concurrent: false,
            stopOnFirstError: true,
            showLoading: true,
          ),
        ),
        throwsA(isA<RequestLogicException>()),
      );
    });

    test('executeBatch 非 Map 响应成功 statusCode', () async {
      final results = await KoiRequestExecutor.executeBatch<String>([
        () async => Response(
          requestOptions: RequestOptions(path: '/test'),
          data: 'plain text',
          statusCode: 200,
        ),
      ]);

      expect(results.length, 1);
      expect(results[0], 'plain text');
    });

    test('executeBatch 非 Map 响应失败 statusCode', () async {
      final results = await KoiRequestExecutor.executeBatch<String>([
        () async => Response(
          requestOptions: RequestOptions(path: '/test'),
          data: 'error',
          statusCode: 500,
        ),
      ]);

      expect(results.length, 1);
      expect(results[0], isNull);
    });

    test('executeWithRetry 最终失败', () async {
      expect(
        () async => KoiRequestExecutor.executeWithRetry<String>(
          request: () async {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              type: DioExceptionType.connectionTimeout,
            );
          },
          maxRetries: 1,
          delay: Duration.zero,
          options: RequestExecutionOptions<String>(
            showLoading: false,
            showError: false,
            needRethrow: true,
          ),
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('executeWithRetry 中间成功', () async {
      var attempts = 0;

      final result = await KoiRequestExecutor.executeWithRetry<String>(
        request: () async {
          attempts++;
          if (attempts < 2) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              type: DioExceptionType.connectionTimeout,
            );
          }
          return Response(
            requestOptions: RequestOptions(path: '/test'),
            data: <String, dynamic>{'rs': true, 'data': 'success'},
            statusCode: 200,
          );
        },
        maxRetries: 3,
        delay: Duration.zero,
        options: RequestExecutionOptions<String>(
          showLoading: true,
          showError: true,
          needRethrow: true,
        ),
      );

      expect(result, 'data');
      expect(attempts, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // DioFactory 补充
  // ═══════════════════════════════════════════════════════════════════
  group('DioFactory 补充', () {
    setUp(() => _registerAdapters());

    test('createMainDio 带 cache 和 logging', () {
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://test.com',
        enableCache: true,
        enableLogging: true,
      );
      final dio = KoiDioFactory.createMainDio(config);
      expect(dio, isNotNull);
      expect(dio.interceptors.length, greaterThan(3));
    });

    test('createTokenDio', () {
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://test.com',
        enableLogging: true,
      );
      final dio = KoiDioFactory.createTokenDio(config);
      expect(dio, isNotNull);
    });

    test('recreateInstance token key 和 其他 key', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');

      KoiDioFactory.createMainDio(config);
      final recreatedMain = KoiDioFactory.recreateInstance('main', config);
      expect(recreatedMain, isNotNull);

      KoiDioFactory.createTokenDio(config);
      final recreatedToken = KoiDioFactory.recreateInstance('token', config);
      expect(recreatedToken, isNotNull);
    });

    test('printFactoryInfo', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      KoiDioFactory.createMainDio(config);
      expect(() => KoiDioFactory.printFactoryInfo(), returnsNormally);
    });

    test('disposeInstance', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      KoiDioFactory.createCustomDio('test_instance', config);
      expect(KoiDioFactory.hasInstance('test_instance'), true);
      KoiDioFactory.disposeInstance('test_instance');
      expect(KoiDioFactory.hasInstance('test_instance'), false);
    });

    test('getInstanceInfo 不存在', () {
      final info = KoiDioFactory.getInstanceInfo('nonexistent');
      expect(info['exists'], false);
    });

    test('getAllInstancesInfo', () {
      final config = KoiNetworkConfig.create(baseUrl: 'https://test.com');
      KoiDioFactory.createCustomDio('a', config);
      KoiDioFactory.createCustomDio('b', config);
      final info = KoiDioFactory.getAllInstancesInfo();
      expect(info.containsKey('a'), true);
      expect(info.containsKey('b'), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // NetworkRequestUtils (mixin helper)
  // ═══════════════════════════════════════════════════════════════════
  group('NetworkRequestUtils', () {
    setUp(() {
      final mockParser = MockResponseParser();
      when(() => mockParser.isSuccess(any())).thenReturn(true);
      when(() => mockParser.isAuthError(any(), any())).thenReturn(false);
      when(() => mockParser.getData(any())).thenReturn('data');
      when(() => mockParser.getMessage(any())).thenReturn(null);
      when(() => mockParser.getCode(any())).thenReturn(200);
      _registerAdapters(responseParser: mockParser);
    });

    test('universalRequest', () async {
      final result = await NetworkRequestUtils.universalRequest<String>(
        request: () async => Response(
          requestOptions: RequestOptions(path: '/test'),
          data: <String, dynamic>{'rs': true, 'data': 'ok'},
          statusCode: 200,
        ),
        showLoading: false,
      );
      expect(result, 'data');
    });

    test('silentRequest', () async {
      final result = await NetworkRequestUtils.silentRequest<String>(
        request: () async => Response(
          requestOptions: RequestOptions(path: '/test'),
          data: <String, dynamic>{'rs': true, 'data': 'ok'},
          statusCode: 200,
        ),
      );
      expect(result, 'data');
    });

    test('quickRequest', () async {
      final result = await NetworkRequestUtils.quickRequest<String>(
        request: () async => Response(
          requestOptions: RequestOptions(path: '/test'),
          data: <String, dynamic>{'rs': true, 'data': 'ok'},
          statusCode: 200,
        ),
      );
      expect(result, 'data');
    });
  });
}
