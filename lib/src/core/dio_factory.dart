import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/core/dio_adapter_web.dart'
    if (dart.library.io) 'package:koi_network/src/core/dio_adapter_native.dart';
import 'package:koi_network/src/interceptors/auth_interceptor.dart';
import 'package:koi_network/src/interceptors/error_handling_interceptor.dart';
import 'package:koi_network/src/interceptors/token_refresh_interceptor.dart';
import 'package:koi_network/src/koi_network_constants.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Koi Dio 工厂类。
/// Factory for creating and managing Dio instances in Koi Network.
///
/// 基于 Dio 官方最佳实践设计，提供：
/// Built on Dio best practices and provides:
/// - 统一的 Dio 实例创建 / Unified Dio instance creation
/// - 智能拦截器管理 / Smart interceptor management
/// - 环境相关配置 / Environment-aware configuration
/// - 性能优化 / Performance optimizations
class KoiDioFactory {
  static final Map<String, Dio> _dioInstances = {};

  /// 创建主 Dio 实例。
  /// Creates the main Dio instance.
  static Dio createMainDio(KoiNetworkConfig? config, {String key = 'main'}) {
    // 如果传入了 config，且缓存实例存在，检查是否需要重新创建
    // If config is passed and a cached instance exists, check if recreation is needed
    if (config != null && _dioInstances.containsKey(key)) {
      // 如果传入的 config 与缓存实例的配置不匹配，清除缓存并重新创建
      // If the passed config doesn't match the cached instance's config, clear cache and recreate
      // 这里我们总是使用传入的 config 重新创建，确保配置正确
      // Here we always recreate with the passed config to ensure correctness
      disposeInstance(key);
    } else if (_dioInstances.containsKey(key)) {
      // 如果没有传入 config，且缓存存在，直接返回（向后兼容）
      // If no config is passed, and a cache exists, return directly (backward compatibility)
      return _dioInstances[key]!;
    }

    final networkConfig = config ?? KoiNetworkConfig.create();
    final dio = _createDio(networkConfig);

    // 添加拦截器
    // Add interceptors
    _addInterceptors(dio, networkConfig);

    _dioInstances[key] = dio;

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🏭 Created main Dio instance: $key');
      networkConfig.printSummary();
    }

