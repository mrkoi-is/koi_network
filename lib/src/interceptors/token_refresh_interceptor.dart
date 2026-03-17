import 'dart:async';

import 'package:dio/dio.dart';
import 'package:koi_network/src/adapters/auth_adapter.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';

/// Koi Token 刷新拦截器
/// Koi Token Refresh Interceptor
///
/// 双重保护机制：
/// Dual protection mechanism:
/// 1. 主动刷新（优先）：在 onRequest 中检查 Token 是否即将过期，提前刷新（无感知）
/// 1. Proactive refresh (priority): Checks if the Token is about to expire in `onRequest` and refreshes it in advance (seamlessly).
/// 2. 被动刷新（兜底）：在 onError 中处理 401/402 错误，触发刷新
/// 2. Passive refresh (fallback): Handles 401/402 errors in `onError` and triggers a refresh.
class KoiTokenRefreshInterceptor extends Interceptor {
  /// 创建 Token 刷新拦截器
  /// Create Token refresh interceptor
  ///
  /// - [_dio] 主 Dio 实例，用于重试请求 / Main Dio instance, used to retry requests
  /// - [enableProactiveRefresh] 是否启用主动刷新（默认开启） / Whether to enable proactive refresh (default is true)
  /// - [refreshThreshold] Token 刷新提前时间阈值（默认 5 分钟） / Token refresh advance time threshold (default 5 minutes)
  /// - [whiteList] 不需要 Token 刷新的白名单路径 / Whitelist paths that do not require Token refresh
  KoiTokenRefreshInterceptor(
    this._dio, {
    this.enableProactiveRefresh = true,
    this.refreshThreshold = const Duration(minutes: 5),
    this.whiteList = const [],
  });

  /// 主 Dio 实例（用于共享拦截器链重试）
  /// Main Dio instance (used for shared interceptor chain retries)
  final Dio _dio;

  /// 是否启用主动刷新（无感知刷新）
  /// Whether to enable proactive refresh (seamless refresh)
  final bool enableProactiveRefresh;

  /// Token 刷新提前时间阈值
  /// Token refresh advance time threshold
  final Duration refreshThreshold;

  /// 不需要 Token 刷新的白名单路径
  /// Whitelist paths that do not require Token refresh
  final List<String> whiteList;

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static const _kSkipTokenRefreshKey = 'koi_skip_token_refresh';
  static const _kSkipProactiveRefreshKey = 'koi_skip_proactive_refresh';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 检查是否在白名单中或被标记为跳过
    // Check if it is in the whitelist or marked to be skipped
    final path = options.path;
    if (options.extra[_kSkipTokenRefreshKey] == true ||
        whiteList.any(path.contains)) {
      handler.next(options);
      return;
    }

    // 1. 如果正在刷新，挂起当前请求，等待刷新结束
    // 1. If refreshing is in progress, suspend the current request and wait for the refresh to finish
    if (_isRefreshing && _refreshCompleter != null) {
      KoiNetworkAdapters.logger.debug(
        '⏳ [TokenRefresh] (OnRequest) Refreshing in progress, queuing: ${options.path}',
      );
      try {
        await _refreshCompleter!.future;
        // 刷新结束后，使用最新 Token 更新头
        // After refreshing, update the header with the latest Token
        final token = KoiNetworkAdapters.auth.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // coverage:ignore-start
        KoiNetworkAdapters.logger.warning(
          '⚠️ [TokenRefresh] (OnRequest) Wait for refresh failed, proceeding',
        );
        // coverage:ignore-end
      }
      handler.next(options);
      return;
    }

    // 2. 主动刷新检查
    // 2. Proactive refresh check
    if (enableProactiveRefresh &&
        options.extra[_kSkipProactiveRefreshKey] != true) {
      final adapter = KoiNetworkAdapters.auth;
      if (adapter is KoiJwtTokenMixin &&
          adapter.isTokenExpiringSoon(threshold: refreshThreshold)) {
        KoiNetworkAdapters.logger.warning(
          '🔄 [TokenRefresh] Token expiring soon, proactive refresh',
        );

        await _performRefresh();

        // 刷新完成后更新本次请求的 Token
        // After refresh is complete, update the Token for this request
        final token = KoiNetworkAdapters.auth.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.extra[_kSkipTokenRefreshKey] == true ||
        !_isAuthError(err)) {
      handler.next(err);
      return;
    }

    // 检查 Token 是否已过期（无法刷新）
    // Check if the Token has expired (cannot be refreshed)
    final auth = KoiNetworkAdapters.auth;
    if (auth is KoiJwtTokenMixin && auth.isTokenExpired()) {
      KoiNetworkAdapters.logger.error(
        '❌ [TokenRefresh] Token expired, forcing logout',
      );
      await _handleAuthFailure();
      handler.reject(err);
      return;
    }

    KoiNetworkAdapters.logger.warning(
      '🔄 [TokenRefresh] Auth error detected: ${err.requestOptions.path}',
    );

    // 非可重放请求体（流/表单）无法自动重试，优先刷新 Token 后直接返回错误
    // Non-replayable request bodies (stream/form) cannot be automatically retried, prioritize refreshing Token then returning the error directly
    if (_isNonReplayableBody(err.requestOptions.data)) {
      KoiNetworkAdapters.logger.warning(
        '🚫 [TokenRefresh] Non-replayable body, skip auto-retry: ${err.requestOptions.path}',
      );

      if (_isRefreshing && _refreshCompleter != null) {
        await _refreshCompleter!.future;
      } else {
        await _performRefresh();
      }

      handler.reject(err);
      return;
    }

    // 如果正在刷新，等待刷新结果后重试
    // If refreshing is in progress, wait for the refresh result and then retry
    if (_isRefreshing && _refreshCompleter != null) {
      KoiNetworkAdapters.logger.debug(
        '⏳ [TokenRefresh] (OnError) Refreshing, queuing for retry',
      );
      try {
        final success = await _refreshCompleter!.future;
        if (success) {
          _retryRequest(err.requestOptions, handler);
        } else {
          handler.reject(err);
        }
      } catch (e) {
        handler.reject(err); // coverage:ignore-line
      }
      return;
    }

    // 触发刷新
    // Trigger refresh
    final success = await _performRefresh();
    if (success) {
      KoiNetworkAdapters.logger.info(
        '✅ [TokenRefresh] Refresh succeeded, retrying',
      );
      _retryRequest(err.requestOptions, handler);
    } else {
      KoiNetworkAdapters.logger.error(
        '❌ [TokenRefresh] Refresh failed, rejecting',
      );
      await _handleAuthFailure();
      handler.reject(err);
    }
  }

