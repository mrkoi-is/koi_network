import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/core/network_service_manager.dart';
import 'package:koi_network/src/koi_network_constants.dart';

/// Koi 网络初始化器。
/// Entry point for initializing Koi Network.
///
/// 提供快速初始化网络服务的便捷方法。
/// Provides convenient helpers for bootstrapping network services.
class KoiNetworkInitializer {
  /// 快速初始化网络服务。
  /// Quickly initializes network services.
  ///
  /// 这是初始化网络模块的主要入口。
  /// This is the primary entry point for initializing network modules.
  ///
  /// 支持多模块并行管理，每个模块都可以使用独立的 base URL。
  /// Supports multiple modules in parallel, each with its own base URL.
  ///
  /// ### 参数说明 / Parameters
  /// - [baseUrl] API 基础地址，必填 / Required API base URL
  /// - [environment] 环境标识，如 `development`、`production` / Environment name such as `development` or `production`
  /// - [customHeaders] 自定义请求头 / Custom request headers
  /// - [tokenRefreshWhiteList] token 刷新白名单 URL 列表 / URL whitelist for token refresh checks
  /// - [enableLogging] 是否启用网络日志 / Whether to enable network logging
  /// - [key] 模块标识符，用于区分不同模块实例 / Module key used to distinguish different network instances
  ///
  /// ### Key 约定 / Key Conventions
  /// 建议使用有业务语义的 key 值。
  /// Use module keys with clear business meaning.
  /// - `'main'` 通用/公共模块（默认值） / General or shared module (default)
  /// - `'highSchool'` 高中业务模块 / High school business module
  /// - `'middleSchool'` 初中业务模块 / Middle school business module
  ///
  /// ### Token 管理 / Token Management
  /// 所有模块共享同一个 token Dio 实例（`key='token'`），因为它们使用同一套认证体系。
  /// All modules share the same token Dio instance (`key='token'`) because
  /// they rely on the same authentication system.
  /// token 刷新通常由 `main` 模块创建，其他模块复用。
  /// Token refresh is typically created by the `main` module and reused by others.
  ///
  /// ### 示例 / Example
  /// ```dart
  /// // 初始化主模块 / Initialize main module
  /// await KoiNetworkInitializer.initialize(
  ///   baseUrl: 'https://api.example.com/',
  ///   environment: 'production',
  ///   key: 'main',
  /// );
  ///
  /// // 初始化高中模块（使用不同的 BaseURL）/ Initialize high school module (different BaseURL)
  /// await KoiNetworkInitializer.initialize(
  ///   baseUrl: 'https://hs-api.example.com/',
  ///   environment: 'production',
  ///   key: 'highSchool',
  /// );
  /// ```
  static Future<void> initialize({
    String? baseUrl,
    String environment = 'development',
    Map<String, String>? customHeaders,
    List<String>? tokenRefreshWhiteList,
    bool enableLogging = false,
    bool enableProactiveTokenRefresh = true,
    String key = 'main',
  }) async {
    try {
      // 检查适配器是否已注册
      // Check if adapters are registered
      if (!KoiNetworkAdapters.isRegistered) {
        throw Exception(
          'Adapters not registered. Call KoiNetworkAdapters.register() first.',
        );
      }

      // 创建配置
      // Create configuration
      final config = _createConfig(
        baseUrl: baseUrl,
        environment: environment,
        customHeaders: customHeaders,
        tokenRefreshWhiteList: tokenRefreshWhiteList,
        enableLogging: enableLogging,
        enableProactiveTokenRefresh: enableProactiveTokenRefresh,
      );

      // 初始化服务
      // Initialize service
      await KoiNetworkServiceManager.instance.initialize(
        config: config,
        key: key,
      );

      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.info('✅ Koi Network initialized');
      }
    } catch (e, stackTrace) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.error(
          '❌ Koi Network initialization failed',
          e,
          stackTrace,
        );
      }
      rethrow;
    }
  }

  /// 使用自定义配置初始化。
  /// Initializes the network layer with a custom configuration.
  static Future<void> initializeWithConfig(KoiNetworkConfig config) async {
    try {
      // 检查适配器是否已注册
      // Check if adapters are registered
      if (!KoiNetworkAdapters.isRegistered) {
        throw Exception(
          'Adapters not registered. Call KoiNetworkAdapters.register() first.',
        );
      }

      // 初始化服务
      // Initialize service
      await KoiNetworkServiceManager.instance.initialize(config: config);

      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.info(
          '✅ Koi Network initialized (custom config)',
        );
      }
    } catch (e, stackTrace) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.error(
          '❌ Koi Network initialization failed',
          e,
          stackTrace,
        );
      }
      rethrow;
    }
  }

  /// 根据环境创建配置。
  /// Creates a configuration object for the given environment.
  static KoiNetworkConfig _createConfig({
    required String environment,
    String? baseUrl,
    Map<String, String>? customHeaders,
    List<String>? tokenRefreshWhiteList,
    bool enableLogging = false,
    bool enableProactiveTokenRefresh = true,
  }) {
    switch (environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return KoiNetworkConfig.production(
          baseUrl: baseUrl,
          customHeaders: customHeaders,
          tokenRefreshWhiteList: tokenRefreshWhiteList,
          enableProactiveTokenRefresh: enableProactiveTokenRefresh,
        );

      case 'testing':
      case 'test':
        return KoiNetworkConfig.testing(
          baseUrl: baseUrl,
          customHeaders: customHeaders,
          tokenRefreshWhiteList: tokenRefreshWhiteList,
          enableLogging: enableLogging,
          enableProactiveTokenRefresh: enableProactiveTokenRefresh,
        );

      case 'development':
      case 'dev':
      default:
        return KoiNetworkConfig.development(
          baseUrl: baseUrl,
          customHeaders: customHeaders,
          tokenRefreshWhiteList: tokenRefreshWhiteList,
          enableLogging: enableLogging,
          enableProactiveTokenRefresh: enableProactiveTokenRefresh,
        );
    }
  }

  /// 当前是否已初始化。
  /// Returns whether the network layer has been initialized.
  static bool get isInitialized =>
      KoiNetworkServiceManager.instance.isInitialized;

  /// 获取当前服务状态。
  /// Returns the current service status.
  static Map<String, dynamic> getStatus() {
    return {
      'adaptersRegistered': KoiNetworkAdapters.isRegistered,
      'serviceInitialized': isInitialized,
      'adapterStatus': KoiNetworkAdapters.getStatus(),
      'serviceStatus': isInitialized
          ? KoiNetworkServiceManager.instance.getStatus()
          : null,
    };
  }

  /// 打印当前状态。
  /// Logs the current status.
  static void printStatus() {
    if (KoiNetworkConstants.debugEnabled) {
      final status = getStatus();
      KoiNetworkAdapters.logger.info('📊 Koi Network status:\n$status');
    }
  }

  /// 重新初始化网络服务。
  /// Reinitializes network services.
  static Future<void> reinitialize({
    String? baseUrl,
    String environment = 'development',
    Map<String, String>? customHeaders,
    bool enableLogging = false,
    List<String>? tokenRefreshWhiteList,
    String key = 'main',
  }) async {
    final config = _createConfig(
      baseUrl: baseUrl,
      environment: environment,
      customHeaders: customHeaders,

      tokenRefreshWhiteList: tokenRefreshWhiteList,
      enableLogging: enableLogging,
    );

    await KoiNetworkServiceManager.instance.reinitialize(
      config: config,
      key: key,
    );

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('✅ Koi Network reinitialized');
    }
  }

  /// 清理资源。
  /// Disposes network resources.
  static void dispose() {
    KoiNetworkServiceManager.instance.dispose();

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🗑️ Koi Network disposed');
    }
  }
}
