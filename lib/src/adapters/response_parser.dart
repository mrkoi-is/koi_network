/// Koi 响应解析器接口。
/// Interface for backend response parsing in Koi Network.
///
/// 用于解耦网络库和项目特定的后端响应格式。
/// Decouples the library from project-specific backend response formats.
///
/// 每个项目可以根据自身后端格式实现此接口。
/// Each project can implement this interface based on its backend response shape.
///
/// ## 示例 / Example
///
/// ### 标准 {code, msg, data} 格式（默认）:
/// ### Standard {code, msg, data} format (default):
/// ```dart
/// class OaResponseParser implements KoiResponseParser {
///   bool isSuccess(json) => [200, 0].contains(json['code']);
///   String? getMessage(json) => json['msg'] as String?;
///   dynamic getData(json) => json['data'];
///   int getCode(json) => json['code'] as int? ?? -1;
///   bool isAuthError(int? httpStatus, Map<String, dynamic>? body) =>
///       httpStatus == 401 || httpStatus == 403;
/// }
/// ```
///
/// ### TMS {rs, code, error} 格式:
/// ### TMS {rs, code, error} format:
/// ```dart
/// class TmsResponseParser implements KoiResponseParser {
///   bool isSuccess(json) => json['rs'] == true;
///   String? getMessage(json) => json['error'] as String?;
///   dynamic getData(json) => json;
///   int getCode(json) => json['code'] as int? ?? 200;
///   bool isAuthError(int? httpStatus, Map<String, dynamic>? body) =>
///       body?['code'] == 403;
/// }
/// ```
abstract class KoiResponseParser {
  /// 判断响应是否成功。
  /// Returns whether the response indicates success.
  bool isSuccess(Map<String, dynamic> json);

  /// 提取状态码。
  /// Extracts the business status code.
  int getCode(Map<String, dynamic> json);

  /// 提取消息，例如错误消息或成功消息。
  /// Extracts a message, such as an error or success message.
  String? getMessage(Map<String, dynamic> json);

  /// 提取业务数据。
  /// Extracts the payload data.
  dynamic getData(Map<String, dynamic> json);

  /// 判断是否为认证错误，例如 token 过期或权限不足。
  /// Returns whether the response represents an authentication error, such as
  /// an expired token or insufficient permission.
  ///
  /// [httpStatusCode] HTTP 状态码（可能为 null）/ HTTP status code (may be null)
  /// [body] 响应体（可能为 null）/ Response body (may be null)
  bool isAuthError(int? httpStatusCode, Map<String, dynamic>? body);
}

/// 默认响应解析器，适配标准 `{code, msg, data}` 格式。
/// Default parser for the standard `{code, msg, data}` response format.
///
/// 兼容常见的后端响应结构。
/// Compatible with common backend response structures.
/// ```json
/// { "code": 200, "msg": "success", "data": {...} }
/// ```
class KoiDefaultResponseParser implements KoiResponseParser {
  /// 构造函数。
  /// Creates a default response parser.
  ///
  /// [successCodes] 成功状态码列表，默认为 [200, 0]
  /// [successCodes] List of successful status codes, default is [200, 0]
  /// [authErrorHttpCodes] 认证错误 HTTP 状态码列表，默认为 [401, 403]
  /// [authErrorHttpCodes] List of authentication error HTTP status codes, default is [401, 403]
  const KoiDefaultResponseParser({
    this.successCodes = const [200, 0],
    this.authErrorHttpCodes = const [401, 403],
  });

  /// 成功状态码列表。
  /// List of business status codes treated as success.
  final List<int> successCodes;

  /// 认证错误 HTTP 状态码。
  /// HTTP status codes treated as authentication failures.
  final List<int> authErrorHttpCodes;

  @override
  bool isSuccess(Map<String, dynamic> json) {
    final code = json['code'];
    if (code is int) return successCodes.contains(code);
    return false;
  }

  @override
  int getCode(Map<String, dynamic> json) {
    final code = json['code'];
    if (code is int) return code;
    return -1;
  }

  @override
  String? getMessage(Map<String, dynamic> json) {
    return json['msg'] as String? ??
        json['message'] as String? ??
        json['error'] as String?;
  }

  @override
  dynamic getData(Map<String, dynamic> json) {
    return json['data'];
  }

  @override
  bool isAuthError(int? httpStatusCode, Map<String, dynamic>? body) {
    if (httpStatusCode != null && authErrorHttpCodes.contains(httpStatusCode)) {
      return true;
    }
    return false;
  }
}