  /// 执行刷新逻辑（保证同一时间只有一个刷新在运行）
  /// Execute refresh logic (ensuring only one refresh is running at a time)
  Future<bool> _performRefresh() async {
    // 双重检查：防止并发进入时重复刷新
    // Double check: prevent duplicate refresh on concurrent entry
    if (_isRefreshing) {
      return (await _refreshCompleter?.future) ?? false; // coverage:ignore-line
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final success = await KoiNetworkAdapters.auth.refresh();
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(success);
      }
      return success;
    } catch (e) {
      KoiNetworkAdapters.logger.error('❌ [TokenRefresh] Refresh exception: $e');
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(
          false,
        ); // 异常视为失败 / Exception treated as failure
      }
      return false;
    } finally {
      _isRefreshing = false;
      // 这里的 completer 不置空，保留给最后等待的请求读取结果，直到下一次刷新开始覆盖
      // The completer is not nullified here, keeping it for the last waiting request to read the result, until overridden by the next refresh
    }
  }

  void _retryRequest(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) {
    final retryOptions = _cloneOptions(requestOptions);
    retryOptions.extra[_kSkipTokenRefreshKey] = true;

    // 显式设置 Authorization 头，确保使用最新 Token
    // Explicitly set the Authorization header to ensure the latest Token is used
    final token = KoiNetworkAdapters.auth.getToken();
    if (token != null && token.isNotEmpty) {
      retryOptions.headers['Authorization'] = 'Bearer $token';
    }

    _dio
        .fetch<dynamic>(retryOptions)
        .then((response) {
          handler.resolve(response);
        })
        .catchError((Object e) {
          handler.reject(
            DioException(requestOptions: requestOptions, error: e),
          );
        });
  }

  /// 检查是否为认证错误（通过 responseParser 配置）
  /// Check if it is an authentication error (via responseParser configuration)
  bool _isAuthError(DioException err) {
    final body = err.response?.data;
    final mapBody = body is Map<String, dynamic> ? body : null;
    return KoiNetworkAdapters.responseParser.isAuthError(
      err.response?.statusCode,
      mapBody,
    );
  }

  RequestOptions _cloneOptions(RequestOptions o) {
    return RequestOptions(
      path: o.path,
      method: o.method,
      headers: Map<String, dynamic>.from(o.headers),
      baseUrl: o.baseUrl,
      queryParameters: Map<String, dynamic>.from(o.queryParameters),
      data: _cloneRequestData(o.data),
      connectTimeout: o.connectTimeout,
      sendTimeout: o.sendTimeout,
      receiveTimeout: o.receiveTimeout,
      responseType: o.responseType,
      contentType: o.contentType,
      followRedirects: o.followRedirects,
      validateStatus: o.validateStatus,
      receiveDataWhenStatusError: o.receiveDataWhenStatusError,
      cancelToken: o.cancelToken,
      onReceiveProgress: o.onReceiveProgress,
      onSendProgress: o.onSendProgress,
      maxRedirects: o.maxRedirects,
      requestEncoder: o.requestEncoder,
      responseDecoder: o.responseDecoder,
      listFormat: o.listFormat,
      extra: Map<String, dynamic>.from(o.extra),
    );
  }

  /// 处理认证失败
  /// Handle authentication failure
  Future<void> _handleAuthFailure() async {
    try {
      await KoiNetworkAdapters.errorHandler.handleAuthError(
        statusCode: 401,
        message: 'Session expired, please log in again',
      );
    } catch (e) {
      KoiNetworkAdapters.logger.error(
        '❌ [TokenRefresh] Auth failure handler error: $e',
      );
    }
  }

  dynamic _cloneRequestData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return data;
  }

  bool _isNonReplayableBody(dynamic data) {
    return data is Stream || data is FormData || data is MultipartFile;
  }
}
