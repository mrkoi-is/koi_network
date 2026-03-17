# Token 无感刷新使用指南

## 概述

YX Network 实现了类似 [dio_refresh](https://github.com/iamdipanshusingh/dio_refresh) 的 **双重保护机制**，提供无感知的 Token 刷新体验：

1. **主动刷新（优先）**：在请求发出前检查 Token 是否即将过期，提前刷新（用户完全无感知）
2. **被动刷新（兜底）**：在收到 401/402 错误时触发刷新，作为兜底方案

## 工作原理

### 主动刷新（无感知）

```
用户发起请求
    ↓
TokenRefreshInterceptor.onRequest
    ↓
检查 Token 是否即将过期（默认提前 5 分钟）
    ↓
是 → 主动刷新 Token → 使用新 Token 继续请求
否 → 直接发送请求
```

### 被动刷新（兜底）

```
请求返回 401/402
    ↓
TokenRefreshInterceptor.onError
    ↓
刷新 Token
    ↓
重试原始请求 + 队列中的所有请求
```

## 快速开始

### 1. 创建适配器（使用 JWT Mixin）

```dart
import 'package:yx_network/yx_network.dart';

class MyAuthAdapter extends YxAuthAdapter with YxJwtTokenMixin {
  @override
  String? getToken() {
    return UserStore.to.token.value;
  }

  @override
  String? getRefreshToken() {
    return UserStore.to.refreshToken.value;
  }

  @override
  Future<bool> refresh() async {
    try {
      // 使用 TokenDio 避免循环依赖
      final dio = YxDioFactory.createTokenDio();
      final response = await dio.post('/auth/refresh', data: {
        'refresh_token': getRefreshToken(),
      });

      // 保存新 Token
      await saveToken(response.data['access_token']);
      await saveRefreshToken(response.data['refresh_token']);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    await UserStore.to.setToken(token);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await UserStore.to.setRefreshToken(refreshToken);
  }

  @override
  Future<void> clearToken() async {
    await UserStore.to.clearToken();
  }
}
```

### 2. 配置网络（启用主动刷新）

```dart
final config = YxNetworkConfig.create(
  baseUrl: 'https://api.example.com',
  enableProactiveTokenRefresh: true,  // 启用主动刷新（默认 true）
  tokenRefreshThreshold: const Duration(minutes: 5),  // 提前 5 分钟刷新（默认）
);

await YxNetworkInitializer.initialize(
  config: config,
  authAdapter: MyAuthAdapter(),
  // ... 其他适配器
);
```

### 3. 使用（完全透明）

```dart
// 正常发起请求，Token 会自动刷新
final result = await api.getUserInfo();
```

## JWT Token 解析

`YxJwtTokenMixin` 提供了以下能力：

```dart
// 获取 Token 过期时间（Unix 时间戳）
int? exp = adapter.getTokenExpiration();

// 检查是否已过期
bool expired = adapter.isTokenExpired();

// 检查是否即将过期（默认 5 分钟）
bool expiringSoon = adapter.isTokenExpiringSoon();

// 获取剩余有效时间
Duration? remaining = adapter.getTokenRemainingTime();
```

## 高级配置

### 自定义刷新阈值

```dart
final config = YxNetworkConfig.create(
  tokenRefreshThreshold: const Duration(minutes: 10),  // 提前 10 分钟刷新
);
```

### 禁用主动刷新（仅使用被动刷新）

```dart
final config = YxNetworkConfig.create(
  enableProactiveTokenRefresh: false,  // 禁用主动刷新
);
```

### 非 JWT Token 支持

如果你的项目不使用 JWT Token，可以覆盖相关方法：

```dart
class MyAuthAdapter extends YxAuthAdapter {
  @override
  bool isTokenExpiringSoon({Duration threshold = const Duration(minutes: 5)}) {
    // 自定义过期检查逻辑
    final expiryTime = _getExpiryTimeFromCustomStorage();
    return DateTime.now().add(threshold).isAfter(expiryTime);
  }

  // 不使用 YxJwtTokenMixin
}
```

## 最佳实践

1. **使用 JWT Token**：推荐使用 JWT Token，可以自动解析过期时间
2. **合理设置阈值**：根据业务场景设置合适的刷新阈值（默认 5 分钟）
3. **使用 TokenDio**：在 `refresh()` 方法中使用 `YxDioFactory.createTokenDio()` 避免循环依赖
4. **错误处理**：在 `refresh()` 中捕获异常并返回 false，让被动刷新兜底

## 对比 dio_refresh

| 特性 | YX Network | dio_refresh |
|------|-----------|-------------|
| 主动刷新 | ✅ | ✅ |
| 被动刷新 | ✅ | ✅ |
| JWT 自动解析 | ✅ | ❌ |
| 并发请求队列 | ✅ | ✅ |
| 配置化 | ✅ | ❌ |
| 适配器模式 | ✅ | ❌ |

## 常见问题

### Q: Token 刷新失败怎么办？
A: 主动刷新失败会继续发送请求，如果返回 401，被动刷新会兜底。如果被动刷新也失败，会调用 `ErrorHandlerAdapter.handleAuthError()`。

### Q: 如何调试刷新逻辑？
A: 在开发环境下，拦截器会输出详细日志，包括刷新触发时机、剩余时间等。

### Q: 刷新期间的并发请求如何处理？
A: 所有并发请求会被加入队列，刷新成功后统一使用新 Token 重试。