    return dio;
  }

  /// 创建 token 刷新专用的 Dio 实例。
  /// Creates a dedicated Dio instance for token refresh.
  static Dio createTokenDio(KoiNetworkConfig? config, {String key = 'token'}) {
    // 如果传入了 config，且缓存实例存在，检查是否需要重新创建
    // If config is passed and a cached instance exists, check if recreation is needed
    if (config != null && _dioInstances.containsKey(key)) {
      // 如果传入的 config 与缓存实例的配置不匹配，清除缓存并重新创建
      // If the passed config doesn't match the cached instance's config, clear cache and recreate
      // 这里我们总是使用传入的 config 重新创建，确保配置正确
      // Here we always recreate with the passed config to ensure correctness
      disposeInstance(key);
    } else if (_dioInstances.containsKey(key)) {
      // 如果没有传入 config，且缓存存在，直接返回（向后兼容）
      // If no config is passed, and a cache exists, return directly (backward compatibility)
      return _dioInstances[key]!;
    }

    final networkConfig = config ?? KoiNetworkConfig.create();
    final dio = _createDio(networkConfig);

    // Token 刷新实例只添加基础拦截器，避免循环依赖
    // Token refresh instance only adds basic interceptors to avoid circular dependencies
    _addBasicInterceptors(dio, networkConfig);

    _dioInstances[key] = dio;

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🔑 Created token refresh Dio instance');
    }

    return dio;
  }

  /// 创建自定义 Dio 实例。
  /// Creates a custom Dio instance.
  static Dio createCustomDio(
    String key,
    KoiNetworkConfig config, {
    List<Interceptor>? customInterceptors,
  }) {
    if (_dioInstances.containsKey(key)) {
      return _dioInstances[key]!;
    }

    final dio = _createDio(config);

    // 添加基础拦截器
    // Add basic interceptors
    _addBasicInterceptors(dio, config);

    // 添加自定义拦截器
    // Add custom interceptors
    if (customInterceptors != null) {
      customInterceptors.forEach(dio.interceptors.add);
    }

    _dioInstances[key] = dio;

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🔧 Created custom Dio instance: $key');
    }

    return dio;
  }

  /// 创建基础 Dio 实例。
  /// Creates a base Dio instance.
  static Dio _createDio(KoiNetworkConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: config.allHeaders,
        contentType: Headers.jsonContentType,
      ),
    );

    // 设置平台特定的 HTTP 适配器 (native: IOHttpClientAdapter, web: null/default)
    // Set platform-specific HTTP adapter (native: IOHttpClientAdapter, web: null/default)
    final adapter = createPlatformAdapter(config);
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }

    return dio;
  }

  /// 添加完整拦截器链。
  /// Adds the full interceptor chain.
  static void _addInterceptors(Dio dio, KoiNetworkConfig config) {
    // 清除现有拦截器
    // Clear existing interceptors
    dio.interceptors.clear();

    // 1. 添加缓存拦截器（最先添加，在其他拦截器之前）
    // 1. Add cache interceptor (add first, before other interceptors)
    if (config.enableCache) {
      final cacheOptions = CacheOptions(
        // 使用内存缓存（简单高效）
        // Use memory cache (simple and efficient)
        store: MemCacheStore(
          maxSize: config.maxCacheSize,
          maxEntrySize: 1048576, // 1MB per entry
        ),
        // 最大过期时间
        // Maximum expiration time
        maxStale: const Duration(days: 7),
      );

      dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

      if (KoiNetworkConstants.debugEnabled) {
        final sizeMB = config.maxCacheSize ~/ (1024 * 1024);
        KoiNetworkAdapters.logger.info(
          '💾 [Cache] Cache interceptor enabled (memory, max ${sizeMB}MB)',
        );
      }
    }

    // 2. 添加请求编码拦截器（在认证拦截器之前）
    // 自动将 Map data 通过注册的 KoiRequestEncoder 编码
    // （例如 TmsRequestEncoder 将 Map → FormData + token）
    // 2. Add request encoder interceptor (before auth interceptor)
    // Automatically encodes Map data via the registered KoiRequestEncoder
    // (e.g. TmsRequestEncoder transforms Map -> FormData + token)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 将 null 或 Map data 通过注册的编码器编码
          // 确保即使无 body 的 POST 请求也能注入 token
          // Encode null or Map data through the registered encoder
          // Ensures tokens can be injected even on POST requests without a body
          final data = options.data;
          if (data == null || data is Map<String, dynamic>) {
            options.data = KoiNetworkAdapters.requestEncoder.encode(
              (data as Map<String, dynamic>?) ?? <String, dynamic>{},
            );
          }
          handler.next(options);
        },
      ),
    );

    // 3. 添加认证和业务拦截器
    // 3. Add authentication and business interceptors
    dio.interceptors.add(KoiAuthInterceptor());
    dio.interceptors.add(
      KoiTokenRefreshInterceptor(
        dio,
        enableProactiveRefresh: config.enableProactiveTokenRefresh,
        refreshThreshold: config.tokenRefreshThreshold,
        whiteList: config.tokenRefreshWhiteList,
      ),
    );
    dio.interceptors.add(KoiErrorHandlingInterceptor(config));

    // 4. 添加重试拦截器（使用 dio_smart_retry）
    // 4. Add retry interceptor (using dio_smart_retry)
    if (config.enableRetry) {
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          retries: config.maxRetries,
          retryDelays: List.generate(
            config.maxRetries,
            (index) => config.retryDelay,
          ),
        ),
      );
    }

    // 5. 添加日志拦截器（最后添加，确保记录所有请求）
    // 5. Add logger interceptor (add last to ensure logging of all requests)
    if (config.enableLogging) {
      dio.interceptors.add(PrettyDioLogger(requestBody: true, compact: false));
    }

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info(
        '📡 Added ${dio.interceptors.length} interceptors',
      );
    }
  }

  /// 添加基础拦截器，主要用于 token 刷新实例。
  /// Adds the minimal interceptor set, mainly for the token refresh instance.
  static void _addBasicInterceptors(Dio dio, KoiNetworkConfig config) {
    // 清除现有拦截器
    // Clear existing interceptors
    dio.interceptors.clear();

    // 只添加认证拦截器
    // Only add auth interceptor
    dio.interceptors.add(KoiAuthInterceptor());

    // 添加日志拦截器
    // Add logger interceptor
    if (config.enableLogging) {
      dio.interceptors.add(PrettyDioLogger(requestBody: true, compact: false));
    }
  }

  /// 获取实例信息。
  /// Returns information for a specific Dio instance.
  static Map<String, dynamic> getInstanceInfo(String key) {
    final dio = _dioInstances[key];
    if (dio == null) {
      return {'exists': false};
    }

    return {
      'exists': true,
      'baseUrl': dio.options.baseUrl,
      'connectTimeout': dio.options.connectTimeout?.inMilliseconds,
      'receiveTimeout': dio.options.receiveTimeout?.inMilliseconds,
      'interceptorCount': dio.interceptors.length,
      'headers': dio.options.headers,
    };
  }

  /// 获取所有实例信息。
  /// Returns information for all Dio instances.
  static Map<String, dynamic> getAllInstancesInfo() {
    final info = <String, dynamic>{};
    for (final key in _dioInstances.keys) {
      info[key] = getInstanceInfo(key);
    }
    return info;
  }

  /// 打印工厂状态信息。
  /// Logs factory status information.
  static void printFactoryInfo() {
    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🏭 Koi Dio Factory status:');
      KoiNetworkAdapters.logger.info('   Instances: ${_dioInstances.length}');
      KoiNetworkAdapters.logger.info(
        '   Keys: ${_dioInstances.keys.join(', ')}',
      );

      for (final entry in _dioInstances.entries) {
        final dio = entry.value;
        KoiNetworkAdapters.logger.info(
          '   ${entry.key}: ${dio.options.baseUrl} '
          '(${dio.interceptors.length} interceptors)',
        );
      }
    }
  }

  /// 清理指定实例。
  /// Disposes a specific Dio instance.
  static void disposeInstance(String key) {
    final dio = _dioInstances.remove(key);
    if (dio != null) {
      dio.close();
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.info('🗑️ Disposed Dio instance: $key');
      }
    }
  }

  /// 清理所有实例。
  /// Disposes all Dio instances.
  static void disposeAll() {
    for (final entry in _dioInstances.entries) {
      entry.value.close();
    }
    _dioInstances.clear();

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info('🗑️ Disposed all Dio instances');
    }
  }

  /// 重新创建实例。
  /// Recreates a Dio instance.
  static Dio recreateInstance(String key, KoiNetworkConfig config) {
    disposeInstance(key);

    if (key == 'token') {
      return createTokenDio(config, key: key);
    }

    // 所有业务模块（main, highSchool, middleSchool 等）都使用 createMainDio
    // 以确保包含完整的拦截器链（重试、刷新、错误处理等）
    // All business modules (main, highSchool, middleSchool etc.) use createMainDio
    // to ensure the full interceptor chain is included (retry, refresh, error handling etc.)
    return createMainDio(config, key: key);
  }

  /// 获取实例数量。
  /// Returns the number of cached instances.
  static int get instanceCount => _dioInstances.length;

  /// 获取所有实例键。
  /// Returns all cached instance keys.
  static List<String> get instanceKeys => _dioInstances.keys.toList();

  /// 检查实例是否存在。
  /// Returns whether a cached instance exists for the key.
  static bool hasInstance(String key) => _dioInstances.containsKey(key);

  /// 获取实例（如果存在）。
  /// Returns the cached instance if it exists.
  static Dio? getInstance(String key) => _dioInstances[key];
}
