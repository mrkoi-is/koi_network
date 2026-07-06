/// Migration contract tests for koi_network.
///
/// These tests define behavior that koi_network must preserve for downstream
/// migrations from project-specific network integrations.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart' as koi;
import 'package:koi_network/src/adapters/auth_adapter.dart';
import 'package:koi_network/src/adapters/error_handler_adapter.dart';
import 'package:koi_network/src/adapters/loading_adapter.dart';
import 'package:koi_network/src/adapters/logger_adapter.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart';
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/interceptors/auth_interceptor.dart';
import 'package:koi_network/src/utils/jwt_decoder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ========================== Mocks ==========================

class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

class MockErrorHandlerAdapter extends Mock implements KoiErrorHandlerAdapter {}

class MockLoggerAdapter extends Mock implements KoiLoggerAdapter {}

class MockLoadingAdapter extends Mock implements KoiLoadingAdapter {}

class MockPlatformAdapter extends Mock implements KoiPlatformAdapter {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

// ========================== Fallbacks ==========================

class FakeRequestOptions extends Fake implements RequestOptions {}

// ========================== Test Data ==========================

/// JWT payload: {"expiration":"11/20/2025 10:26:19","ttdateExp":"11/20/2025 10:30:19"}
const testJwtToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0dGRhdGVFeHAiOiIxMS8yMC8yMDI1IDEwOjMwOjE5IiwiZXhwaXJhdGlvbiI6IjExLzIwLzIwMjUgMTA6MjY6MTkiLCJVc2VySWQiOiI3Mjg3MzEyODAwNjQ1ODEiLCJVc2VyTmFtZSI6Iuadjue7hOmVvyJ9.i8_jkMzF_MHsyJV6_fk0zWvFW_HxkX0CFkY_x09mKJo';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  // ==========================
  // 1. KoiJwtDecoder: Custom Claims
  // ==========================
  group('KoiJwtDecoder — Custom Claims', () {
    test('getCustomExpiration parses expiration claim with custom parser', () {
      final expiry = KoiJwtDecoder.getCustomExpiration(
        testJwtToken,
        'expiration',
        (value) => _parseOaDate(value),
      );
      expect(expiry, isNotNull);
      expect(expiry, DateTime.utc(2025, 11, 20, 10, 26, 19));
    });

    test('getCustomExpiration parses ttdateExp claim with custom parser', () {
      final expiry = KoiJwtDecoder.getCustomExpiration(
        testJwtToken,
        'ttdateExp',
        (value) => _parseOaDate(value),
      );
      expect(expiry, isNotNull);
      expect(expiry, DateTime.utc(2025, 11, 20, 10, 30, 19));
    });

    test('getCustomExpiration returns null for missing claim', () {
      final expiry = KoiJwtDecoder.getCustomExpiration(
        testJwtToken,
        'nonexistent_claim',
        (value) => _parseOaDate(value),
      );
      expect(expiry, isNull);
    });

    test('getCustomExpiration returns null for non-string claim', () {
      final token = _createTestToken({'expiration': 12345});
      final expiry = KoiJwtDecoder.getCustomExpiration(
        token,
        'expiration',
        (value) => _parseOaDate(value),
      );
      expect(expiry, isNull);
    });

    test('getCustomExpiration with empty token returns null', () {
      final expiry = KoiJwtDecoder.getCustomExpiration(
        '',
        'expiration',
        (value) => DateTime.parse(value),
      );
      expect(expiry, isNull);
    });
  });

