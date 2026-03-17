/// 请求执行选项。
/// Options that control how a single request is executed.
class RequestExecutionOptions<T> {
  /// 创建请求执行选项。
  /// Creates request execution options.
  ///
  /// - [onSuccess] 成功回调 / Success callback
  /// - [onError] 错误回调 / Error callback
  /// - [onFinally] 完成回调（无论成功或失败） / Callback invoked whether the request succeeds or fails
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

  /// 创建静默请求选项，不显示加载或错误提示。
  /// Creates silent request options without loading or error prompts.
  factory RequestExecutionOptions.silent() {
    return const RequestExecutionOptions(showLoading: false, showError: false);
  }

  /// 创建快速请求选项，不显示加载但会显示错误。
  /// Creates quick request options that hide loading but still show errors.
  factory RequestExecutionOptions.quick() {
    return const RequestExecutionOptions(showLoading: false);
  }

  /// 成功回调。
  /// Callback invoked on success.
  final void Function(T? data)? onSuccess;

  /// 错误回调。
  /// Callback invoked on error.
  final void Function(Object e, String message)? onError;

  /// 完成回调，无论成功或失败都会执行。
  /// Callback invoked regardless of success or failure.
  final void Function()? onFinally;

  /// 是否需要重新抛出异常。
  /// Whether caught exceptions should be rethrown.
  final bool needRethrow;

  /// 是否显示加载提示。
  /// Whether to show a loading prompt.
  final bool showLoading;

  /// 是否显示错误提示。
  /// Whether to show error feedback.
  final bool showError;

  /// 加载提示文本。
  /// Text displayed in the loading prompt.
  final String? loadingText;

  /// 自定义成功检查。
  /// Custom success validator.
  final bool Function(T? data)? successCheck;

  /// 自定义数据检查。
  /// Custom data validator.
  final bool Function(T? data)? dataCheck;

  /// 数据是否不能为空。
  /// Whether the response data must be non-null.
  final bool dataNotNull;

  /// 复制当前配置并覆盖部分字段。
  /// Returns a copy of this configuration with selected fields replaced.
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
