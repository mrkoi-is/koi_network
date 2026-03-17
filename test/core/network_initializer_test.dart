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

void main() {
  late MockAuthAdapter mockAuth;
  late MockErrorHandlerAdapter mockErrorHandler;
  late MockLoggerAdapter mockLogger;
  late MockLoadingAdapter mockLoading;
  late MockPlatformAdapter mockPlatform;

  setUp(() {
    mockAuth = MockAuthAdapter();
    mockErrorHandler = MockErrorHandlerAdapter();
    mockLogger = MockLoggerAdapter();
    mockLoading = MockLoadingAdapter();
    mockPlatform = MockPlatformAdapter();

    // Mock logger 方法
    when(() => mockLogger.info(any())).thenReturn(null);
    when(() => mockLogger.error(any(), any(), any())).thenReturn(null);
    when(() => mockLogger.warning(any())).thenReturn(null);

    // 注册适配器
    KoiNetworkAdapters.register(
      authAdapter: mockAuth,
      errorHandlerAdapter: mockErrorHandler,
      loadingAdapter: mockLoading,
      loggerAdapter: mockLogger,
      platformAdapter: mockPlatform,
    );
  });

  tearDown(() {
    KoiNetworkInitializer.dispose();
    KoiNetworkAdapters.clear();
    KoiDioFactory.disposeAll();
  });

  group('NetworkInitializer 初始化测试（P1 功能验证）', () {
    test('快速初始化应该成功创建网络服务', () async {
      // Act
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
      );

      // Assert
      expect(KoiNetworkInitializer.isInitialized, true);
      expect(KoiNetworkServiceManager.instance.isInitialized, true);
      expect(KoiNetworkServiceManager.instance.config, isNotNull);
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://api.example.com',
      );
    });

    test('使用自定义配置初始化应该成功', () async {
      // Arrange
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://custom.example.com',
        enableLogging: false,
        enableRetry: false,
      );

      // Act
      await KoiNetworkInitializer.initializeWithConfig(config);

      // Assert
      expect(KoiNetworkInitializer.isInitialized, true);
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://custom.example.com',
      );
      expect(KoiNetworkServiceManager.instance.config!.enableLogging, false);
      expect(KoiNetworkServiceManager.instance.config!.enableRetry, false);
    });

    test('未注册适配器时初始化应该抛出异常', () async {
      // Arrange
      KoiNetworkAdapters.clear();

      // Act & Assert
      expect(
        () => KoiNetworkInitializer.initialize(
          baseUrl: 'https://api.example.com',
        ),
        throwsException,
      );
    });

    test('不同环境应该创建对应的配置', () async {
      // Test production
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
        environment: 'production',
      );
      expect(
        KoiNetworkServiceManager.instance.config!.validateCertificate,
        false,
      );
      KoiNetworkInitializer.dispose();

      // Test testing
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
        environment: 'testing',
      );
      expect(KoiNetworkServiceManager.instance.config, isNotNull);
      KoiNetworkInitializer.dispose();

      // Test development (uses default enableLogging=false from initialize())
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
      );
      expect(KoiNetworkServiceManager.instance.config!.enableLogging, false);
    });

    test('自定义请求头应该被正确设置', () async {
      // Arrange
      final customHeaders = {
        'X-Custom-Header': 'custom-value',
        'X-App-Version': '1.0.0',
      };

      // Act
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
        customHeaders: customHeaders,
      );

      // Assert
      expect(
        KoiNetworkServiceManager.instance.config!.customHeaders,
        customHeaders,
      );
    });
  });

  group('NetworkInitializer 状态管理测试（P1 功能验证）', () {
    test('getStatus 应该返回完整的状态信息', () async {
      // Arrange
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
      );

      // Act
      final status = KoiNetworkInitializer.getStatus();

      // Assert
      expect(status['adaptersRegistered'], true);
      expect(status['serviceInitialized'], true);
      expect(status['adapterStatus'], isNotNull);
      expect(status['serviceStatus'], isNotNull);
    });

    test('未初始化时 getStatus 应该返回正确的状态', () {
      // Act
      final status = KoiNetworkInitializer.getStatus();

      // Assert
      expect(status['adaptersRegistered'], true);
      expect(status['serviceInitialized'], false);
      expect(status['serviceStatus'], null);
    });
  });

  group('NetworkInitializer 重新初始化测试（P1 功能验证）', () {
    test('reinitialize 应该清理旧实例并创建新实例', () async {
      // Arrange - 第一次初始化
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://old.example.com',
      );
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://old.example.com',
      );

      // Act - 重新初始化
      await KoiNetworkInitializer.reinitialize(
        baseUrl: 'https://new.example.com',
        environment: 'production',
      );

      // Assert
      expect(KoiNetworkInitializer.isInitialized, true);
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://new.example.com',
      );
      expect(
        KoiNetworkServiceManager.instance.config!.validateCertificate,
        false,
      );
    });
  });

  group('NetworkInitializer 清理测试（P1 功能验证）', () {
    test('dispose 应该清理所有资源', () async {
      // Arrange
      await KoiNetworkInitializer.initialize(
        baseUrl: 'https://api.example.com',
      );
      expect(KoiNetworkInitializer.isInitialized, true);

      // Act
      KoiNetworkInitializer.dispose();

      // Assert
      expect(KoiNetworkInitializer.isInitialized, false);
      expect(KoiNetworkServiceManager.instance.config, null);
    });
  });
}
