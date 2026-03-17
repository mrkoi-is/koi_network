/// 强类型响应接口。
/// Interface for strongly typed response wrappers.
///
/// 用于桥接预编译的强类型响应模型，例如 Retrofit 生成的 `BaseResult<T>`。
/// Bridges precompiled typed response models, such as Retrofit-generated
/// `BaseResult<T>`.
///
/// 项目侧的 `BaseResult` 只需实现此接口，即可无缝接入 `KoiTypedRequestExecutor`。
/// A project-specific `BaseResult` only needs to implement this interface to
/// work seamlessly with `KoiTypedRequestExecutor`.
///
/// ## 使用示例 / Usage Example
///
/// ```dart
/// // 项目端已有的 BaseResult，只需加上 implements
/// // The project's existing BaseResult, simply add implements
/// @JsonSerializable(genericArgumentFactories: true)
/// class BaseResult<T> implements KoiTypedResponse<T> {
///   BaseResult(this.code, this.message, this.data);
///
///   @override
///   final int? code;
///
///   @override
///   final String? message;
///
///   @override
///   final T? data;
///
///   @override
///   bool get isSuccess => code == 200 || code == 0;
/// }
/// ```
abstract class KoiTypedResponse<T> {
  /// 请求在业务层是否成功。
  /// Whether the request is successful at the business layer.
  bool get isSuccess;

  /// 业务错误码，可选。
  /// Business error code, if available.
  int? get code;

  /// 业务错误消息，可选。
  /// Business error message, if available.
  String? get message;

  /// 实际业务数据。
  /// Actual business payload.
  T? get data;
}
