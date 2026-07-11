import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

// Mock 类
class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

class MockErrorHandlerAdapter extends Mock implements KoiErrorHandlerAdapter {}

class MockLoggerAdapter extends Mock implements KoiLoggerAdapter {}

class MockLoadingAdapter extends Mock implements KoiLoadingAdapter {}

class MockPlatformAdapter extends Mock implements KoiPlatformAdapter {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

// Fake 类
class FakeResponse extends Fake implements Response {}

class FakeDioException extends Fake implements DioException {}

void main() {
  late MockAuthAdapter mockAuthAdapter;
  late MockErrorHandlerAdapter mockErrorHandler;
  late MockErrorInterceptorHandler mockHandler;

  setUpAll(() {
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeDioException());
  });

  setUp(() {
    mockAuthAdapter = MockAuthAdapter();
    mockErrorHandler = MockErrorHandlerAdapter();
    mockHandler = MockErrorInterceptorHandler();
    when(() => mockAuthAdapter.isLoggedIn()).thenReturn(true);

    // 注册全局适配器
    KoiNetworkAdapters.register(
      authAdapter: mockAuthAdapter,
      errorHandlerAdapter: mockErrorHandler,
      loadingAdapter: MockLoadingAdapter(),
      loggerAdapter: MockLoggerAdapter(),
      platformAdapter: MockPlatformAdapter(),
    );
  });

  tearDown(KoiNetworkAdapters.clear);

  group('Error Propagation Tests', () {
    test('Should always propagate error to next handler', () {
      // Arrange
      final config = KoiNetworkConfig.create();
      final interceptor = KoiErrorHandlingInterceptor(config);

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      // Act
      interceptor.onError(dioError, mockHandler);

      // Wait for async operations
      return Future.delayed(const Duration(milliseconds: 100), () {
        // Assert - should always call handler.next()
        verify(() => mockHandler.next(dioError)).called(1);
        verifyNever(() => mockHandler.resolve(any()));
      });
    });

    test('Should propagate even for auth errors after handling', () {
      // Arrange
      final config = KoiNetworkConfig.create();
      final interceptor = KoiErrorHandlingInterceptor(config);

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );

      when(
        () => mockErrorHandler.handleAuthError(
          statusCode: any(named: 'statusCode'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => true);

      // Act
      interceptor.onError(dioError, mockHandler);

      // Wait for async operations
      return Future.delayed(const Duration(milliseconds: 100), () {
        // Assert
        verify(
          () => mockErrorHandler.handleAuthError(
            statusCode: 401,
            message: any(named: 'message'),
          ),
        ).called(1);
        verify(() => mockHandler.next(dioError)).called(1);
      });
    });

    test('Should not globally handle a 401 when not logged in', () async {
      // Arrange
      final interceptor = KoiErrorHandlingInterceptor(
        KoiNetworkConfig.create(),
      );
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/public'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/public'),
          statusCode: 401,
        ),
      );
      when(() => mockAuthAdapter.isLoggedIn()).thenReturn(false);

      // Act
      await interceptor.onError(dioError, mockHandler);

      // Assert
      verifyNever(
        () => mockErrorHandler.handleAuthError(
          statusCode: any(named: 'statusCode'),
          message: any(named: 'message'),
        ),
      );
      verify(() => mockHandler.next(dioError)).called(1);
    });

    test(
      'Should not globally handle a 401 from a configured public path',
      () async {
        // Arrange
        final interceptor = KoiErrorHandlingInterceptor(
          KoiNetworkConfig.create(tokenRefreshWhiteList: const ['/auth/login']),
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        );

        // Act
        await interceptor.onError(dioError, mockHandler);

        // Assert
        verifyNever(
          () => mockErrorHandler.handleAuthError(
            statusCode: any(named: 'statusCode'),
            message: any(named: 'message'),
          ),
        );
        verify(() => mockHandler.next(dioError)).called(1);
      },
    );
  });
}
