import 'package:dio/dio.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/core/dio_factory.dart';
import 'package:koi_network/src/koi_network_constants.dart';

/// Koi 网络服务管理器。
/// Singleton manager for Koi Network services.
///
/// 使用单例模式统一管理网络服务和 Dio 实例。
/// Manages network services and Dio instances through a singleton.
class KoiNetworkServiceManager {
  /// 获取单例实例。
  /// Returns the singleton instance.
  factory KoiNetworkServiceManager() => _instance;
  KoiNetworkServiceManager._internal();
  static final KoiNetworkServiceManager _instance =
      KoiNetworkServiceManager._internal();

  /// 获取静态单例实例。
  /// Returns the static singleton instance.
  static KoiNetworkServiceManager get instance => _instance;

  KoiNetworkConfig? _config;
  bool _isInitialized = false;

  /// 当前是否已初始化。
  /// Returns whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// 获取当前配置。
  /// Returns the current network configuration.
  KoiNetworkConfig? get config => _config;

  /// 获取指定模块的 Dio 实例，默认使用 `main`。
  /// Returns the Dio instance for a specific module, defaulting to `main`.
  Dio getModuleDio([String key = 'main']) {
    final dio = KoiDioFactory.getInstance(key);
    if (dio == null) {
      throw Exception(
        'Network service [$key] not initialized. Call initialize(key: "$key") first.',
      );
    }
    return dio;
  }

  /// 获取主 Dio 实例，保留向后兼容。
  /// Returns the main Dio instance for backward compatibility.
  Dio get mainDio => getModuleDio();

  /// 获取共享的 token Dio 实例，保留向后兼容。
  /// Returns the shared token Dio instance for backward compatibility.
  ///
  /// 所有模块共用同一个 token dio，因为使用相同的认证系统
  /// All modules share the same token dio, because they use the same authentication system
  Dio get tokenDio => getModuleDio('token');

  /// 初始化网络服务。
  /// Initializes the network service.
  Future<void> initialize({
    KoiNetworkConfig? config,
    String key = 'main',
  }) async {
    if (KoiDioFactory.hasInstance(key)) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.warning(
          '⚠️ Network service [$key] already initialized',
        );
      }
      return;
    }

    try {
      // 保存配置（主要针对 main，其他的由外部管理或随实例存储）
      // Save configuration (mainly for main, others managed externally or stored with instance)
      final networkConfig =
          config ?? KoiNetworkConfig.create(); // coverage:ignore-line
      if (key == 'main') {
        _config = networkConfig;
      }

      // 验证配置
      // Validate configuration
      if (!networkConfig.isValid) {
        throw Exception('Invalid network config: $key');
      }

      // 通过工厂创建并存入 Map 统一管理
      // Create via factory and store in Map for centralized management
      KoiDioFactory.createMainDio(networkConfig, key: key);

      // 只有 main 模块创建 token dio（所有模块共用）
      // Only the main module creates token dio (shared by all modules)
      if (key == 'main' && !KoiDioFactory.hasInstance('token')) {
        KoiDioFactory.createTokenDio(networkConfig);
      }

      if (key == 'main') {
        _isInitialized = true;
      }

      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.info('✅ Network service [$key] initialized');
        networkConfig.printSummary();
      }
    } catch (e, stackTrace) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.error(
          '❌ Network service [$key] init failed',
          e,
          stackTrace,
        );
      }
      rethrow;
    }
  }

  /// 重新初始化网络服务。
  /// Reinitializes the network service.
  Future<void> reinitialize({
    KoiNetworkConfig? config,
    String key = 'main',
  }) async {
    KoiDioFactory.disposeInstance(key);
    // 如果是 main 模块，也清理共享的 token dio
    // If it's the main module, also clean the shared token dio
    if (key == 'main') {
      KoiDioFactory.disposeInstance('token');
    }
    await initialize(config: config, key: key);
  }

  /// 更新配置。
  /// Updates the configuration for a module.
  Future<void> updateConfig(
    KoiNetworkConfig config, {
    String key = 'main',
  }) async {
    if (key == 'main') {
      _config = config;
    }

    // 重新创建 Dio 实例
    // Recreate Dio instance
    KoiDioFactory.recreateInstance(key, config);
    // 如果是 main 模块，也重新创建共享的 token dio
    // If it's the main module, also recreate the shared token dio
    if (key == 'main') {
      KoiDioFactory.recreateInstance('token', config);
    }

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('✅ Network config [$key] updated');
      config.printSummary();
    }
  }

  /// 获取服务状态。
  /// Returns the current service status.
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasConfig': _config != null,
      'config': _config?.summary,
      'dioInstances': KoiDioFactory.getAllInstancesInfo(),
    };
  }

  /// 打印服务状态。
  /// Logs the current service status.
  void printStatus() {
    if (KoiNetworkConstants.debugEnabled) {
      final status = getStatus();
      KoiNetworkAdapters.logger.info('📊 Network service status:\n$status');
    }
  }

  /// 清理资源。
  /// Disposes all managed resources.
  void dispose() {
    // 清理所有 Dio 实例（由工厂统一管理）
    // Dispose all Dio instances (centrally managed by factory)
    KoiDioFactory.disposeAll();

    _config = null;
    _isInitialized = false;

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🗑️ Network service disposed');
    }
  }
}
