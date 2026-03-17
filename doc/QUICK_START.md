# Koi Network 快速开始指南

这份文档面向首次接入 `koi_network` 的开发者，目标是在最少配置下完成：

1. 添加依赖
2. 注册适配器
3. 初始化网络层
4. 发起第一个请求

---

## 1. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  koi_network: ^0.0.1
```

安装依赖：

```bash
dart pub get
```

如果你的项目是 Flutter 应用，也可以使用：

```bash
flutter pub get
```

---

## 2. 实现最小适配器

`koi_network` 通过适配器解耦 UI、日志、认证和平台信息。
首次接入时，至少需要提供：

- `KoiAuthAdapter`
- `KoiErrorHandlerAdapter`
- `KoiLoadingAdapter`
- `KoiPlatformAdapter`

下面是一个最小可运行示例：

```dart
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

class DemoAuthAdapter extends KoiAuthAdapter with KoiJwtTokenMixin {
  String? _token;

  @override
  String? getToken() => _token;

  @override
  Future<bool> refresh() async {
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
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}

class DemoErrorHandler extends KoiErrorHandlerAdapter {
  @override
  void showError(String message) {
    print('Error: $message');
  }

  @override
  Future<bool> handleAuthError({int? statusCode, String? message}) async {
    print('Auth error: $statusCode, $message');
    return true;
  }

  @override
  String formatErrorMessage(DioException error) {
    return error.message ?? error.toString();
  }
}

class DemoLoadingAdapter extends KoiLoadingAdapter {
  @override
  void showLoading({String? message}) {
    print(message ?? 'Loading...');
  }

  @override
  void hideLoading() {
    print('Loading finished');
  }
}
```

`KoiDefaultPlatformAdapter` 和 `KoiDefaultLoggerAdapter` 可以直接复用：

```dart
final platformAdapter = KoiDefaultPlatformAdapter();
final loggerAdapter = KoiDefaultLoggerAdapter();
```

---

## 3. 注册适配器并初始化

在真正发请求之前，先注册适配器，再初始化网络层：

```dart
import 'package:koi_network/koi_network.dart';

Future<void> setupNetwork() async {
  KoiNetworkAdapters.register(
    authAdapter: DemoAuthAdapter(),
    errorHandlerAdapter: DemoErrorHandler(),
    loadingAdapter: DemoLoadingAdapter(),
    platformAdapter: KoiDefaultPlatformAdapter(),
    loggerAdapter: KoiDefaultLoggerAdapter(),
  );

  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://api.example.com',
    environment: 'development',
  );
}
```

如果你需要更细粒度的配置，可以先创建 `KoiNetworkConfig`：

```dart
final config = KoiNetworkConfig.create(
  baseUrl: 'https://api.example.com',
  enableLogging: true,
  enableRetry: true,
  maxRetries: 3,
);

await KoiNetworkInitializer.initializeWithConfig(config);
```

---

## 4. 发起第一个请求

初始化完成后，可以通过 `KoiNetworkServiceManager` 获取 Dio 实例：

```dart
final dio = KoiNetworkServiceManager.instance.mainDio;

final user = await KoiRequestExecutor.execute<Map<String, dynamic>>(
  request: () => dio.get('/user/profile'),
);
```

如果响应不是标准 `Map`，也可以传入 `fromJson`：

```dart
final profile = await KoiRequestExecutor.execute<UserProfile>(
  request: () => dio.get('/user/profile'),
  fromJson: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
);
```

---

## 5. 使用 Mixin 简化调用

如果你希望在业务类里直接复用请求模式，可以使用 `KoiNetworkRequestMixin`：

```dart
class UserController with KoiNetworkRequestMixin {
  Future<void> loadProfile(Dio dio) async {
    await universalRequest<Map<String, dynamic>>(
      request: () => dio.get('/user/profile'),
      onSuccess: (data) => print('Profile loaded: $data'),
    );
  }
}
```

常见模式包括：

- `universalRequest`: 显示 loading，显示错误
- `silentRequest`: 不显示 loading，不显示错误
- `quickRequest`: 不显示 loading，但显示错误
- `batchRequest`: 多请求批量执行
- `retryRequest`: 应用层重试

---

## 6. 多模块初始化

如果应用需要连接多个后端服务，可以用不同的 `key` 初始化多个模块：

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

说明：

- `main` 模块建议先初始化
- 所有模块共享同一个 token Dio
- 每个模块可以拥有不同的 `baseUrl`

---

## 下一步

- 阅读 [../README.md](../README.md) 了解整体能力
- 阅读 [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) 查看完整示例
- 阅读 [TOKEN_REFRESH_GUIDE.md](TOKEN_REFRESH_GUIDE.md) 了解 token 刷新机制
