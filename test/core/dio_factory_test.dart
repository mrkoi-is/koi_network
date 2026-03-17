import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

// Mock 类
class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

class MockErrorHandlerAdapter extends Mock implements KoiErrorHandlerAdapter {}

class MockLoadingAdapter extends Mock implements KoiLoadingAdapter {}

class MockLoggerAdapter extends Mock implements KoiLoggerAdapter {}

class MockPlatformAdapter extends Mock implements KoiPlatformAdapter {}

void main() {
  late MockAuthAdapter mockAuthAdapter;
  late MockErrorHandlerAdapter mockErrorHandlerAdapter;
  late MockLoadingAdapter mockLoadingAdapter;
  late MockLoggerAdapter mockLoggerAdapter;
  late MockPlatformAdapter mockPlatformAdapter;

  setUp(() {
    mockAuthAdapter = MockAuthAdapter();
    mockErrorHandlerAdapter = MockErrorHandlerAdapter();
    mockLoadingAdapter = MockLoadingAdapter();
    mockLoggerAdapter = MockLoggerAdapter();
    mockPlatformAdapter = MockPlatformAdapter();

    // 注册适配器
    KoiNetworkAdapters.register(
      authAdapter: mockAuthAdapter,
      errorHandlerAdapter: mockErrorHandlerAdapter,
      loadingAdapter: mockLoadingAdapter,
      loggerAdapter: mockLoggerAdapter,
      platformAdapter: mockPlatformAdapter,
    );

    // 设置 Mock 行为
    when(() => mockLoggerAdapter.debug(any(), any(), any())).thenReturn(null);
    when(() => mockLoggerAdapter.info(any(), any(), any())).thenReturn(null);
    when(() => mockLoggerAdapter.warning(any(), any(), any())).thenReturn(null);
    when(() => mockLoggerAdapter.error(any(), any(), any())).thenReturn(null);
    when(() => mockPlatformAdapter.platform).thenReturn('test');
    when(
      () => mockPlatformAdapter.platformDisplayName,
    ).thenReturn('Test Platform');
    when(
      () => mockPlatformAdapter.getPlatformConfig(),
    ).thenReturn({'platform': 'test', 'version': '1.0.0'});
  });

  tearDown(() {
    KoiNetworkAdapters.clear();
    KoiDioFactory.disposeAll(); // 清理所有 Dio 实例缓存
  });

  group('DioFactory SSL 验证测试', () {
    test('开发环境应该允许忽略 SSL 证书验证', () {
      // Arrange
      final config = KoiNetworkConfig.development(
        baseUrl: 'https://dev.example.com',
      );

      // Act
      final dio = KoiDioFactory.createMainDio(config);

      // Assert
      expect(dio, isNotNull);
      expect(dio.options.baseUrl, 'https://dev.example.com');
      expect(config.validateCertificate, false);
    });

    test('生产环境允许关闭 SSL 证书验证（按项目要求）', () {
      // Arrange
      final config = KoiNetworkConfig.production(
        baseUrl: 'https://api.example.com',
      );

      // Act
      final dio = KoiDioFactory.createMainDio(config);

      // Assert
      expect(dio, isNotNull);
      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(
        config.validateCertificate,
        false,
        reason: '当前项目要求生产环境关闭 SSL 证书验证',
      );
    });

    test('生产环境配置默认关闭 SSL 验证（按项目要求）', () {
      // Arrange
      final config = KoiNetworkConfig.production(
        baseUrl: 'https://api.example.com',
      );

      // Act & Assert
      expect(
        config.validateCertificate,
        false,
        reason: '当前项目要求生产环境默认关闭 SSL 证书验证',
      );

      // 注意：isProduction 是基于运行时环境变量 dart.vm.product，
      // 在测试环境中通常为 false，这是正常的
      // 重要的是 validateCertificate 配置正确

      // 注意：warnings 中对「生产环境未启用SSL证书验证」的判定依赖 dart.vm.product，
      // 在单测环境通常为 false，因此此处不校验 warnings，避免与运行环境耦合。
    });

    test('测试环境应该允许配置 SSL 验证', () {
      // Arrange
      final config = KoiNetworkConfig.testing(
        baseUrl: 'https://test.example.com',
      );

      // Act
      final dio = KoiDioFactory.createMainDio(config);

      // Assert
      expect(dio, isNotNull);
      expect(dio.options.baseUrl, 'https://test.example.com');
      // 测试环境默认关闭 SSL 验证（便于测试）
      expect(config.validateCertificate, false);
    });

    test('自定义配置可以显式控制 SSL 验证', () {
      // Arrange - 启用 SSL 验证
      final configWithSSL = KoiNetworkConfig.create(
        baseUrl: 'https://secure.example.com',
        validateCertificate: true,
      );

      // Act
      final dioWithSSL = KoiDioFactory.createCustomDio(
        'ssl_test',
        configWithSSL,
      );

      // Assert
      expect(dioWithSSL, isNotNull);
      expect(configWithSSL.validateCertificate, true);

      // Arrange - 禁用 SSL 验证
      final configWithoutSSL = KoiNetworkConfig.create(
        baseUrl: 'https://insecure.example.com',
        validateCertificate: false,
      );

      // Act
      final dioWithoutSSL = KoiDioFactory.createCustomDio(
        'no_ssl_test',
        configWithoutSSL,
      );

      // Assert
      expect(dioWithoutSSL, isNotNull);
      expect(configWithoutSSL.validateCertificate, false);
    });
  });
}
