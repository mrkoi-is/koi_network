# Koi Network 快速开始指南

5 分钟快速上手 Koi Network 网络库

---

## 📦 第一步：添加依赖

在你的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  koi_network: ^0.0.1
```

运行：
```bash
flutter pub get
```

---

## 🔧 第二步：实现适配器

在你的应用层（如 `oa_app/lib/adapters/network/`）创建适配器实现。

### 示例：认证适配器

```dart
// oa_app/lib/adapters/network/oa_auth_adapter.dart
import 'package:koi_network/koi_network.dart';
import 'package:oa_core/oa_core.dart';

class OaAuthAdapter extends KoiAuthAdapter with KoiJwtTokenMixin {
  @override
  String? getToken() => UserStore.to.token.value;
  
  @override
  Future<bool> refresh() async {
    // 实现你的 Token 刷新逻辑
    final dio = KoiDioFactory.createTokenDio(null);
    final response = await dio.post('/auth/refresh');
    await saveToken(response.data['access_token']);
    return true;
  }
  
  @override
  String? getRefreshToken() => UserStore.to.refreshToken;
  
  @override
  Future<void> saveToken(String token) async {
    await UserStore.to.setToken(token);
  }
}
```

### 其他适配器

参考 [README.md](README.md#2-实现适配器) 实现其他必需的适配器：
- `OaErrorHandlerAdapter` - 错误处理
- `OaLoadingAdapter` - 加载提示
- `OaPlatformAdapter` - 平台检测
- `OaLoggerAdapter` - 日志记录

---

## 🚀 第三步：注册适配器

在应用层创建适配器注册服务：

```dart
// oa_app/lib/services/network_adapter_registry.dart
import 'package:koi_network/koi_network.dart';
import '../adapters/network/oa_auth_adapter.dart';
import '../adapters/network/oa_error_handler_adapter.dart';
import '../adapters/network/oa_loading_adapter.dart';
import '../adapters/network/oa_platform_adapter.dart';
import '../adapters/network/oa_logger_adapter.dart';

class NetworkAdapterRegistry {
  static void registerAdapters() {
    KoiNetworkAdapters.register(
      authAdapter: OaAuthAdapter(),
      errorHandlerAdapter: OaErrorHandlerAdapter(),
      loadingAdapter: OaLoadingAdapter(),
      platformAdapter: OaPlatformAdapter(),
      loggerAdapter: OaLoggerAdapter(),
    );
    print('✅ 网络适配器注册完成');
  }
}
```

---

## 🎯 第四步：在 main.dart 中初始化

### 单模块应用

```dart
// oa_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:koi_network/koi_network.dart';
import 'services/network_adapter_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 注册网络适配器（必须在初始化网络服务之前）
  NetworkAdapterRegistry.registerAdapters();
  
  // 2. 初始化网络服务
  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://api.example.com',
    environment: 'development',
  );
  
  runApp(MyApp());
}
```

### 多模块应用（推荐）⭐

如果你的应用需要对接多个后端服务：

```dart
// oa_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:oa_core/oa_core.dart';
import 'package:koi_network/koi_network.dart';
import 'services/network_adapter_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 注册网络适配器
  NetworkAdapterRegistry.registerAdapters();
  
  // 2. 初始化多个网络模块
  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://api-common.example.com',
    environment: 'development',
    key: NetworkModuleKeys.main,  // 使用常量，避免硬编码
  );
  
  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://api-module1.example.com',
    environment: 'development',
    key: NetworkModuleKeys.highSchool,
  );
  
  runApp(MyApp());
}
```

> **提示**: 
> - 在 `oa_core/utils/network_constants.dart` 中定义 `NetworkModuleKeys`
> - `main` 模块必须先初始化（用于创建共享 Token Dio）
> - 每个模块可配置不同的 baseUrl


---

## 💡 第五步：在 Controller 中使用

### 方式 1：使用基础 Mixin

```dart
import 'package:get/get.dart';
import 'package:oa_core/oa_core.dart';

class MyController extends GetxController with KoiNetworkRequestMixin {
  Future<void> loadData() async {
    // 通用请求（显示加载、显示错误）
    final data = await universalRequest<MyData>(
      request: () => apiClient.getData(),
      onSuccess: (data) => print('成功: $data'),
    );

    // 静默请求（不显示加载和错误）
    await silentRequest<MyData>(
      request: () => apiClient.getData(),
    );

    // 快速请求（不显示加载，但显示错误）
    await quickRequest<MyData>(
      request: () => apiClient.getData(),
    );
  }
}
```

---

## ✅ 完成！

现在你已经成功集成了 Koi Network。

### 下一步

- 📖 查看 [完整使用示例](USAGE_EXAMPLE.md)
- 🔧 了解 [Token 无感刷新](TOKEN_REFRESH_GUIDE.md)
- 📚 阅读 [技术选型说明](TECH_STACK.md)
