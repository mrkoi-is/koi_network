import 'package:dio/dio.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/response_parser.dart'
    show KoiResponseParser;
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/koi_network_constants.dart';

/// Koi 错误处理拦截器
/// Koi Error Handling Interceptor
///
/// 统一处理网络请求错误。使用 [KoiResponseParser] 提取错误消息
/// Unified handling of network request errors. Uses [KoiResponseParser] to extract error messages
///
/// 和判断认证错误，而非硬编码状态码和字段名。
/// and determine authentication errors, instead of hardcoding status codes and field names.
class KoiErrorHandlingInterceptor extends Interceptor {
  /// 创建错误处理拦截器
  /// Create error handling interceptor
  KoiErrorHandlingInterceptor(this.config);

  /// 网络配置
  /// Network configuration
  final KoiNetworkConfig config;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.error(
        '❌ [ErrorHandling] 请求错误 / Request Error',
        err,
        err.stackTrace,
      );
      _logErrorDetails(err);
    }

    // 尝试让适配器处理认证错误
    // Attempt to let the adapter handle authentication errors
    await _tryHandleAuthError(err);

    // 始终传播错误
    // Always propagate the error
    handler.next(err);
  }

  /// 记录错误详情
  /// Log error details
  void _logErrorDetails(DioException err) {
    final buffer = StringBuffer()
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('❌ Network Request Error Details')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('🔗 URL: ${err.requestOptions.uri}')
      ..writeln('📝 Method: ${err.requestOptions.method}')
      ..writeln('🏷️ Type: ${err.type}')
      ..writeln('💬 Message: ${err.message}');

    if (err.response != null) {
      buffer
        ..writeln('📊 Status Code: ${err.response?.statusCode}')
        ..writeln('📄 Response Data: ${err.response?.data}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    KoiNetworkAdapters.logger.error(buffer.toString());
  }

  /// 尝试处理认证错误
  /// Try to handle authentication error
  Future<void> _tryHandleAuthError(DioException err) async {
    try {
      final parser = KoiNetworkAdapters.responseParser;
      final responseBody = err.response?.data;

      // 使用 parser 判断是否为认证错误（可配置的状态码和响应体检测）
      // Use parser to determine if it is an authentication error (configurable status code and response body detection)
      final body = responseBody is Map<String, dynamic> ? responseBody : null;
      final isAuth = parser.isAuthError(err.response?.statusCode, body);

      if (isAuth) {
        final message = _extractErrorMessage(err);
        await KoiNetworkAdapters.errorHandler.handleAuthError(
          statusCode: err.response?.statusCode,
          message: message,
        );
      }
    } catch (e) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.error(
          '❌ [ErrorHandling] 处理认证错误失败 / Failed to handle auth error: $e',
        );
      }
    }
  }

  /// 提取错误消息
  /// Extract error message
  String _extractErrorMessage(DioException err) {
    // 使用 parser 从响应体提取消息
    // Extract message from response body using parser
    if (err.response?.data is Map<String, dynamic>) {
      final body = err.response!.data as Map<String, dynamic>;
      final msg = KoiNetworkAdapters.responseParser.getMessage(body);
      if (msg != null && msg.isNotEmpty) return msg;
    }

    // 使用 Dio 错误消息
    // Use Dio error message
    if (err.message != null && err.message!.isNotEmpty) {
      return err.message!;
    }

    // 根据错误类型返回默认消息
    // Return default message based on error type
    return _getDefaultErrorMessage(err.type);
  }

  /// 获取默认错误消息
  /// Get default error message
  String _getDefaultErrorMessage(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout => 'Connection timeout',
      DioExceptionType.sendTimeout => 'Send timeout',
      DioExceptionType.receiveTimeout => 'Receive timeout',
      DioExceptionType.badResponse => 'Bad server response',
      DioExceptionType.cancel => 'Request cancelled',
      DioExceptionType.connectionError => 'Connection error',
      DioExceptionType.unknown => 'Unknown error',
      _ => 'Network request failed',
    };
  }
}
