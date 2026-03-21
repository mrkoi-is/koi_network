简体中文 | [English](README.md)

# Koi Network

[![pub package](https://img.shields.io/pub/v/koi_network.svg)](https://pub.dev/packages/koi_network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

基于 Dio 的灵活网络请求库，适用于 Dart 和 Flutter 项目。

`koi_network` 提供可复用的网络层：基于适配器的集成架构、可配置的响应解析、
请求执行辅助器、Token 刷新、重试、缓存，以及多模块 Dio 管理。

## 为什么选择 Koi Network

许多项目需要相同的网络能力，但不希望将网络层绑定到特定的 UI 框架、
状态管理方案或后端响应格式。

`koi_network` 通过将基础设施与项目特定逻辑分离来解决这个问题：

- 基于适配器的认证、加载、错误处理、平台、日志、解析和请求编码
- 兼容自定义响应信封格式，如 `{code, msg, data}` 或其他后端格式
- 内置请求执行模式：普通、静默、快速、批量和重试
- 支持主动和被动 Token 刷新
- 通过 Dio 中间件可选支持重试和缓存
- 同时支持原始 Dio 响应和已类型化的 API 包装器

## 安装

在你的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  koi_network: ^0.0.1
```

然后安装依赖：

```bash
dart pub get
```

如果使用 Flutter，`flutter pub get` 同样可用。

## 最小配置

最简设置只需三步：

1. 注册适配器
2. 初始化网络层
3. 获取 Dio 实例并发起请求

```dart
import 'package:koi_network/koi_network.dart';

Future<void> setupNetwork() async {
  KoiNetworkAdapters.register(
    authAdapter: KoiDefaultAuthAdapter(),
    errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
    loadingAdapter: KoiDefaultLoadingAdapter(),
    platformAdapter: KoiDefaultPlatformAdapter(),
    loggerAdapter: KoiDefaultLoggerAdapter(),
  );

  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://api.example.com',
    environment: 'development',
  );
}
```

初始化完成后：

```dart
final dio = KoiNetworkServiceManager.instance.mainDio;

final profile = await KoiRequestExecutor.execute<Map<String, dynamic>>(
  request: () => dio.get('/user/profile'),
);
```

## 自定义适配器

在实际项目中，通常需要用应用实现替换默认适配器。

JWT 认证适配器示例：

```dart
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

class MyAuthAdapter extends KoiAuthAdapter with KoiJwtTokenMixin {
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

class MyErrorHandler extends KoiErrorHandlerAdapter {
  @override
  void showError(String message) {
    print('Error: $message');
  }

  @override
  Future<bool> handleAuthError({int? statusCode, String? message}) async {
    // 例如：清除会话并跳转到登录页
    return true;
  }

  @override
  String formatErrorMessage(DioException error) {
    return error.message ?? error.toString();
  }
}
```

## 请求执行

`KoiRequestExecutor` 是标准 Dio 请求的主要入口。

### 解析 JSON 为模型

```dart
final user = await KoiRequestExecutor.execute<User>(
  request: () => dio.get('/user/profile'),
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

### 静默请求

```dart
final settings = await KoiRequestExecutor.executeSilent<Map<String, dynamic>>(
  request: () => dio.get('/settings'),
);
```

### 快速请求

```dart
final notifications = await KoiRequestExecutor.executeQuick<List<dynamic>>(
  request: () => dio.get('/notifications'),
);
```

### 批量请求

```dart
final results = await KoiRequestExecutor.executeBatch<Map<String, dynamic>>(
  [
    () => dio.get('/user/profile'),
    () => dio.get('/user/permissions'),
    () => dio.get('/dashboard'),
  ],
  options: const BatchRequestOptions(
    concurrent: true,
    showLoading: true,
  ),
);
```

### 应用层重试

```dart
final criticalData = await KoiRequestExecutor.executeWithRetry<MyData>(
  request: () => dio.get('/critical-data'),
  fromJson: (json) => MyData.fromJson(json as Map<String, dynamic>),
  maxRetries: 3,
  delay: const Duration(seconds: 2),
);
```

## 使用 Mixin

对于需要频繁发起请求的控制器或业务类，
`KoiNetworkRequestMixin` 提供了更简洁的 API。

```dart
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

class UserController with KoiNetworkRequestMixin {
  UserController(this._dio);

  final Dio _dio;

  Future<void> loadProfile() async {
    await universalRequest<Map<String, dynamic>>(
      request: () => _dio.get('/user/profile'),
      onSuccess: (data) => print('Profile: $data'),
    );
  }
}
```

常用辅助方法：

- `universalRequest`
- `silentRequest`
- `quickRequest`
- `batchRequest`
- `retryRequest`

## 类型化响应支持

如果你的 API 层已经返回类型化响应包装器，实现
`KoiTypedResponse<T>` 并使用 `KoiTypedRequestExecutor`。

```dart
class BaseResult<T> implements KoiTypedResponse<T> {
  BaseResult({
    required this.code,
    required this.message,
    required this.data,
  });

  @override
  final int? code;

  @override
  final String? message;

  @override
  final T? data;

  @override
  bool get isSuccess => code == 200 || code == 0;
}
```

```dart
final user = await KoiTypedRequestExecutor.execute<User>(
  request: () => userApi.getProfile(),
);
```

## Token 刷新

`koi_network` 支持两种刷新路径：

- 主动刷新：在 Token 过期前刷新
- 被动刷新：在认证失败后刷新

推荐的 JWT 配置：

- 实现 `KoiAuthAdapter`
- 混入 `KoiJwtTokenMixin`
- 在 `refresh()` 中使用 `KoiDioFactory.createTokenDio(null)`
- 将登录和刷新端点添加到 `tokenRefreshWhiteList`

示例：

```dart
await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api.example.com',
  enableProactiveTokenRefresh: true,
  tokenRefreshWhiteList: ['/auth/login', '/auth/refresh'],
);
```

## 多模块支持

你可以在同一应用中初始化多个后端模块。

```dart
await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api-common.example.com',
  key: 'main',
);

await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api-orders.example.com',
  key: 'orders',
);

final ordersDio =
    KoiNetworkServiceManager.instance.getModuleDio('orders');
```

## 配合 Retrofit / Swagger 使用

`koi_network` 定位为基础设施层 — 它**不负责**生成 API 客户端。
如需类型安全的端点定义，请搭配 [retrofit](https://pub.dev/packages/retrofit)
以及可选的 Swagger/OpenAPI 代码生成器使用。

### 推荐架构

```
Swagger/OpenAPI 文档
       ↓  (代码生成)
┌──────────────────────┐
│  API Client 层       │  ← LoginApi, OrderApi (Retrofit 注解)
│  ApiClient 聚合      │  ← 将所有 API 汇聚到一个入口
├──────────────────────┤
│  koi_network         │  ← Dio 管理, 拦截器, Token 刷新,
│                      │     KoiTypedRequestExecutor
├──────────────────────┤
│  Dio                 │  ← HTTP 传输
└──────────────────────┘
```

### 第一步：定义 Retrofit API

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api.g.dart';

@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;

  @GET('/api/v1/user/profile')
  Future<BaseResult<UserProfile>> getProfile();

  @POST('/api/v1/user/update')
  Future<BaseResult<bool>> updateProfile(@Body() UpdateProfileRequest req);
}
```

### 第二步：创建 API Client 聚合

```dart
class MyApiClient {
  MyApiClient(Dio dio)
      : user = UserApi(dio),
        order = OrderApi(dio);

  final UserApi user;
  final OrderApi order;
}
```

### 第三步：接入 koi_network

```dart
final dio = KoiNetworkServiceManager.instance.mainDio;
final api = MyApiClient(dio);

// 使用 KoiTypedRequestExecutor 自动处理错误
final profile = await KoiTypedRequestExecutor.execute<UserProfile>(
  request: () => api.user.getProfile(),
);
```

### Swagger / OpenAPI 代码生成

如果你的后端提供 Swagger 文档，可以使用代码生成器
自动创建 Retrofit API 类和模型文件：

```bash
# 使用 swagger_generator_flutter 的示例
dart run swagger_generator_flutter generate --all
flutter pub run build_runner build --delete-conflicting-outputs
```

生成的文件通常输出到：
- `lib/api/` — Retrofit API 接口
- `lib/api_models/` — 请求/响应模型类

> **提示：** `koi_network` 与生成器完全解耦。
> 你可以更换生成器、手写 API 或混合使用 — Dio 实例和请求执行器的用法不变。

## 主要公共 API

- `KoiNetworkAdapters`
- `KoiNetworkInitializer`
- `KoiNetworkServiceManager`
- `KoiRequestExecutor`
- `KoiTypedRequestExecutor`
- `KoiNetworkRequestMixin`
- `KoiNetworkConfig`
- `KoiAuthAdapter`
- `KoiResponseParser`
- `KoiRequestEncoder`

## 文档

- [快速开始](doc/QUICK_START.md)
- [使用示例](doc/USAGE_EXAMPLE.md)
- [Token 刷新指南](doc/TOKEN_REFRESH_GUIDE.md)
- [测试指南](doc/TESTING_GUIDE.md)
- [技术栈](doc/TECH_STACK.md)
- [更新日志](CHANGELOG.md)

## 许可证

MIT. 详见 [LICENSE](LICENSE)。
