/// 请求执行选项
/// Request Execution Options
///
/// 用于配置单个请求的执行行为
/// Used to configure the execution behavior of a single request
class RequestExecutionOptions<T> {
  /// 创建请求执行选项
  /// Create request execution options
  ///
  /// - [onSuccess] 成功回调 / Success callback
  /// - [onError] 错误回调 / Error callback
  /// - [onFinally] 完成回调（无论成功或失败） / Finally callback (whether successful or failed)
  /// - [needRethrow] 是否需要重新抛出异常 / Whether to rethrow exceptions
  /// - [showLoading] 是否显示加载提示 / Whether to show loading prompt
  /// - [showError] 是否显示错误提示 / Whether to show error prompt
  /// - [loadingText] 加载提示文本 / Loading prompt text
  /// - [successCheck] 自定义成功检查函数 / Custom success check function
  /// - [dataCheck] 自定义数据检查函数 / Custom data check function
  /// - [dataNotNull] 数据是否不能为空 / Whether data must not be null
  const RequestExecutionOptions({
    this.onSuccess,
    this.onError,
    this.onFinally,
    this.needRethrow = false,
    this.showLoading = true,
    this.showError = true,
    this.loadingText,
    this.successCheck,
    this.dataCheck,
    this.dataNotNull = true,
  });

  /// 创建静默请求选项（不显示加载和错误）
  /// Create silent request options (no loading and error prompts)
  factory RequestExecutionOptions.silent() {
    return const RequestExecutionOptions(showLoading: false, showError: false);
  }

  /// 创建快速请求选项（不显示加载，但显示错误）
  /// Create quick request options (no loading prompt, but shows errors)
  factory RequestExecutionOptions.quick() {
    return const RequestExecutionOptions(showLoading: false);
  }

  /// 成功回调
  /// Success callback
  final void Function(T? data)? onSuccess;

  /// 错误回调
  /// Error callback
  final void Function(Object e, String message)? onError;

  /// 完成回调（无论成功或失败都会执行）
  /// Finally callback (executed regardless of success or failure)
  final void Function()? onFinally;

  /// 是否需要重新抛出异常
  /// Whether to rethrow exceptions
  final bool needRethrow;

  /// 是否显示加载提示
  /// Whether to show loading prompt
  final bool showLoading;

  /// 是否显示错误提示
  /// Whether to show error prompt
  final bool showError;

  /// 加载提示文本
  /// Loading prompt text
  final String? loadingText;

  /// 自定义成功检查
  /// Custom success check
  final bool Function(T? data)? successCheck;

  /// 自定义数据检查
  /// Custom data check
  final bool Function(T? data)? dataCheck;

  /// 数据是否不能为空
  /// Whether data must not be null
  final bool dataNotNull;

  /// 复制并修改
  /// Copy and modify
  RequestExecutionOptions<T> copyWith({
    void Function(T? data)? onSuccess,
    void Function(Object e, String message)? onError,
    void Function()? onFinally,
    bool? needRethrow,
    bool? showLoading,
    bool? showError,
    String? loadingText,
    bool Function(T? data)? successCheck,
    bool Function(T? data)? dataCheck,
    bool? dataNotNull,
  }) {
    return RequestExecutionOptions<T>(
      onSuccess: onSuccess ?? this.onSuccess,
      onError: onError ?? this.onError,
      onFinally: onFinally ?? this.onFinally,
      needRethrow: needRethrow ?? this.needRethrow,
      showLoading: showLoading ?? this.showLoading,
      showError: showError ?? this.showError,
      loadingText: loadingText ?? this.loadingText,
      successCheck: successCheck ?? this.successCheck,
      dataCheck: dataCheck ?? this.dataCheck,
      dataNotNull: dataNotNull ?? this.dataNotNull,
    );
  }
}
