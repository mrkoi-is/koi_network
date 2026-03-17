# Token 自动刷新指南

## 概述

`koi_network` 内置了 token 自动刷新拦截器，提供两层保护：

1. **主动刷新**  
   在请求发出前检查 token 是否即将过期，必要时提前刷新。

2. **被动刷新**  
   当服务端返回认证错误（如 401 / 403）时，自动触发刷新并重试请求。

这套机制默认依赖：

- `KoiAuthAdapter` 提供 token 读写和刷新逻辑
- `KoiJwtTokenMixin` 提供 JWT 到期检测能力
- `KoiTokenRefreshInterceptor` 在请求和错误阶段自动接管刷新流程

---

## 工作流程

### 主动刷新

```text
请求发出前
  -> 检查 token 是否即将过期
  -> 若即将过期，先调用 refresh()
  -> 刷新成功后继续原请求
```

### 被动刷新

```text
请求返回认证错误
  -> 触发 refresh()
  -> 刷新成功后重试原请求
  -> 刷新失败时交给错误处理适配器
```

---

## 1. 实现认证适配器

推荐在 JWT 场景下让认证适配器混入 `KoiJwtTokenMixin`：

```dart
import 'package:koi_network/koi_network.dart';

class DemoAuthAdapter extends KoiAuthAdapter with KoiJwtTokenMixin {
  String? _token;
  String? _refreshToken;

  @override
  String? getToken() => _token;

  @override
  String? getRefreshToken() => _refreshToken;

  @override
  Future<bool> refresh() async {
    try {
      final dio = KoiDioFactory.createTokenDio(null);
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': getRefreshToken()},
      );

      final accessToken = response.data['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }

      await saveToken(accessToken);
      return true;
    } catch (_) {
      return false;
    }
  }

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
```

---

## 2. 注册适配器并初始化

先注册适配器，再初始化网络层。

如果你只需要默认的刷新阈值，可以直接使用 `initialize`：

```dart
KoiNetworkAdapters.register(
  authAdapter: DemoAuthAdapter(),
  errorHandlerAdapter: DemoErrorHandler(),
  loadingAdapter: DemoLoadingAdapter(),
  platformAdapter: KoiDefaultPlatformAdapter(),
);

await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api.example.com',
  enableProactiveTokenRefresh: true,
  tokenRefreshWhiteList: ['/auth/login', '/auth/refresh'],
);
```

如果你需要自定义刷新阈值，使用配置对象：

```dart
final config = KoiNetworkConfig.create(
  baseUrl: 'https://api.example.com',
  enableProactiveTokenRefresh: true,
  tokenRefreshThreshold: const Duration(minutes: 10),
  tokenRefreshWhiteList: ['/auth/login', '/auth/refresh'],
);

await KoiNetworkInitializer.initializeWithConfig(config);
```

---

## 3. 使用方式

初始化完成后，请求层不需要额外处理 refresh：

```dart
final user = await KoiRequestExecutor.execute<Map<String, dynamic>>(
  request: () => dio.get('/user/profile'),
);
```

如果 token 即将过期，拦截器会在请求发出前自动刷新。
如果服务端返回认证错误，拦截器会尝试刷新并重试请求。

---

## 4. `KoiJwtTokenMixin` 提供的能力

`KoiJwtTokenMixin` 当前提供以下公开方法：

```dart
final expired = adapter.isTokenExpired();
final expiringSoon = adapter.isTokenExpiringSoon();
final expiration = adapter.getTokenExpiration();
```

如果你想自己计算剩余有效时间，可以这样写：

```dart
final expiration = adapter.getTokenExpiration();
final remaining = expiration?.difference(DateTime.now().toUtc());
```

---

## 5. 非 JWT 场景

当前**主动刷新**依赖 `KoiJwtTokenMixin` 的过期检测能力。

这意味着：

- 如果你使用 JWT，推荐直接混入 `KoiJwtTokenMixin`
- 如果你不使用 JWT，仍然可以保留**被动刷新**
- 如果你不使用 JWT，建议关闭主动刷新，避免无意义的前置检测

```dart
final config = KoiNetworkConfig.create(
  baseUrl: 'https://api.example.com',
  enableProactiveTokenRefresh: false,
);
```

---

## 6. 最佳实践

1. 在 `refresh()` 中始终使用 `KoiDioFactory.createTokenDio(null)`，避免刷新请求再次进入完整拦截器链。
2. 将登录、刷新接口加入 `tokenRefreshWhiteList`。
3. 对 JWT 场景优先使用 `KoiJwtTokenMixin`。
4. 刷新失败时返回 `false`，让拦截器进入统一错误处理流程。
5. 在 `KoiErrorHandlerAdapter.handleAuthError()` 中实现登出、跳转登录页等全局动作。

---

## 常见问题

### 刷新失败会发生什么？

主动刷新失败时，请求会继续执行；如果后续返回认证错误，被动刷新会再次兜底。
如果被动刷新仍失败，错误会交给 `KoiErrorHandlerAdapter.handleAuthError()`。

### 并发请求如何处理？

刷新期间，后续需要 token 的请求会等待刷新结果，刷新成功后统一继续或重试。

### 为什么要单独使用 token Dio？

因为刷新请求不应该再次进入完整的认证、刷新和错误处理链，否则容易形成循环依赖。

