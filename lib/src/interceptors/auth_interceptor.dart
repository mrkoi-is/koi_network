import 'package:dio/dio.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart'
    show KoiPlatformAdapter;
import 'package:koi_network/src/koi_network_constants.dart';

/// Header 构建器，用于在请求前动态组装请求头。
/// Header builder — allows project code to inject dynamic headers per request.
typedef KoiHeaderBuilder =
    Future<Map<String, String>> Function(RequestOptions options);

/// Koi 认证拦截器。
/// Interceptor that injects authentication-related headers.
///
/// 自动添加认证信息和通用请求头。
/// Automatically adds authentication information and shared request headers.
///
/// 平台信息和应用版本通过 [KoiPlatformAdapter] 获取，
/// Platform information and app version are provided by [KoiPlatformAdapter],
/// 因此不依赖 Flutter 或 `package_info_plus`。
/// so it does not depend on Flutter or `package_info_plus`.
///
/// [headerBuilders] 可选的外部 Header 构建器列表，在通用请求头之后、认证头之前执行。
/// [headerBuilders] Optional list of header builder callbacks executed after
/// common headers but before the auth token.
class KoiAuthInterceptor extends QueuedInterceptor {
  /// Creates an auth interceptor with optional dynamic header builders.
  KoiAuthInterceptor({this.headerBuilders = const []});

  /// 外部注入的 Header 构建器列表，在通用请求头和认证信息之间执行。
  /// List of externally injected header builder callbacks, executed between
  /// common headers and the auth token.
  final List<KoiHeaderBuilder> headerBuilders;

  static int _requestCounter = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 添加通用请求头
      // Add common request headers
      _addCommonHeaders(options);

      // 执行外部注入的 header 构建器
      // Execute externally injected header builders
      for (final builder in headerBuilders) {
        try {
          final headers = await builder(options);
          options.headers.addAll(headers);
        } catch (e) {
          // 单个 builder 失败不影响整体
          // A single builder failure does not block the request
          if (KoiNetworkConstants.debugEnabled) {
            KoiNetworkAdapters.logger.warning(
              '⚠️ [Auth] Header builder failed: $e',
            );
          }
        }
      }

      // 添加认证信息
      // Add authentication headers
      _addAuthHeaders(options);

      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.info(
          '🔐 [Auth] Headers added: ${options.path}',
        );
      }

      handler.next(options);
    } catch (e) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.error(
          '❌ [Auth] Failed to add auth headers: $e',
        );
      }
      // 即使认证信息添加失败，也继续请求
      // Continue the request even if adding auth headers fails
      handler.next(options);
    }
  }

  /// 添加通用请求头。
  /// Adds common request headers.
  void _addCommonHeaders(RequestOptions options) {
    final platform = KoiNetworkAdapters.platform;
    final headers = <String, String>{
      'User-Agent': platform.userAgent,
      'X-App-Version': platform.appVersion,
      'X-Platform': platform.platform,
      'X-Platform-Name': platform.platformDisplayName,
      'X-Request-ID': _generateRequestId(),
      'X-Request-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    options.headers.addAll(headers);
  }

  /// 添加认证请求头。
  /// Adds authentication headers.
  void _addAuthHeaders(RequestOptions options) {
    // 若业务方已通过 header builder 显式注入 Authorization，则不覆盖。
    // If Authorization was already injected by a header builder, do not overwrite.
    if (options.headers.containsKey('Authorization')) {
      return;
    }

    try {
      final token = KoiNetworkAdapters.auth.getToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.warning(
          '⚠️ [Auth] Failed to get auth header: $e',
        );
      }
    }
  }

  /// 生成唯一请求 ID，基于原子计数器和微秒时间戳。
  /// Generates a unique request ID using an atomic counter and microsecond timestamp.
  String _generateRequestId() {
    return 'koi_${DateTime.now().microsecondsSinceEpoch}_${++_requestCounter}';
  }
}
