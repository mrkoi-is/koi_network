import 'package:dio/dio.dart';
import 'package:koi_network/src/executors/request_executor.dart';
import 'package:koi_network/src/executors/typed_request_executor.dart';
import 'package:koi_network/src/models/request_execution_options.dart';
import 'package:koi_network/src/models/typed_response.dart';

/// Koi 网络请求 mixin。
/// Mixin that provides convenient request helpers for controllers.
///
/// 为 Controller 提供便捷的网络请求方法。
/// Adds convenient request helpers to controller classes.
///
/// 支持两种模式：
/// Supports two execution modes:
/// - **动态解析模式 (Dynamic Parsing Mode)**：通过 [KoiRequestExecutor] 执行原始 Dio 请求 / Executes original Dio requests via [KoiRequestExecutor]
/// - **强类型模式 (Typed Mode)**：通过 [KoiTypedRequestExecutor] 执行预解析的 Retrofit 请求 / Executes pre-parsed Retrofit requests via [KoiTypedRequestExecutor]
mixin KoiNetworkRequestMixin {
  // ==================== 动态解析模式 / Dynamic Parsing Mode ====================

  /// 通用请求。
  /// Executes a general request.
  Future<T?> universalRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool showLoading = true,
    bool showError = true,
    String? loadingText,
    bool needRethrow = true,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return KoiRequestExecutor.execute<T>(
      request: request,
      fromJson: fromJson,
      options: RequestExecutionOptions<T>(
        showLoading: showLoading,
        showError: showError,
        loadingText: loadingText,
        needRethrow: needRethrow,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
        successCheck: successCheck,
        dataCheck: dataCheck,
        dataNotNull: dataNotNull,
      ),
    );
  }

  /// 静默请求，不显示加载和错误。
  /// Executes a silent request without loading or error feedback.
  Future<T?> silentRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return KoiRequestExecutor.executeSilent<T>(
      request: request,
      fromJson: fromJson,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
      dataNotNull: dataNotNull,
      successCheck: successCheck,
      dataCheck: dataCheck,
    );
  }

  /// 快速请求，不显示加载但会显示错误。
  /// Executes a quick request that hides loading but still shows errors.
  Future<T?> quickRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return KoiRequestExecutor.executeQuick<T>(
      request: request,
      fromJson: fromJson,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
      dataNotNull: dataNotNull,
      successCheck: successCheck,
      dataCheck: dataCheck,
    );
  }

  /// 批量请求。
  /// Executes a batch of requests.
  Future<List<T?>> batchRequest<T>(
    List<Future<Response<dynamic>> Function()> requests, {
    T Function(dynamic json)? fromJson,
    bool concurrent = true,
    bool showLoading = true,
    String? loadingText,
    bool stopOnFirstError = false,
  }) async {
    return KoiRequestExecutor.executeBatch<T>(
      requests,
      fromJson: fromJson,
      options: BatchRequestOptions(
        concurrent: concurrent,
        showLoading: showLoading,
        loadingText: loadingText,
        stopOnFirstError: stopOnFirstError,
      ),
    );
  }

  /// 重试请求。
  /// Executes a request with retry support.
  Future<T?> retryRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool showLoading = true,
    bool showError = true,
  }) async {
    return KoiRequestExecutor.executeWithRetry<T>(
      request: request,
      fromJson: fromJson,
      maxRetries: maxRetries,
      delay: delay,
      options: RequestExecutionOptions<T>(
        showLoading: showLoading,
        showError: showError,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
      ),
    );
  }

  // ==================== 强类型模式（Retrofit 桥接） / Typed Mode (Retrofit Bridge) ====================

  /// 强类型通用请求。
  /// Executes a general typed request.
  ///
  /// 用于执行已由 Retrofit 预解析的强类型请求。
  /// Used for typed requests that have already been pre-parsed by Retrofit.
  ///
  /// [request] 返回实现了 [KoiTypedResponse] 的对象（如 `BaseResult<T>`）。
  /// [request] returns an object implementing [KoiTypedResponse], such as `BaseResult<T>`.
  Future<T?> typedRequest<T>({
    required Future<KoiTypedResponse<T>> Function() request,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool showLoading = true,
    bool showError = true,
    String? loadingText,
    bool needRethrow = true,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return KoiTypedRequestExecutor.execute<T>(
      request: request,
      options: RequestExecutionOptions<T>(
        showLoading: showLoading,
        showError: showError,
        loadingText: loadingText,
        needRethrow: needRethrow,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
        successCheck: successCheck,
        dataCheck: dataCheck,
        dataNotNull: dataNotNull,
      ),
    );
  }

  /// 强类型静默请求。
  /// Executes a silent typed request.
  Future<T?> typedSilentRequest<T>({
    required Future<KoiTypedResponse<T>> Function() request,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool dataNotNull = true,
  }) async {
    return KoiTypedRequestExecutor.executeSilent<T>(
      request: request,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
      dataNotNull: dataNotNull,
    );
  }

  /// 强类型快速请求。
  /// Executes a quick typed request.
  Future<T?> typedQuickRequest<T>({
    required Future<KoiTypedResponse<T>> Function() request,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return KoiTypedRequestExecutor.executeQuick<T>(
      request: request,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
      dataNotNull: dataNotNull,
      successCheck: successCheck,
      dataCheck: dataCheck,
    );
  }
}

/// 网络请求工具类。
/// Utility class for request helpers without using the mixin.
///
/// 提供静态方法访问，适用于不使用 mixin 的场景。
/// Exposes static helper methods for scenarios where the mixin is not used.
class NetworkRequestUtils {
  /// 通用请求。
  /// Executes a general request.
  static Future<T?> universalRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool showLoading = true,
    bool showError = true,
    String? loadingText,
    bool needRethrow = true,
  }) async {
    return KoiRequestExecutor.execute<T>(
      request: request,
      fromJson: fromJson,
      options: RequestExecutionOptions<T>(
        showLoading: showLoading,
        showError: showError,
        loadingText: loadingText,
        needRethrow: needRethrow,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
      ),
    );
  }

  /// 静默请求。
  /// Executes a silent request.
  static Future<T?> silentRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
  }) async {
    return KoiRequestExecutor.executeSilent<T>(
      request: request,
      fromJson: fromJson,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }

  /// 快速请求。
  /// Executes a quick request.
  static Future<T?> quickRequest<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
  }) async {
    return KoiRequestExecutor.executeQuick<T>(
      request: request,
      fromJson: fromJson,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }

  /// 强类型通用请求。
  /// Executes a general typed request.
  static Future<T?> typedRequest<T>({
    required Future<KoiTypedResponse<T>> Function() request,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool showLoading = true,
    bool showError = true,
    String? loadingText,
    bool needRethrow = true,
    bool dataNotNull = true,
  }) async {
    return KoiTypedRequestExecutor.execute<T>(
      request: request,
      options: RequestExecutionOptions<T>(
        showLoading: showLoading,
        showError: showError,
        loadingText: loadingText,
        needRethrow: needRethrow,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
        dataNotNull: dataNotNull,
      ),
    );
  }

  /// 强类型静默请求。
  /// Executes a silent typed request.
  static Future<T?> typedSilentRequest<T>({
    required Future<KoiTypedResponse<T>> Function() request,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
  }) async {
    return KoiTypedRequestExecutor.executeSilent<T>(
      request: request,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}
