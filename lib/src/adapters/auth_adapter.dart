import 'package:koi_network/src/utils/jwt_decoder.dart';

/// Koi 认证适配器接口
/// Koi Authentication Adapter Interface
///
/// 用于解耦网络库和项目特定的认证逻辑
/// Used to decouple the network library from project-specific authentication logic
abstract class KoiAuthAdapter {
  /// 获取当前用户的认证 Token
  /// Get the authentication Token of the current user
  String? getToken();

  /// 获取刷新 Token（如果支持）
  /// Get the refresh Token (if supported)
  String? getRefreshToken() => null;

  /// 刷新并保存 Token（由项目侧实现）。
  /// Refresh and save the Token (implemented by the project side).
  ///
  /// 返回是否刷新成功。
  /// Returns whether the refresh was successful.
  Future<bool> refresh();

  /// 保存认证 Token
  /// Save the authentication Token
  Future<void> saveToken(String token);

  /// 保存刷新 Token（如果支持）
  /// Save the refresh Token (if supported)
  Future<void> saveRefreshToken(String refreshToken) async {}

  /// 清除认证信息
  /// Clear authentication information
  Future<void> clearToken();

  /// 检查是否已登录
  /// Check if the user is logged in
  bool isLoggedIn() => getToken() != null && getToken()!.isNotEmpty;

  /// 获取用户ID（可选）
  /// Get the user ID (optional)
  String? getUserId() => null;

  /// 获取用户名（可选）
  /// Get the username (optional)
  String? getUsername() => null;
}

/// JWT Token 解析能力 Mixin
/// JWT Token parsing capability Mixin
///
/// 为 AuthAdapter 提供基于 JWT 的 Token 过期检测能力
/// Provides JWT-based Token expiration detection capability for AuthAdapter
mixin KoiJwtTokenMixin on KoiAuthAdapter {
  /// 检查 Token 是否已过期
  /// Check if the Token has expired
  bool isTokenExpired() {
    final token = getToken();
    if (token == null || token.isEmpty) return true;
    return KoiJwtDecoder.isExpired(token);
  }

  /// 检查 Token 是否即将过期（默认提前 5 分钟）
  /// Check if the Token is expiring soon (defaults to 5 minutes ahead)
  bool isTokenExpiringSoon({Duration? threshold}) {
    final token = getToken();
    if (token == null || token.isEmpty) return true;
    return KoiJwtDecoder.isExpiringSoon(token, threshold: threshold);
  }

  /// 获取 Token 过期时间
  /// Get the Token expiration time
  DateTime? getTokenExpiration() {
    final token = getToken();
    if (token == null || token.isEmpty) return null;
    return KoiJwtDecoder.getExpiration(token);
  }
}

/// 默认的空实现（用于测试或不需要认证的场景）
/// Default empty implementation (used for testing or scenarios without authentication)
class KoiDefaultAuthAdapter extends KoiAuthAdapter with KoiJwtTokenMixin {
  String? _token;
  String? _refreshToken;

  @override
  String? getToken() => _token;

  @override
  String? getRefreshToken() => _refreshToken;

  @override
  Future<bool> refresh() async => false;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
  }
}
