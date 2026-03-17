# Koi Network 使用示例

本页提供几个常见的公开使用场景，所有示例都基于当前真实可用的公开 API。

---

## 1. 初始化网络层

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
    customHeaders: {
      'X-App-Channel': 'debug',
    },
  );
}
```

如果你已经构造好了配置对象，也可以这样初始化：

```dart
final config = KoiNetworkConfig.create(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 60),
  enableLogging: true,
  enableRetry: true,
  maxRetries: 3,
);

await KoiNetworkInitializer.initializeWithConfig(config);
```

---

## 2. 直接使用 `KoiRequestExecutor`

适用场景：

- Repository / Service 层
- 不需要 mixin 的场景
- 需要自定义 `RequestExecutionOptions` 的请求

```dart
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<User?> fetchUser() {
    return KoiRequestExecutor.execute<User>(
      request: () => _dio.get('/user/profile'),
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      options: const RequestExecutionOptions<User>(
        showLoading: false,
      ),
    );
  }

  Future<List<Order>?> fetchOrders() {
    return KoiRequestExecutor.execute<List<Order>>(
      request: () => _dio.get('/orders'),
      fromJson: (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => Order.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
```

---

## 3. 使用 `KoiNetworkRequestMixin`

适用场景：

- 业务控制器
- 需要复用统一请求模式的类
- 希望在业务代码中快速调用 `universalRequest` / `silentRequest`

```dart
import 'package:dio/dio.dart';
import 'package:koi_network/koi_network.dart';

class UserController with KoiNetworkRequestMixin {
  UserController(this._dio);

  final Dio _dio;

  Future<void> loadProfile() async {
    await universalRequest<Map<String, dynamic>>(
      request: () => _dio.get('/user/profile'),
      onSuccess: (data) => print('Profile loaded: $data'),
    );
  }

  Future<void> preloadSettings() async {
    await silentRequest<Map<String, dynamic>>(
      request: () => _dio.get('/settings'),
    );
  }

  Future<void> refreshNotifications() async {
    await quickRequest<List<dynamic>>(
      request: () => _dio.get('/notifications'),
    );
  }
}
```

### 常用方法速查

| 方法 | Loading | 错误提示 | 适用场景 |
|------|---------|----------|----------|
| `universalRequest` | ✅ | ✅ | 普通页面请求、表单提交 |
| `silentRequest` | ❌ | ❌ | 预加载、后台轮询 |
| `quickRequest` | ❌ | ✅ | 下拉刷新、快速操作 |
| `batchRequest` | ✅ | ✅ | 页面首屏并发加载 |
| `retryRequest` | ✅ | ✅ | 关键数据获取 |

---

## 4. 批量请求

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

如果你希望某个请求失败后立即停止，可以设置：

```dart
const BatchRequestOptions(stopOnFirstError: true)
```

---

## 5. 强类型响应

如果你的接口层已经返回强类型结果对象，例如 Retrofit 生成的 `BaseResult<T>`，
可以让该对象实现 `KoiTypedResponse<T>`：

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

然后直接使用 `KoiTypedRequestExecutor`：

```dart
final user = await KoiTypedRequestExecutor.execute<User>(
  request: () => userApi.getProfile(),
);
```

---

## 6. 多模块场景

如果你的应用需要同时连接多个服务：

```dart
await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api-common.example.com',
  key: 'main',
);

await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api-report.example.com',
  key: 'report',
);

final reportDio = KoiNetworkServiceManager.instance.getModuleDio('report');
```

说明：

- `main` 模块建议最先初始化
- token Dio 由主模块创建并共享
- 业务模块使用自己的 `key`

---

## 7. 最佳实践

1. 先注册适配器，再初始化网络层。
2. 页面/控制器场景优先使用 `KoiNetworkRequestMixin`。
3. Repository / Service 场景优先使用 `KoiRequestExecutor`。
4. 对已强类型化的接口，优先使用 `KoiTypedRequestExecutor`。
5. 生产环境建议开启证书校验并谨慎控制日志开关。
