import 'package:dio/dio.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/koi_network_constants.dart'
    show KoiNetworkConstants;
import 'package:koi_network/src/models/request_execution_options.dart';

/// 批量请求选项
/// Batch Request Options
///
/// 配置批量请求的执行行为，如并发模式、加载提示等
/// Configures the execution behavior of batch requests, such as concurrent mode, loading prompts, etc.
class BatchRequestOptions {
  /// 创建批量请求选项
  /// Create batch request options
  ///
  /// - [concurrent] 是否并发执行所有请求 / Whether to execute all requests concurrently
  /// - [showLoading] 是否显示加载提示 / Whether to show loading prompt
  /// - [loadingText] 加载提示文本 / Loading prompt text
  /// - [stopOnFirstError] 是否在第一个失败时停止 / Whether to stop on the first error
  const BatchRequestOptions({
    this.concurrent = true,
    this.showLoading = true,
    this.loadingText,
    this.stopOnFirstError = false,
  });

  /// 是否并发执行
  /// Whether to execute concurrently
  final bool concurrent;

  /// 是否显示加载提示
  /// Whether to show loading prompt
  final bool showLoading;

  /// 加载提示文本
  /// Loading prompt text
  final String? loadingText;

  /// 是否在第一个失败时停止
  /// Whether to stop on the first error
  final bool stopOnFirstError;
}

/// 请求逻辑异常
/// Request Logic Exception
///
/// 用于表示业务逻辑层面的请求失败，区别于网络层异常
/// Used to indicate request failure at the business logic layer, distinct from network layer exceptions
class RequestLogicException<T> implements Exception {
  /// 创建请求逻辑异常
  /// Create request logic exception
  ///
  /// - [message] 错误消息 / Error message
  /// - [data] 错误时携带的响应数据（可选） / Response data carried upon error (optional)
  /// - [errorCode] 业务错误码（可选） / Business error code (optional)
  RequestLogicException(this.message, {this.data, this.errorCode});

  /// 错误消息
  /// Error message
  final String message;

  /// 响应数据（错误时可能携带部分数据）
  /// Response data (may carry partial data upon error)
  final T? data;

  /// 业务错误码
  /// Business error code
  final int? errorCode;

  @override
  String toString() => 'RequestLogicException: $message (code: $errorCode)';
}

