import 'package:dio/dio.dart';

/// Koi 错误处理适配器接口
///
/// 用于解耦网络库和项目特定的错误处理逻辑
abstract class KoiErrorHandlerAdapter {
  /// 显示错误消息
  void showError(String message);

  /// 显示成功消息（可选）
  void showSuccess(String message) {}

  /// 显示警告消息（可选）
  void showWarning(String message) {}

  /// 显示信息消息（可选）
  void showInfo(String message) {}

  /// 处理认证错误（401/402）
  ///
  /// 此方法需要全局处理：弹窗提示 + 登出 + 跳转登录页
  ///
  /// 返回 true 表示已处理，false 表示需要继续传播错误
  Future<bool> handleAuthError({int? statusCode, String? message}) async {
    return false;
  }

  /// 格式化错误消息
  String formatErrorMessage(DioException error);
}

/// 默认的错误处理适配器（仅打印日志）
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
