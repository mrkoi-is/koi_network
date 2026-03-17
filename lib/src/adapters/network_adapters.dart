import 'package:koi_network/src/adapters/auth_adapter.dart';
import 'package:koi_network/src/adapters/error_handler_adapter.dart';
import 'package:koi_network/src/adapters/loading_adapter.dart';
import 'package:koi_network/src/adapters/logger_adapter.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart';
import 'package:koi_network/src/adapters/request_encoder.dart';
import 'package:koi_network/src/adapters/response_parser.dart';

/// Koi 网络适配器注册中心。
/// Central registry for Koi Network adapters.
///
/// 用于注册和管理所有适配器实例。
/// Registers and manages all adapter instances used by the library.
///
/// 项目端在初始化网络库前必须调用 [register] 注册适配器。
/// Host applications must call [register] before initializing the network layer.
class KoiNetworkAdapters {
  static KoiAuthAdapter? _authAdapter;
  static KoiErrorHandlerAdapter? _errorHandlerAdapter;
  static KoiLoadingAdapter? _loadingAdapter;
  static KoiPlatformAdapter? _platformAdapter;
  static KoiLoggerAdapter? _loggerAdapter;
  static KoiResponseParser? _responseParser;
  static KoiRequestEncoder? _requestEncoder;

  /// 注册所有适配器。
  /// Registers all adapter implementations.
  ///
  /// [authAdapter] 认证适配器（必填）/ Authentication adapter (required)
  /// [errorHandlerAdapter] 错误处理适配器（必填）/ Error handler adapter (required)
  /// [loadingAdapter] 加载提示适配器（必填）/ Loading prompt adapter (required)
  /// [platformAdapter] 平台信息适配器（必填）/ Platform information adapter (required)
  /// [loggerAdapter] 日志适配器（可选，默认使用 print 输出）/ Logger adapter (optional, uses print by default)
  /// [responseParser] 响应解析器（可选，默认标准 {code, msg, data} 格式）/ Response parser (optional, default standard format)
  /// [requestEncoder] 请求编码器（可选，默认 JSON 编码）/ Request encoder (optional, JSON encoding by default)
  static void register({
    required KoiAuthAdapter authAdapter,
    required KoiErrorHandlerAdapter errorHandlerAdapter,
    required KoiLoadingAdapter loadingAdapter,
    required KoiPlatformAdapter platformAdapter,
    KoiLoggerAdapter? loggerAdapter,
    KoiResponseParser? responseParser,
    KoiRequestEncoder? requestEncoder,
  }) {
    _authAdapter = authAdapter;
    _errorHandlerAdapter = errorHandlerAdapter;
    _loadingAdapter = loadingAdapter;
    _platformAdapter = platformAdapter;
    _loggerAdapter = loggerAdapter ?? KoiDefaultLoggerAdapter();
    _responseParser = responseParser ?? const KoiDefaultResponseParser();
    _requestEncoder = requestEncoder ?? const KoiJsonRequestEncoder();
  }

  /// 注册默认适配器，主要用于测试。
  /// Registers default adapters, mainly for testing.
  static void registerDefaults() {
    _authAdapter = KoiDefaultAuthAdapter();
    _errorHandlerAdapter = KoiDefaultErrorHandlerAdapter();
    _loadingAdapter = KoiDefaultLoadingAdapter();
    _platformAdapter = KoiDefaultPlatformAdapter();
    _loggerAdapter = KoiDefaultLoggerAdapter();
    _responseParser = const KoiDefaultResponseParser();
    _requestEncoder = const KoiJsonRequestEncoder();
  }

  /// 获取认证适配器。
  /// Returns the authentication adapter.
  static KoiAuthAdapter get auth {
    if (_authAdapter == null) {
      throw StateError(
        'KoiAuthAdapter not registered. Call KoiNetworkAdapters.register() first.',
      );
    }
    return _authAdapter!;
  }

  /// 获取错误处理适配器。
  /// Returns the error handler adapter.
  static KoiErrorHandlerAdapter get errorHandler {
    if (_errorHandlerAdapter == null) {
      throw StateError(
        'KoiErrorHandlerAdapter not registered. Call KoiNetworkAdapters.register() first.',
      );
    }
    return _errorHandlerAdapter!;
  }

  /// 获取加载提示适配器。
  /// Returns the loading adapter.
  static KoiLoadingAdapter get loading {
    if (_loadingAdapter == null) {
      throw StateError(
        'KoiLoadingAdapter not registered. Call KoiNetworkAdapters.register() first.',
      );
    }
    return _loadingAdapter!;
  }

  /// 获取平台工具适配器。
  /// Returns the platform adapter.
  static KoiPlatformAdapter get platform {
    if (_platformAdapter == null) {
      throw StateError(
        'KoiPlatformAdapter not registered. Call KoiNetworkAdapters.register() first.',
      );
    }
    return _platformAdapter!;
  }

  /// 获取日志适配器。
  /// Returns the logger adapter.
  static KoiLoggerAdapter get logger {
    _loggerAdapter ??= KoiDefaultLoggerAdapter();
    return _loggerAdapter!;
  }

  /// 获取响应解析器。
  /// Returns the response parser.
  static KoiResponseParser get responseParser {
    _responseParser ??= const KoiDefaultResponseParser();
    return _responseParser!;
  }

  /// 获取请求编码器。
  /// Returns the request encoder.
  static KoiRequestEncoder get requestEncoder {
    _requestEncoder ??= const KoiJsonRequestEncoder();
    return _requestEncoder!;
  }

  /// 检查是否已注册所有必需适配器。
  /// Returns whether all required adapters are registered.
  static bool get isRegistered {
    return _authAdapter != null &&
        _errorHandlerAdapter != null &&
        _loadingAdapter != null &&
        _platformAdapter != null;
  }

  /// 清除所有适配器，主要用于测试。
  /// Clears all registered adapters, mainly for testing.
  static void clear() {
    _authAdapter = null;
    _errorHandlerAdapter = null;
    _loadingAdapter = null;
    _platformAdapter = null;
    _loggerAdapter = null;
    _responseParser = null;
    _requestEncoder = null;
  }

  /// 获取适配器状态信息。
  /// Returns status information for all adapters.
  static Map<String, bool> getStatus() {
    return {
      'authAdapter': _authAdapter != null,
      'errorHandlerAdapter': _errorHandlerAdapter != null,
      'loadingAdapter': _loadingAdapter != null,
      'platformAdapter': _platformAdapter != null,
      'loggerAdapter': _loggerAdapter != null,
      'responseParser': _responseParser != null,
      'requestEncoder': _requestEncoder != null,
    };
  }
}