/// Koi 请求执行器
/// Koi Request Executor
///
/// 提供统一的请求执行逻辑，与后端响应格式无关。
/// Provides unified request execution logic, independent of the backend response format.
///
/// 通过 [KoiNetworkAdapters.responseParser] 解析响应数据。
/// Parses response data via [KoiNetworkAdapters.responseParser].
///
/// ## 使用方式 / Usage
///
/// ```dart
/// // 方式一：直接获取 dynamic 数据 / Method 1: Get dynamic data directly
/// final data = await KoiRequestExecutor.execute<Map<String, dynamic>>(
///   request: () => dio.get('/users'),
/// );
///
/// // 方式二：传入 fromJson 自动转型 / Method 2: Pass fromJson for auto-casting
/// final user = await KoiRequestExecutor.execute<User>(
///   request: () => dio.get('/user/1'),
///   fromJson: (json) => User.fromJson(json),
/// );
/// ```
class KoiRequestExecutor {
  /// 执行单个请求
  /// Execute a single request
  ///
  /// [request] 返回 Dio [Response] 的异步函数 / Async function returning a Dio [Response]
  /// [fromJson] 可选，将响应数据转换为目标类型 T / Optional, converts response data to target type T
  /// [options] 请求执行选项 / Request execution options
  static Future<T?> execute<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    RequestExecutionOptions<T>? options,
  }) async {
    final opts = options ?? RequestExecutionOptions<T>();
    final parser = KoiNetworkAdapters.responseParser;

    try {
      // 显示加载提示
      // Show loading prompt
      if (opts.showLoading) {
        KoiNetworkAdapters.loading.showLoading(message: opts.loadingText);
      }

      // 执行请求
      // Execute request
      final response = await request();
      final responseData = response.data;

      // 隐藏加载提示
      // Hide loading prompt
      if (opts.showLoading) {
        KoiNetworkAdapters.loading.hideLoading();
      }

      // 检查 HTTP 级别的认证错误
      // Check for HTTP-level authentication errors
      if (responseData is Map<String, dynamic>) {
        if (parser.isAuthError(response.statusCode, responseData)) {
          throw RequestLogicException<T>(
            'Authentication error',
            errorCode: response.statusCode,
          );
        }
      }

      // 提取业务数据
      // Extract business data
      T? data;
      bool isSuccess;

      if (responseData is Map<String, dynamic>) {
        // 结构化响应：通过 parser 解析
        // Structured response: parsed via parser
        isSuccess = parser.isSuccess(responseData);
        final rawData = parser.getData(responseData);
        data = fromJson != null ? fromJson(rawData) : rawData as T?;
      } else {
        // 非结构化响应（如直接返回 List 或原始值）
        // Unstructured response (e.g., returning List or raw values directly)
        isSuccess =
            response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300;
        data = fromJson != null ? fromJson(responseData) : responseData as T?;
      }

      // 自定义成功检查
      // Custom success check
      if (opts.successCheck != null) {
        if (!opts.successCheck!(data)) {
          final code = responseData is Map<String, dynamic>
              ? parser.getCode(responseData)
              : response.statusCode;
          throw RequestLogicException<T>(
            'Operation failed',
            data: data,
            errorCode: code,
          );
        }
      }

      // 自定义数据检查
      // Custom data check
      if (opts.dataCheck != null) {
        if (!opts.dataCheck!(data)) {
          final code = responseData is Map<String, dynamic>
              ? parser.getCode(responseData)
              : response.statusCode;
          throw RequestLogicException<T>(
            'Invalid data format',
            data: data,
            errorCode: code,
          );
        }
        opts.onSuccess?.call(data);
        return data;
      }

      // 处理结果
      // Process result
      if (isSuccess) {
        if (opts.dataNotNull && data == null) {
          final code = responseData is Map<String, dynamic>
              ? parser.getCode(responseData)
              : response.statusCode;
          throw RequestLogicException<T>(
            'No data available',
            data: data,
            errorCode: code,
          );
        }

        opts.onSuccess?.call(data);
        return data;
      } else {
        // 业务逻辑错误
        // Business logic error
        final msg = responseData is Map<String, dynamic>
            ? parser.getMessage(responseData)
            : null;
        final code = responseData is Map<String, dynamic>
            ? parser.getCode(responseData)
            : response.statusCode;
        throw RequestLogicException<T>(
          msg ?? 'Operation failed',
          data: data,
          errorCode: code,
        );
      }
    } catch (e) {
      KoiNetworkAdapters.logger.error(e.toString());

      // 隐藏加载提示
      // Hide loading prompt
      if (opts.showLoading) {
        KoiNetworkAdapters.loading.hideLoading();
      }

      // 错误处理
      // Error handling
      final errorMessage = getErrorMessage(e);

      if (opts.showError) {
        KoiNetworkAdapters.errorHandler.showError(errorMessage);
      }

      opts.onError?.call(e, errorMessage);

      if (opts.needRethrow) {
        rethrow;
      }

      return null;
    } finally {
      opts.onFinally?.call();
    }
  }

  /// 执行静默请求（不显示加载和错误提示）
  /// Execute a silent request (does not show loading or error prompts)
  static Future<T?> executeSilent<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return execute<T>(
      request: request,
      fromJson: fromJson,
      options: RequestExecutionOptions<T>(
        showLoading: false,
        showError: false,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
        dataNotNull: dataNotNull,
      ),
    );
  }

  /// 执行快速请求（不显示加载，但显示错误）
  /// Execute a quick request (does not show loading, but shows errors)
  static Future<T?> executeQuick<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool dataNotNull = true,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
  }) async {
    return execute<T>(
      request: request,
      fromJson: fromJson,
      options: RequestExecutionOptions<T>(
        showLoading: false,
        onSuccess: onSuccess,
        onError: onError,
        onFinally: onFinally,
        dataNotNull: dataNotNull,
        successCheck: successCheck,
        dataCheck: dataCheck,
      ),
    );
  }

  /// 执行批量请求
  /// Execute batch requests
  static Future<List<T?>> executeBatch<T>(
    List<Future<Response<dynamic>> Function()> requests, {
    T Function(dynamic json)? fromJson,
    BatchRequestOptions? options,
  }) async {
    final opts = options ?? const BatchRequestOptions();

    try {
      // 显示加载提示
      // Show loading prompt
      if (opts.showLoading) {
        KoiNetworkAdapters.loading.showLoading(
          message: opts.loadingText ?? 'Loading...',
        );
      }

      List<T?> results;

      if (opts.concurrent) {
        // 并发执行
        // Concurrent execution
        final futures = requests.map(
          (request) => _executeSingleInBatch<T>(
            request,
            fromJson: fromJson,
            stopOnError: opts.stopOnFirstError,
          ),
        );
        results = await Future.wait(futures);
      } else {
        // 顺序执行
        // Sequential execution
        results = [];
        for (final request in requests) {
          try {
            final result = await _executeSingleInBatch<T>(
              request,
              fromJson: fromJson,
              stopOnError: opts.stopOnFirstError,
            );
            results.add(result);
          } catch (e) {
            if (opts.stopOnFirstError) {
              rethrow;
            }
            results.add(null); // coverage:ignore-line
          }
        }
      }

      // 隐藏加载提示
      // Hide loading prompt
      if (opts.showLoading) {
        KoiNetworkAdapters.loading.hideLoading();
      }

      return results;
    } catch (e) {
      // 隐藏加载提示
      // Hide loading prompt
      if (opts.showLoading) {
        KoiNetworkAdapters.loading.hideLoading();
      }

      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.error('❌ Batch request failed', e);
      }

      rethrow;
    }
  }

  /// 执行单个批量请求中的请求
  /// Execute a single request within a batch
  static Future<T?> _executeSingleInBatch<T>(
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic json)? fromJson,
    bool stopOnError = false,
  }) async {
    final parser = KoiNetworkAdapters.responseParser;

    try {
      final response = await request();
      final responseData = response.data;

      bool isSuccess;
      T? data;

      if (responseData is Map<String, dynamic>) {
        isSuccess = parser.isSuccess(responseData);
        final rawData = parser.getData(responseData);
        data = fromJson != null ? fromJson(rawData) : rawData as T?;
      } else {
        isSuccess =
            response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300;
        data = fromJson != null ? fromJson(responseData) : responseData as T?;
      }

      if (isSuccess) {
        return data;
      } else {
        if (stopOnError) {
          final msg = responseData is Map<String, dynamic>
              ? parser.getMessage(responseData)
              : null;
          final code = responseData is Map<String, dynamic>
              ? parser.getCode(responseData)
              : response.statusCode;
          throw RequestLogicException<T>(
            msg ?? 'Request failed',
            data: data,
            errorCode: code,
          );
        }
        return null;
      }
    } catch (e) {
      if (stopOnError) {
        rethrow;
      }

      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.warning(
          '⚠️ Single request in batch failed',
          e,
        );
      }

      return null;
    }
  }

  /// 执行重试请求
  /// Execute a request with automatic retries
  ///
  /// ⚠️ 注意：Dio 已通过 dio_smart_retry 拦截器自动处理网络层重试。
  /// ⚠️ Note: Dio already handles network-layer retries automatically via the dio_smart_retry interceptor.
  ///
  /// 此方法主要用于应用层的业务逻辑重试（如业务错误码重试）。
  /// This method is primarily used for application-layer business logic retries (e.g., retrying on business error codes).
  static Future<T?> executeWithRetry<T>({
    required Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    RequestExecutionOptions<T>? options,
  }) async {
    final opts = options ?? RequestExecutionOptions<T>();

    if (KoiNetworkConstants.debugEnabled) {
      KoiNetworkAdapters.logger.info(
        '🔄 [Retry] App-level retry enabled (max $maxRetries)',
      );
    }

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await execute<T>(
          request: request,
          fromJson: fromJson,
          options: opts.copyWith(
            showLoading: attempt == 0 && opts.showLoading,
            showError: attempt == maxRetries && opts.showError,
            needRethrow: true,
          ),
        );
      } catch (e) {
        if (attempt == maxRetries) {
          if (KoiNetworkConstants.debugEnabled) {
            KoiNetworkAdapters.logger.warning(
              '❌ [Retry] Failed after $maxRetries retries',
            );
          }
          rethrow;
        }

        if (KoiNetworkConstants.debugEnabled) {
          KoiNetworkAdapters.logger.debug(
            '🔄 [Retry] Attempt ${attempt + 1}/$maxRetries',
            e,
          );
        }

        if (delay.inMilliseconds > 0) {
          await Future<void>.delayed(delay);
        }
      }
    }

    return null;
  }

  /// 获取错误消息
  /// Get error message
  static String getErrorMessage(Object e) {
    if (e is RequestLogicException) {
      return e.message;
    }

    if (e is DioException) {
      return KoiNetworkAdapters.errorHandler.formatErrorMessage(e);
    }

    return e.toString();
  }
}
