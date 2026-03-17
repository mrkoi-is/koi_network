import 'package:koi_network/src/utils/jwt_decoder.dart';

/// Koi 认证适配器接口。
/// Authentication adapter interface for Koi Network.
///
/// 用于解耦网络库与项目侧的认证实现。
/// Decouples the networking layer from project-specific authentication logic.
abstract class KoiAuthAdapter {
  /// 获取当前用户的认证 token。
  /// Returns the current user's authentication token.
  String? getToken();

  /// 获取 refresh token（如果支持）。
  /// Returns the refresh token, if supported.
  String? getRefreshToken() => null;

  /// 刷新并保存 token，由项目侧实现。
  /// Refreshes and persists the token, implemented by the host project.
  ///
  /// 返回刷新是否成功。
  /// Returns whether the refresh succeeded.
  Future<bool> refresh();

  /// 保存认证 token。
  /// Persists the authentication token.
  Future<void> saveToken(String token);

  /// 保存 refresh token（如果支持）。
  /// Persists the refresh token, if supported.
  Future<void> saveRefreshToken(String refreshToken) async {}

  /// 清除认证信息。
  /// Clears authentication state.
  Future<void> clearToken();

  /// 检查当前是否已登录。
  /// Returns whether the current user is logged in.
  bool isLoggedIn() => getToken() != null && getToken()!.isNotEmpty;

  /// 获取用户 ID，可选实现。
  /// Returns the user ID, if available.
  String? getUserId() => null;

  /// 获取用户名，可选实现。
  /// Returns the username, if available.
  String? getUsername() => null;
}

/// JWT token 解析能力 mixin。
/// Mixin that adds JWT token parsing helpers.
///
/// 为 `KoiAuthAdapter` 提供基于 JWT 的过期检测能力。
/// Provides JWT-based expiration checks for `KoiAuthAdapter`.
mixin KoiJwtTokenMixin on KoiAuthAdapter {
  /// 检查 token 是否已过期。
  /// Returns whether the token has expired.
  bool isTokenExpired() {
    final token = getToken();
    if (token == null || token.isEmpty) return true;
    return KoiJwtDecoder.isExpired(token);
  }

  /// 检查 token 是否即将过期，默认提前 5 分钟。
  /// Returns whether the token is expiring soon, defaulting to 5 minutes ahead.
  bool isTokenExpiringSoon({Duration? threshold}) {
    final token = getToken();
    if (token == null || token.isEmpty) return true;
    return KoiJwtDecoder.isExpiringSoon(token, threshold: threshold);
  }

  /// 获取 token 过期时间。
  /// Returns the token expiration time.
  DateTime? getTokenExpiration() {
    final token = getToken();
    if (token == null || token.isEmpty) return null;
    return KoiJwtDecoder.getExpiration(token);
  }
}

/// 默认空实现，适用于测试或无需认证的场景。
/// Default empty implementation for tests or unauthenticated scenarios.
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
