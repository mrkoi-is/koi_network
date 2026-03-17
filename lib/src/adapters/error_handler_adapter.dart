import 'package:dio/dio.dart';

/// Koi 错误处理适配器接口。
/// Interface for project-level error handling.
///
/// 用于解耦网络库和项目特定的错误处理逻辑。
/// Decouples the networking layer from project-specific error handling logic.
abstract class KoiErrorHandlerAdapter {
  /// 显示错误消息。
  /// Shows an error message.
  void showError(String message);

  /// 显示成功消息，可选实现。
  /// Shows a success message, if supported.
  void showSuccess(String message) {}

  /// 显示警告消息，可选实现。
  /// Shows a warning message, if supported.
  void showWarning(String message) {}

  /// 显示信息消息，可选实现。
  /// Shows an informational message, if supported.
  void showInfo(String message) {}

  /// 处理认证错误，例如 401 或 402。
  /// Handles authentication-related errors such as 401 or 402.
  ///
  /// 此方法通常需要全局处理，例如弹窗提示、登出、跳转登录页。
  /// This method is typically handled globally, for example by showing a dialog,
  /// logging out, or redirecting to the login page.
  ///
  /// 返回 `true` 表示已处理，返回 `false` 表示需要继续传播错误。
  /// Returns `true` if the error has been handled, otherwise `false` to keep propagating it.
  Future<bool> handleAuthError({int? statusCode, String? message}) async {
    return false;
  }

  /// 格式化错误消息。
  /// Formats a user-facing error message from Dio exceptions.
  String formatErrorMessage(DioException error);
}

/// 默认错误处理适配器，仅打印日志。
/// Default error handler adapter that only prints logs.
class KoiDefaultErrorHandlerAdapter implements KoiErrorHandlerAdapter {
  @override
  void showError(String message) {
    // 默认实现使用 print 输出调试信息，实际项目中应通过子类实现 UI 提示
    // ignore: avoid_print
    print('❌ Error: $message');
  }

  @override
  void showSuccess(String message) {
    // 默认实现使用 print 输出调试信息，实际项目中应通过子类实现 UI 提示
    // ignore: avoid_print
    print('✅ Success: $message');
  }

  @override
  void showWarning(String message) {
    // 默认实现使用 print 输出调试信息，实际项目中应通过子类实现 UI 提示
    // ignore: avoid_print
    print('⚠️ Warning: $message');
  }

  @override
  void showInfo(String message) {
    // 默认实现使用 print 输出调试信息，实际项目中应通过子类实现 UI 提示
    // ignore: avoid_print
    print('ℹ️ Info: $message');
  }

  @override
  Future<bool> handleAuthError({int? statusCode, String? message}) async {
    // 默认实现使用 print 输出调试信息，实际项目中应通过子类处理登出逻辑
    // ignore: avoid_print
    print('🔐 Auth Error: $statusCode - $message');
    return false;
  }

  @override
  String formatErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection failed';
      case DioExceptionType.unknown:
        return 'Unknown error: ${error.message}';
      default:
        return 'Network request failed';
    }
  }
}
