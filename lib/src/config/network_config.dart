/// Koi 网络配置
///
/// 统一管理网络请求的配置参数
library;

import 'package:koi_network/src/adapters/network_adapters.dart';

class KoiNetworkConfig {
  const KoiNetworkConfig._({
    required this.baseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.enableLogging,
    required this.enableRetry,
    required this.maxRetries,
    required this.retryDelay,
    required this.validateCertificate,
    required this.maxConnectionsPerHost,
    required this.defaultHeaders,
    required this.customHeaders,
    required this.enableCache,
    required this.maxCacheSize,
    required this.enableProactiveTokenRefresh,
    required this.tokenRefreshThreshold,
    required this.tokenRefreshWhiteList,
  });

  /// 创建自定义配置
  factory KoiNetworkConfig.create({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool? enableLogging,
    bool? enableRetry,
    int? maxRetries,
    Duration? retryDelay,
    bool? validateCertificate,
    int? maxConnectionsPerHost,
    Map<String, String>? customHeaders,
    bool? enableCache,
    int? maxCacheSize,
    bool? enableProactiveTokenRefresh,
    Duration? tokenRefreshThreshold,
    List<String>? tokenRefreshWhiteList,
  }) {
    // 环境检测
    const isProd = bool.fromEnvironment('dart.vm.product');

    return KoiNetworkConfig._(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      sendTimeout: sendTimeout ?? const Duration(seconds: 15),
      enableLogging: enableLogging ?? !isProd,
      enableRetry: enableRetry ?? true,
      maxRetries: maxRetries ?? 3,
      retryDelay: retryDelay ?? const Duration(seconds: 1),
      // 注意：当前项目默认关闭证书校验（生产环境亦然）。
      // 如需开启严格证书校验，请在创建配置时显式传入 validateCertificate: true。
      validateCertificate: validateCertificate ?? false,
      maxConnectionsPerHost: maxConnectionsPerHost ?? 12,
      defaultHeaders: {'Accept': 'application/json'},
      customHeaders: customHeaders ?? {},
      enableCache: enableCache ?? false,
      maxCacheSize: maxCacheSize ?? 10 * 1024 * 1024, // 10MB
      enableProactiveTokenRefresh: enableProactiveTokenRefresh ?? true,
      tokenRefreshThreshold:
          tokenRefreshThreshold ?? const Duration(minutes: 5),
      tokenRefreshWhiteList: tokenRefreshWhiteList ?? [],
    );
  }

  /// 测试环境配置
  factory KoiNetworkConfig.testing({
    String? baseUrl,
    Map<String, String>? customHeaders,
    List<String>? tokenRefreshWhiteList,
    bool enableLogging = false,
    bool? enableProactiveTokenRefresh,
  }) {
    return KoiNetworkConfig.create(
      baseUrl: baseUrl ?? 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
      enableLogging: enableLogging,
      validateCertificate: false,
      enableRetry: true,
      maxRetries: 1,
      retryDelay: const Duration(milliseconds: 100),
      enableCache: false,
      customHeaders: customHeaders,
      tokenRefreshWhiteList: tokenRefreshWhiteList,
      enableProactiveTokenRefresh: enableProactiveTokenRefresh,
    );
  }

  /// 生产环境配置
  factory KoiNetworkConfig.production({
    String? baseUrl,
    Map<String, String>? customHeaders,
    List<String>? tokenRefreshWhiteList,
    bool enableLogging = false,
    bool? enableProactiveTokenRefresh,
  }) {
    assert(
      baseUrl != null && baseUrl.isNotEmpty,
      'Production baseUrl must not be empty',
    );

    return KoiNetworkConfig.create(
      baseUrl: baseUrl,
      enableLogging: enableLogging,
      validateCertificate: false,
      enableRetry: true,
      maxRetries: 1,
      enableCache: false,
      customHeaders: customHeaders,
      tokenRefreshWhiteList: tokenRefreshWhiteList,
      enableProactiveTokenRefresh: enableProactiveTokenRefresh,
    );
  }

  /// 开发环境配置
  factory KoiNetworkConfig.development({
    String? baseUrl,
    Map<String, String>? customHeaders,
    List<String>? tokenRefreshWhiteList,
    bool enableLogging = false,
    bool? enableProactiveTokenRefresh,
  }) {
    return KoiNetworkConfig.create(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
      enableLogging: enableLogging,
      validateCertificate: false,
      enableRetry: true,
      maxRetries: 1,
      retryDelay: const Duration(milliseconds: 500),
      enableCache: false,
      customHeaders: customHeaders,
      tokenRefreshWhiteList: tokenRefreshWhiteList,
      enableProactiveTokenRefresh: enableProactiveTokenRefresh,
    );
  }

  /// 基础 URL
  final String baseUrl;

  /// 连接超时
  final Duration connectTimeout;

  /// 接收超时
  final Duration receiveTimeout;

  /// 发送超时
  final Duration sendTimeout;

  /// 是否启用日志
  final bool enableLogging;

  /// 是否启用重试
  final bool enableRetry;

  /// 最大重试次数
  final int maxRetries;

  /// 重试延迟
  final Duration retryDelay;

  /// 是否验证证书
  final bool validateCertificate;

  /// 最大并发连接数
  final int maxConnectionsPerHost;

  /// 默认请求头
  final Map<String, String> defaultHeaders;

  /// 自定义请求头
  final Map<String, String> customHeaders;

  /// 是否启用缓存
  final bool enableCache;

  /// 最大缓存大小（字节）
  final int maxCacheSize;