  // ==========================
  // 2. KoiAuthInterceptor: Header Builder Support
  // ==========================
  group('KoiAuthInterceptor — Header Builders', () {
    late MockAuthAdapter mockAuthAdapter;
    late MockErrorHandlerAdapter mockErrorHandler;
    late MockLoggerAdapter mockLogger;
    late MockLoadingAdapter mockLoading;
    late MockPlatformAdapter mockPlatform;

    setUp(() {
      mockAuthAdapter = MockAuthAdapter();
      mockErrorHandler = MockErrorHandlerAdapter();
      mockLogger = MockLoggerAdapter();
      mockLoading = MockLoadingAdapter();
      mockPlatform = MockPlatformAdapter();

      KoiNetworkAdapters.register(
        authAdapter: mockAuthAdapter,
        errorHandlerAdapter: mockErrorHandler,
        loadingAdapter: mockLoading,
        platformAdapter: mockPlatform,
        loggerAdapter: mockLogger,
      );

      when(() => mockPlatform.platform).thenReturn('ios');
      when(() => mockPlatform.platformDisplayName).thenReturn('iOS');
      when(() => mockPlatform.userAgent).thenReturn('KoiApp/1.0.0');
      when(() => mockPlatform.appVersion).thenReturn('1.0.0');
      when(() => mockLogger.debug(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.info(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.warning(any(), any(), any())).thenReturn(null);
      when(() => mockLogger.error(any(), any(), any())).thenReturn(null);
    });

    tearDown(() {
      Future.microtask(KoiNetworkAdapters.clear);
    });

    test('headerBuilders should be accepted by constructor', () {
      Future<Map<String, String>> testBuilder(RequestOptions _) async => {
        'X-Test': 'value',
      };

      final interceptor = KoiAuthInterceptor(headerBuilders: [testBuilder]);
      expect(interceptor.headerBuilders.length, 1);
    });

    test('header builders should inject custom headers', () async {
      final options = RequestOptions(path: '/api/review');
      final handler = MockRequestInterceptorHandler();
      when(() => mockAuthAdapter.getToken()).thenReturn(null);
      when(() => handler.next(any())).thenReturn(null);

      Future<Map<String, String>> reviewBuilder(RequestOptions opts) async {
        return {'isReview': 'true', 'X-Path': opts.path};
      }

      final interceptor = KoiAuthInterceptor(headerBuilders: [reviewBuilder]);
      await interceptor.onRequest(options, handler);

      expect(options.headers['isReview'], 'true');
      expect(options.headers['X-Path'], '/api/review');
      verify(() => handler.next(options)).called(1);
    });

    test(
      'builder-injected Authorization should NOT be overwritten by fallback',
      () async {
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();
        when(() => mockAuthAdapter.getToken()).thenReturn('fallback_token');
        when(() => handler.next(any())).thenReturn(null);

        Future<Map<String, String>> authBuilder(RequestOptions _) async {
          return {'Authorization': 'Bearer builder_token'};
        }

        final interceptor = KoiAuthInterceptor(headerBuilders: [authBuilder]);
        await interceptor.onRequest(options, handler);

        // Builder's Authorization must be preserved, not overwritten
        expect(options.headers['Authorization'], 'Bearer builder_token');
        verify(() => handler.next(options)).called(1);
      },
    );

    test(
      'failing builder should not block other builders or the request',
      () async {
        final options = RequestOptions(path: '/api/test');
        final handler = MockRequestInterceptorHandler();
        when(() => mockAuthAdapter.getToken()).thenReturn(null);
        when(() => handler.next(any())).thenReturn(null);

        Future<Map<String, String>> failBuilder(RequestOptions _) async {
          throw Exception('Builder failure');
        }

        Future<Map<String, String>> goodBuilder(RequestOptions _) async => {
          'Good': 'yes',
        };

        final interceptor = KoiAuthInterceptor(
          headerBuilders: [failBuilder, goodBuilder],
        );
        await interceptor.onRequest(options, handler);

        expect(options.headers['Good'], 'yes');
        verify(() => handler.next(options)).called(1);
      },
    );

    test('empty headerBuilders should not break the interceptor', () async {
      final options = RequestOptions(path: '/api/test');
      final handler = MockRequestInterceptorHandler();
      when(() => mockAuthAdapter.getToken()).thenReturn('token');
      when(() => handler.next(any())).thenReturn(null);

      final interceptor = KoiAuthInterceptor();
      await interceptor.onRequest(options, handler);

      // Common headers and auth headers should still be added
      expect(options.headers['Authorization'], 'Bearer token');
      expect(options.headers.containsKey('X-Request-ID'), isTrue);
      verify(() => handler.next(options)).called(1);
    });
  });

  // ==========================
  // 3. KoiNetworkConfig: Header Builder Propagation
  // ==========================
  group('KoiNetworkConfig — Header Builders', () {
    test('create should accept and store headerBuilders', () {
      Future<Map<String, String>> testBuilder(RequestOptions _) async => {
        'X-Test': 'value',
      };

      final config = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
        headerBuilders: [testBuilder],
      );

      expect(config.headerBuilders.length, 1);
    });

    test('copyWith should preserve headerBuilders', () {
      Future<Map<String, String>> testBuilder(RequestOptions _) async => {
        'X-Test': 'value',
      };

      final original = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
        headerBuilders: [testBuilder],
      );
      final copied = original.copyWith(enableLogging: true);

      expect(copied.headerBuilders.length, 1);
    });

    test('production config should accept headerBuilders', () {
      Future<Map<String, String>> testBuilder(RequestOptions _) async => {
        'X-Test': 'value',
      };

      final config = KoiNetworkConfig.production(
        baseUrl: 'https://api.example.com',
        headerBuilders: [testBuilder],
      );

      expect(config.headerBuilders, isNotEmpty);
    });

    test('development config should accept headerBuilders', () {
      Future<Map<String, String>> testBuilder(RequestOptions _) async => {
        'X-Test': 'value',
      };

      final config = KoiNetworkConfig.development(
        baseUrl: 'https://api.example.com',
        headerBuilders: [testBuilder],
      );

      expect(config.headerBuilders, isNotEmpty);
    });
  });

  // ==========================
  // 4. Dio re-export: package:dio/dio.dart should be accessible from barrel
  // ==========================
  group('Barrel — Dio re-export', () {
    test('Dio should be importable from koi_network barrel', () {
      expect(koi.Dio, isNotNull);
    });
  });
}

// ========================== Helpers ==========================

String _createTestToken(Map<String, dynamic> payload) {
  final header = base64Url.encode(
    utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final body = base64Url.encode(utf8.encode(json.encode(payload)));
  return '$header.$body.test_signature';
}

/// Parse the OA project's custom date format: MM/dd/yyyy HH:mm:ss
DateTime _parseOaDate(String value) {
  final parts = value.split(' ');
  final dateParts = parts[0].split('/');
  final timeParts = parts[1].split(':');
  return DateTime.utc(
    int.parse(dateParts[2]), // year
    int.parse(dateParts[0]), // month
    int.parse(dateParts[1]), // day
    int.parse(timeParts[0]), // hour
    int.parse(timeParts[1]), // minute
    int.parse(timeParts[2]), // second
  );
}
