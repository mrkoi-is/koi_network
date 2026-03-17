import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:koi_network/src/koi_network_constants.dart';
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
    when(() => mockLogger.debug(any())).thenReturn(null);

    // 注册适配器
    KoiNetworkAdapters.register(
      authAdapter: mockAuth,
      errorHandlerAdapter: mockErrorHandler,
      loadingAdapter: mockLoading,
      loggerAdapter: mockLogger,
      platformAdapter: mockPlatform,
    );
    KoiNetworkConstants.debugEnabled = true;
  });

  tearDown(() {
    KoiNetworkServiceManager.instance.dispose();
    KoiNetworkAdapters.clear();
    KoiDioFactory.disposeAll();
  });

  group('NetworkServiceManager 单例测试（P1 功能验证）', () {
    test('instance 应该返回同一个实例', () {
      // Act
      final instance1 = KoiNetworkServiceManager.instance;
      final instance2 = KoiNetworkServiceManager.instance;
      final instance3 = KoiNetworkServiceManager();

      // Assert
      expect(identical(instance1, instance2), true);
      expect(identical(instance1, instance3), true);
    });
  });

  group('NetworkServiceManager 初始化测试（P1 功能验证）', () {
    test('初始化应该创建 Dio 实例', () async {
      // Arrange
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
      );

      // Act
      await KoiNetworkServiceManager.instance.initialize(config: config);

      // Assert
      expect(KoiNetworkServiceManager.instance.isInitialized, true);
      expect(KoiNetworkServiceManager.instance.config, isNotNull);
      expect(KoiNetworkServiceManager.instance.mainDio, isNotNull);
      expect(KoiNetworkServiceManager.instance.tokenDio, isNotNull);
    });

    test('重复初始化应该被忽略', () async {
      // Arrange
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(config: config);

      // Act - 第二次初始化
      await KoiNetworkServiceManager.instance.initialize(config: config);

      // Assert - 应该仍然是初始化状态
      expect(KoiNetworkServiceManager.instance.isInitialized, true);
      verify(() => mockLogger.warning(any())).called(greaterThanOrEqualTo(1));
    });

    test('未初始化时访问 mainDio 应该抛出异常', () {
      // Act & Assert
      expect(() => KoiNetworkServiceManager.instance.mainDio, throwsException);
    });

    test('未初始化时访问 tokenDio 应该抛出异常', () {
      // Act & Assert
      expect(() => KoiNetworkServiceManager.instance.tokenDio, throwsException);
    });

    test('使用默认配置初始化应该成功', () async {
      // Arrange
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
      );

      // Act
      await KoiNetworkServiceManager.instance.initialize(config: config);

      // Assert
      expect(KoiNetworkServiceManager.instance.isInitialized, true);
      expect(KoiNetworkServiceManager.instance.config, isNotNull);
    });
  });

  group('NetworkServiceManager 重新初始化测试（P1 功能验证）', () {
    test('reinitialize 应该清理旧实例并创建新实例', () async {
      // Arrange - 第一次初始化
      final config1 = KoiNetworkConfig.create(
        baseUrl: 'https://old.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(config: config1);
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://old.example.com',
      );

      // Act - 重新初始化
      final config2 = KoiNetworkConfig.create(
        baseUrl: 'https://new.example.com',
      );
      await KoiNetworkServiceManager.instance.reinitialize(config: config2);

      // Assert
      expect(KoiNetworkServiceManager.instance.isInitialized, true);
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://new.example.com',
      );
    });
  });

  group('NetworkServiceManager 配置更新测试（P1 功能验证）', () {
    test('updateConfig 应该更新配置并重新创建 Dio 实例', () async {
      // Arrange
      final config1 = KoiNetworkConfig.create(
        baseUrl: 'https://old.example.com',
        enableLogging: true,
      );
      await KoiNetworkServiceManager.instance.initialize(config: config1);

      // Act
      final config2 = KoiNetworkConfig.create(
        baseUrl: 'https://new.example.com',
        enableLogging: false,
      );
      await KoiNetworkServiceManager.instance.updateConfig(config2);

      // Assert
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://new.example.com',
      );
      expect(KoiNetworkServiceManager.instance.config!.enableLogging, false);
    });
  });

  group('NetworkServiceManager 状态管理测试（P1 功能验证）', () {
    test('getStatus 应该返回完整的状态信息', () async {
      // Arrange
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(config: config);

      // Act
      final status = KoiNetworkServiceManager.instance.getStatus();

      // Assert
      expect(status['isInitialized'], true);
      expect(status['hasConfig'], true);
      // expect(status['hasMainDio'], true); // Removed in new arch
      // expect(status['hasTokenDio'], true); // Removed in new arch
      expect(status['config'], isNotNull);
      expect(status['dioInstances'], isNotNull);
      expect((status['dioInstances'] as Map).containsKey('main'), true);
      expect((status['dioInstances'] as Map).containsKey('token'), true);
    });

    test('未初始化时 getStatus 应该返回正确的状态', () {
      // Act
      final status = KoiNetworkServiceManager.instance.getStatus();

      // Assert
      expect(status['isInitialized'], false);
      expect(status['hasConfig'], false);
      // expect(status['hasMainDio'], false); // Removed
      // expect(status['hasTokenDio'], false); // Removed
    });
  });

  group('NetworkServiceManager 多模块支持测试（P0 架构验证）', () {
    test('应该支持多模块并行初始化', () async {
      // 1. 初始化 Main 模块
      final mainConfig = KoiNetworkConfig.create(
        baseUrl: 'https://main.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(
        config: mainConfig,
        key: 'main',
      );

      // 2. 初始化 HighSchool 模块
      final hsConfig = KoiNetworkConfig.create(
        baseUrl: 'https://hs.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(
        config: hsConfig,
        key: 'highSchool',
      );

      // Assert
      final mainDio = KoiNetworkServiceManager.instance.getModuleDio('main');
      final hsDio = KoiNetworkServiceManager.instance.getModuleDio(
        'highSchool',
      );
      final tokenDio = KoiNetworkServiceManager.instance.getModuleDio('token');

      expect(mainDio, isNotNull);
      expect(hsDio, isNotNull);
      expect(tokenDio, isNotNull);

      // 验证 BaseURL 正确隔离
      expect(mainDio.options.baseUrl, 'https://main.example.com');
      expect(hsDio.options.baseUrl, 'https://hs.example.com');

      // 验证 Token Dio 是独立的实例，但所有模块都能获取
      expect(identical(mainDio, hsDio), false);
      expect(identical(mainDio, tokenDio), false);
    });

    test('非 Main 模块不应重复创建 Token Dio', () async {
      // 1. 初始化 Main (创建 token dio)
      await KoiNetworkServiceManager.instance.initialize(
        config: KoiNetworkConfig.create(baseUrl: 'https://main.example.com'),
        key: 'main',
      );
      final tokenDio1 = KoiNetworkServiceManager.instance.tokenDio;

      // 2. 初始化 HS (不应创建新的 token dio)
      await KoiNetworkServiceManager.instance.initialize(
        config: KoiNetworkConfig.create(baseUrl: 'https://hs.example.com'),
        key: 'highSchool',
      );
      final tokenDio2 = KoiNetworkServiceManager.instance.tokenDio;

      // Assert
      expect(
        identical(tokenDio1, tokenDio2),
        true,
        reason: '必须复用同一个 Token Dio 实例',
      );
    });

    test('清理 Main 模块应连带清理 Token Dio', () async {
      // Arrange
      await KoiNetworkServiceManager.instance.initialize(
        config: KoiNetworkConfig.create(baseUrl: 'https://main-test.com'),
        key: 'main',
      );
      expect(KoiDioFactory.hasInstance('token'), true);

      // Act
      await KoiNetworkServiceManager.instance.reinitialize(
        config: KoiNetworkConfig.create(baseUrl: 'https://new-main.com'),
        key: 'main',
      );

      // Assert - Token Dio 应该被重建（新实例）
      expect(KoiDioFactory.hasInstance('token'), true);
      expect(
        KoiNetworkServiceManager.instance.mainDio.options.baseUrl,
        'https://new-main.com',
      );
    });
  });

  group('NetworkServiceManager 清理测试（P1 功能验证）', () {
    test('dispose 应该清理所有资源', () async {
      // Arrange
      final config = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(config: config);
      expect(KoiNetworkServiceManager.instance.isInitialized, true);

      // Act
      KoiNetworkServiceManager.instance.dispose();

      // Assert
      expect(KoiNetworkServiceManager.instance.isInitialized, false);
      expect(KoiNetworkServiceManager.instance.config, null);
      expect(() => KoiNetworkServiceManager.instance.mainDio, throwsException);
      expect(() => KoiNetworkServiceManager.instance.tokenDio, throwsException);
    });

    test('dispose 后可以重新初始化', () async {
      // Arrange
      final config1 = KoiNetworkConfig.create(
        baseUrl: 'https://api.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(config: config1);
      KoiNetworkServiceManager.instance.dispose();

      // Act
      final config2 = KoiNetworkConfig.create(
        baseUrl: 'https://new.example.com',
      );
      await KoiNetworkServiceManager.instance.initialize(config: config2);

      // Assert
      expect(KoiNetworkServiceManager.instance.isInitialized, true);
      expect(
        KoiNetworkServiceManager.instance.config!.baseUrl,
        'https://new.example.com',
      );
    });
  });
}
