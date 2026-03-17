import 'dart:convert';

/// JWT Token 解析工具
/// JWT Token Decoder Utils
///
/// 提供 JWT Token 的解析功能。纯 Dart 实现，不依赖 intl 包。
/// Provides parsing functionality for JWT Tokens. Pure Dart implementation, no dependency on the intl package.
class KoiJwtDecoder {
  /// 解析 JWT Token 获取 payload
  /// Decode JWT Token to get payload
  ///
  /// JWT 格式：header.payload.signature
  /// JWT format: header.payload.signature
  ///
  /// 返回解析后的 payload Map，解析失败返回 null
  /// Returns the decoded payload Map, or null if decoding fails
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = _normalizeBase64(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 获取标准 JWT 过期时间（`exp` 声明，Unix 时间戳秒数）
  /// Get standard JWT expiration time (`exp` claim, Unix timestamp in seconds)
  ///
  /// 这是 [RFC 7519](https://tools.ietf.org/html/rfc7519) 标准的过期字段。
  /// This is the standard expiration field according to [RFC 7519](https://tools.ietf.org/html/rfc7519).
  static DateTime? getExpiration(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    if (exp is String) {
      final parsed = int.tryParse(exp);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
      }
    }
    return null;
  }

  /// 获取自定义过期时间
  /// Get custom expiration time
  ///
  /// 用于非标准 JWT 格式（如自定义日期字段）。
  /// Used for non-standard JWT formats (e.g., custom date fields).
  ///
  /// [claimName] 声明字段名 / Claim field name
  /// [parser] 自定义日期解析回调 / Custom date parsing callback
  static DateTime? getCustomExpiration(
    String token,
    String claimName,
    DateTime Function(String value) parser,
  ) {
    final payload = decode(token);
    if (payload == null) return null;

    final value = payload[claimName];
    if (value is! String) return null;

    try {
      return parser(value);
    } catch (e) {
      return null;
    }
  }

  /// 检查 Token 是否已过期（基于标准 `exp` 声明）
  /// Check if Token has expired (based on standard `exp` claim)
  static bool isExpired(String token) {
    final expiry = getExpiration(token);
    if (expiry == null) return true;
    return DateTime.now().toUtc().isAfter(expiry);
  }

  /// 检查 Token 是否即将过期
  /// Check if Token is expiring soon
  ///
  /// [threshold] 提前多久视为即将过期 / How much in advance to consider it expiring soon
  static bool isExpiringSoon(String token, {Duration? threshold}) {
    final expiry = getExpiration(token);
    if (expiry == null) return true;

    final effectiveThreshold = threshold ?? const Duration(minutes: 5);
    final now = DateTime.now().toUtc();
    return now.isAfter(expiry.subtract(effectiveThreshold));
  }

  /// 获取 Token 签发时间（`iat` 声明）
  /// Get Token issued at time (`iat` claim)
  static DateTime? getIssuedAt(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    final iat = payload['iat'];
    if (iat is int) {
      return DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true);
    }
    if (iat is String) {
      final parsed = int.tryParse(iat);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
      }
    }
    return null;
  }

  /// 获取 Token 中的用户 ID
  /// Get user ID from Token
  ///
  /// 尝试常见的用户 ID 字段：sub, user_id, userId, UserId, uid
  /// Tries common user ID fields: sub, user_id, userId, UserId, uid
  static String? getUserId(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    const candidates = ['sub', 'user_id', 'userId', 'UserId', 'uid'];
    for (final key in candidates) {
      final value = payload[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  /// 获取 Token 中的用户名
  /// Get username from Token
  ///
  /// 尝试常见的用户名字段：name, username, user_name, UserName
  /// Tries common username fields: name, username, user_name, UserName
  static String? getUsername(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    const candidates = ['name', 'username', 'user_name', 'UserName'];
    for (final key in candidates) {
      final value = payload[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  /// 标准化 Base64 字符串（处理 URL-safe Base64 填充）
  /// Normalize Base64 string (handle URL-safe Base64 padding)
  static String _normalizeBase64(String str) {
    var normalized = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
      case 3:
        normalized += '=';
    }
    return normalized;
  }
}
