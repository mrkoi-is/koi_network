import 'package:dio/dio.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart'
    show KoiPlatformAdapter;
import 'package:koi_network/src/koi_network_constants.dart';

/// Koi 认证拦截器
/// Koi Authentication Interceptor
///
/// 自动添加认证信息和通用请求头。
/// Automatically adds authentication information and common request headers.
///
/// 平台信息和应用版本通过 [KoiPlatformAdapter] 获取，
/// Platform information and app version are obtained via [KoiPlatformAdapter],
/// 不依赖 Flutter 或 package_info_plus。
/// so it does not depend on Flutter or package_info_plus.
class KoiAuthInterceptor extends QueuedInterceptor {
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

  /// 添加通用请求头
  /// Add common request headers
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

  /// 添加认证头
  /// Add authentication headers
  void _addAuthHeaders(RequestOptions options) {
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

  /// 生成唯一请求 ID（原子计数器 + 微秒时间戳）
  /// Generate a unique request ID (atomic counter + microseconds timestamp)
  String _generateRequestId() {
    return 'koi_${DateTime.now().microsecondsSinceEpoch}_${++_requestCounter}';
  }
}