  /// 是否启用主动 Token 刷新（无感刷新）
  final bool enableProactiveTokenRefresh;

  /// Token 刷新提前时间阈值（默认 5 分钟）
  final Duration tokenRefreshThreshold;

  /// Token 刷新拦截器白名单
  final List<String> tokenRefreshWhiteList;

  /// 配置是否有效
  bool get isValid {
    return baseUrl.isNotEmpty &&
        connectTimeout.inMilliseconds > 0 &&
        receiveTimeout.inMilliseconds > 0 &&
        sendTimeout.inMilliseconds > 0 &&
        maxRetries >= 0 &&
        maxConnectionsPerHost > 0;
  }

  /// 获取所有请求头
  Map<String, String> get allHeaders {
    return {...defaultHeaders, ...customHeaders};
  }

  /// 获取环境信息
  String get environment {
    const isProd = bool.fromEnvironment('dart.vm.product');
    if (isProd) return 'production';
    return 'development';
  }

  /// 是否为生产环境
  bool get isProduction => environment == 'production';

  /// 是否为开发环境
  bool get isDevelopment => environment == 'development';

  /// 是否为测试环境
  bool get isTesting => environment == 'testing';

  /// 配置摘要信息
  Map<String, dynamic> get summary => {
    'environment': environment,
    'baseUrl': baseUrl,
    'connectTimeout': '${connectTimeout.inMilliseconds}ms',
    'receiveTimeout': '${receiveTimeout.inMilliseconds}ms',
    'sendTimeout': '${sendTimeout.inMilliseconds}ms',
    'enableLogging': enableLogging,
    'enableRetry': enableRetry,
    'maxRetries': maxRetries,
    'retryDelay': '${retryDelay.inMilliseconds}ms',
    'validateCertificate': validateCertificate,
    'maxConnectionsPerHost': maxConnectionsPerHost,
    'enableCache': enableCache,
    'maxCacheSize': '${maxCacheSize}MB',
    'defaultHeadersCount': allHeaders.length,
  };

  /// 获取配置警告
  List<String> get warnings {
    final warnings = <String>[];

    if (connectTimeout.inSeconds > 30) {
      warnings.add('Connection timeout too long: ${connectTimeout.inSeconds}s');
    }

    if (receiveTimeout.inSeconds > 60) {
      warnings.add('Receive timeout too long: ${receiveTimeout.inSeconds}s');
    }

    if (maxRetries > 5) {
      warnings.add('Too many retries: $maxRetries');
    }

    if (maxCacheSize > 100 * 1024 * 1024) {
      warnings.add('Cache size too large: ${maxCacheSize ~/ (1024 * 1024)}MB');
    }

    if (!validateCertificate && isProduction) {
      // coverage:ignore-start
      warnings.add('SSL certificate validation disabled in production');
      // coverage:ignore-end
    }

    return warnings;
  }

  /// 打印配置摘要
  void printSummary() {
    final log = KoiNetworkAdapters.logger;
    log.info('📋 Koi Network Config:');
    log.info('   Base URL: $baseUrl');
    log.info('   Connect Timeout: ${connectTimeout.inSeconds}s');
    log.info('   Receive Timeout: ${receiveTimeout.inSeconds}s');
    log.info('   Enable Logging: $enableLogging');
    log.info('   Enable Retry: $enableRetry (max: $maxRetries)');
    log.info('   Validate Certificate: $validateCertificate');
    log.info('   Max Connections: $maxConnectionsPerHost');
    log.info('   Enable Cache: $enableCache');
  }

  /// 复制配置并修改部分参数
  KoiNetworkConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool? enableLogging,
    bool? enableRetry,
    int? maxRetries,
    Duration? retryDelay,
    bool? validateCertificate,
    int? maxConnectionsPerHost,
    Map<String, String>? customHeaders,
    bool? enableCache,
    int? maxCacheSize,
    bool? enableProactiveTokenRefresh,
    Duration? tokenRefreshThreshold,
    List<String>? tokenRefreshWhiteList,
  }) {
    // coverage:ignore-start
    return KoiNetworkConfig._(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
      enableRetry: enableRetry ?? this.enableRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      validateCertificate: validateCertificate ?? this.validateCertificate,
      maxConnectionsPerHost:
          maxConnectionsPerHost ?? this.maxConnectionsPerHost,
      defaultHeaders: defaultHeaders,
      customHeaders: customHeaders ?? this.customHeaders,
      enableCache: enableCache ?? this.enableCache,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      enableProactiveTokenRefresh:
          enableProactiveTokenRefresh ?? this.enableProactiveTokenRefresh,
      tokenRefreshThreshold:
          tokenRefreshThreshold ?? this.tokenRefreshThreshold,
      tokenRefreshWhiteList:
          tokenRefreshWhiteList ?? this.tokenRefreshWhiteList,
    );
    // coverage:ignore-end
  }

  @override
  String toString() {
    return 'KoiNetworkConfig(environment: $environment, baseUrl: $baseUrl, '
        'enableLogging: $enableLogging, enableRetry: $enableRetry)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KoiNetworkConfig &&
        other.baseUrl == baseUrl &&
        other.connectTimeout == connectTimeout &&
        other.receiveTimeout == receiveTimeout &&
        other.sendTimeout == sendTimeout &&
        other.enableLogging == enableLogging &&
        other.enableRetry == enableRetry &&
        other.maxRetries == maxRetries &&
        other.validateCertificate == validateCertificate;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseUrl,
      connectTimeout,
      receiveTimeout,
      sendTimeout,
      enableLogging,
      enableRetry,
      maxRetries,
      validateCertificate,
    );
  }
}
