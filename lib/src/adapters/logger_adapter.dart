/// Koi 日志适配器接口。
/// Logging abstraction for Koi Network.
///
/// 用于解耦网络库和项目特定的日志逻辑。
/// Decouples the library from project-specific logging implementations.
library;

// 默认实现使用 print 输出日志，实际项目中应注入 Logger 框架（如 Talker）
// The default implementation uses print for log output, actual projects should inject a Logger framework (like Talker)
// ignore_for_file: avoid_print

/// 日志适配器抽象接口。
/// Abstract interface for logging adapters.
///
/// 定义标准日志方法，允许业务层注入自定义日志实现。
/// Defines standard logging methods so host applications can inject custom
/// logging implementations.
abstract class KoiLoggerAdapter {
  /// 调试日志。
  /// Writes a debug log.
  void debug(String message, [dynamic error, StackTrace? stackTrace]);

  /// 信息日志。
  /// Writes an info log.
  void info(String message, [dynamic error, StackTrace? stackTrace]);

  /// 警告日志。
  /// Writes a warning log.
  void warning(String message, [dynamic error, StackTrace? stackTrace]);

  /// 错误日志。
  /// Writes an error log.
  void error(String message, [dynamic error, StackTrace? stackTrace]);

  /// 严重错误日志。
  /// Writes a fatal log.
  void fatal(String message, [dynamic error, StackTrace? stackTrace]);
}

/// 默认日志适配器，内部使用 `print`。
/// Default logger adapter implemented with `print`.
class KoiDefaultLoggerAdapter implements KoiLoggerAdapter {
  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    print('🐛 [DEBUG] $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   StackTrace: $stackTrace');
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    print('ℹ️ [INFO] $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   StackTrace: $stackTrace');
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    print('⚠️ [WARNING] $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   StackTrace: $stackTrace');
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('❌ [ERROR] $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   StackTrace: $stackTrace');
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    print('💀 [FATAL] $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   StackTrace: $stackTrace');
  }
}
