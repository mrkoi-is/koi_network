# YX Network 使用示例

## 📋 完整使用流程

### 1. 在 main.dart 中初始化

```dart
import 'package:flutter/material.dart';
import 'package:oa_core/oa_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 OA 网络服务
  await OaNetworkService.initialize(
    baseUrl: 'https://api.example.com',
    environment: 'development', // 或 'production', 'testing'
    customHeaders: {
      'X-Custom-Header': 'value',
    },
  );
  
  runApp(MyApp());
}
```

---

## 🎯 在 Controller 中使用（推荐：Mixin 方式）

> **适用场景**：所有 GetX Controller 中的网络请求

使用 `YxNetworkRequestMixin` 可以让代码更简洁、更具语义化。

```dart
import 'package:get/get.dart';
import 'package:oa_core/oa_core.dart';

class MyController extends GetxController with YxNetworkRequestMixin {
  final RxList<MyData> dataList = <MyData>[].obs;

  /// 通用请求：显示 Loading + 显示错误
  Future<void> loadData() async {
    await universalRequest<List<MyData>>(
      request: () => apiClient.getData(),
      onSuccess: (data) => dataList.value = data ?? [],
    );
  }

  /// 静默请求：不显示 Loading，不显示错误
  /// 适用场景：后台轮询、预加载、非关键数据刷新
  Future<void> refreshInBackground() async {
    await silentRequest<List<MyData>>(
      request: () => apiClient.getData(),
      onSuccess: (data) => dataList.value = data ?? [],
    );
  }

  /// 快速请求：不显示 Loading，但显示错误
  /// 适用场景：下拉刷新、点赞/收藏等快速操作
  Future<void> quickRefresh() async {
    await quickRequest<List<MyData>>(
      request: () => apiClient.getData(),
      onSuccess: (data) => dataList.value = data ?? [],
    );
  }

  /// 批量请求：并发执行多个请求
  /// 适用场景：页面初始化需要同时加载多个数据源
  Future<void> loadMultipleData() async {
    final results = await batchRequest<MyData>(
      [
        () => apiClient.getData1(),
        () => apiClient.getData2(),
        () => apiClient.getData3(),
      ],
      concurrent: true,
      showLoading: true,
    );
    print('批量请求完成: ${results.length} 个结果');
  }

  /// 重试请求：失败后自动重试
  /// 适用场景：关键数据获取、网络不稳定环境
  Future<void> loadWithRetry() async {
    await retryRequest<MyData>(
      request: () => apiClient.getCriticalData(),
      maxRetries: 3,
      delay: Duration(seconds: 2),
      onSuccess: (data) => print('加载成功: $data'),
    );
  }
}
```

### Mixin 方法速查表

| 方法 | Loading | 错误提示 | 适用场景 |
|------|---------|---------|----------|
| `universalRequest` | ✅ | ✅ | 普通表单提交、详情加载 |
| `silentRequest` | ❌ | ❌ | 后台轮询、预加载 |
| `quickRequest` | ❌ | ✅ | 下拉刷新、快速操作 |
| `batchRequest` | ✅ | ✅ | 页面初始化多数据源 |
| `retryRequest` | ✅ | ✅ | 关键数据、弱网环境 |

---

## 🔧 高级用法：直接使用 YxRequestExecutor

> **适用场景**：非 Controller 类（如 Service、Repository）或需要完全自定义配置

```dart
import 'package:yx_network/yx_network.dart';

class MyRepository {
  /// 在非 Controller 中直接使用执行器
  Future<List<MyData>?> fetchData() async {
    return await YxRequestExecutor.execute<List<MyData>>(
      request: () => apiClient.getData(),
      options: RequestExecutionOptions<List<MyData>>(
        showLoading: false,  // Repository 层通常不显示 UI
        showError: false,
        dataNotNull: true,
      ),
    );
  }

  /// 静默获取
  Future<MyData?> getSilently() async {
    return await YxRequestExecutor.executeSilent<MyData>(
      request: () => apiClient.getData(),
    );
  }
}
```

### 何时选择 YxRequestExecutor？

| 场景 | 推荐方式 |
|------|---------|
| Controller 中的请求 | ✅ Mixin |
| Repository / Service 层 | ✅ YxRequestExecutor |
| 需要自定义 Options 的复杂场景 | ✅ YxRequestExecutor |
| 静态工具方法 | ✅ NetworkRequestUtils |

---

## ⚙️ 自定义配置

```dart
final config = YxNetworkConfig.create(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 60),
  enableLogging: true,
  enableRetry: true,
  maxRetries: 3,
  validateCertificate: false, // 开发环境可禁用
);

await OaNetworkService.initializeWithConfig(config);
```

---

## 🎯 最佳实践

1. **Controller 中统一使用 Mixin** - 代码更简洁
2. **Repository 层使用 YxRequestExecutor** - 不关心 UI 反馈
3. **下拉刷新使用 `quickRequest`** - 不需要 Loading 遮罩
4. **后台轮询使用 `silentRequest`** - 完全静默
5. **关键数据使用 `retryRequest`** - 提高成功率

## ⚠️ 注意事项

1. 必须先初始化网络服务才能使用
2. 适配器必须在初始化前注册
3. 生产环境建议启用 SSL 证书验证
