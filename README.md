# Koi Network

Enterprise-grade network library built on Dio with configurable response parsing, request encoding, token refresh, retry, caching, and adapter-based architecture.

[![pub package](https://img.shields.io/pub/v/koi_network.svg)](https://pub.dev/packages/koi_network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **Adapter Architecture** — Decoupled from project-specific dependencies via pluggable adapters
- ✅ **Configurable Response Parsing** — Works with any JSON envelope (`{code,msg,data}`, `{rs,error}`, etc.)
- ✅ **Smart Token Refresh** — Proactive (pre-expiry) + Reactive (on 401) dual protection
- ✅ **Retry & Caching** — Powered by `dio_smart_retry` and `dio_cache_interceptor`
- ✅ **Request Executor** — Unified execute/silent/quick/batch/retry patterns
- ✅ **Type Safety** — Full generics support with optional `fromJson` callbacks
- ✅ **Easy Testing** — Mock-friendly adapter design

## Quick Start

### 1. Add Dependency

```yaml
dependencies:
  koi_network: ^0.2.0
```

### 2. Implement Adapters

```dart
// Auth adapter (supports JWT Token auto-refresh)
class MyAuthAdapter extends KoiAuthAdapter with KoiJwtTokenMixin {
  @override
  String? getToken() => UserStore.to.token;

  @override
  Future<bool> refresh() async {
    final dio = KoiDioFactory.createTokenDio(null);
    final response = await dio.post('/auth/refresh',
      data: {'refresh_token': getRefreshToken()},
    );
    await saveToken(response.data['access_token']);
    return true;
  }

  @override
  Future<void> saveToken(String token) async =>
      UserStore.to.setToken(token);

  @override
  Future<void> clearToken() async => UserStore.to.clearToken();
}

// Error handler adapter
class MyErrorHandler implements KoiErrorHandlerAdapter {
  @override
  void showError(String message) => print('Error: $message');

  @override
  Future<bool> handleAuthError({int? statusCode, String? message}) async {
    // Navigate to login...
    return true;
  }

  @override
  String formatErrorMessage(DioException error) => error.message ?? error.toString();

  @override
  void showSuccess(String message) {}
  @override
  void showWarning(String message) {}
  @override
  void showInfo(String message) {}
}
```

### 3. Register & Initialize

```dart
void main() async {
  // 1. Register adapters
  KoiNetworkAdapters.register(
    authAdapter: MyAuthAdapter(),
    errorHandlerAdapter: MyErrorHandler(),
    loadingAdapter: MyLoadingAdapter(),
    platformAdapter: KoiDefaultPlatformAdapter(),
  );

  // 2. Initialize
  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://api.example.com',
    environment: 'production',
  );

  runApp(MyApp());
}
```

### 4. Make Requests

```dart
// Simple request
final user = await KoiRequestExecutor.execute<User>(
  request: () => dio.get('/user/1'),
  fromJson: (json) => User.fromJson(json),
);

// Silent request (no loading/error UI)
final data = await KoiRequestExecutor.executeSilent<MyData>(
  request: () => dio.get('/data'),
);

// Batch request
final results = await KoiRequestExecutor.executeBatch<Item>(
  [() => dio.get('/item/1'), () => dio.get('/item/2')],
  fromJson: (json) => Item.fromJson(json),
);
```

### 5. Using the Mixin

```dart
class MyController with KoiNetworkRequestMixin {
  Future<void> loadData() async {
    final data = await universalRequest<MyData>(
      request: () => apiClient.getData(),
      onSuccess: (data) => print('Success: $data'),
    );
  }
}
```

## Multi-Module Support

```dart
// Initialize multiple backend modules
await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api-common.example.com',
  key: 'main',
);
await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api-hs.example.com',
  key: 'highSchool',
);

// Access a specific module's Dio
final hsDio = KoiNetworkServiceManager.instance.getModuleDio('highSchool');
```

## Architecture

```
koi_network/
├── adapters/       # Pluggable adapter interfaces
├── config/         # Network configuration
├── core/           # Dio factory & service manager
├── executors/      # Request executor
├── interceptors/   # Auth, token refresh, error handling
├── mixins/         # Controller convenience mixin
├── models/         # Request execution options
└── utils/          # JWT decoder
```

## Documentation

- **[Quick Start](doc/QUICK_START.md)** — 5-minute setup guide
- **[Usage Examples](doc/USAGE_EXAMPLE.md)** — Complete examples
- **[Tech Stack](doc/TECH_STACK.md)** — Technology choices explained
- **[Token Refresh Guide](doc/TOKEN_REFRESH_GUIDE.md)** — Token refresh flow
- **[Testing Guide](doc/TESTING_GUIDE.md)** — Testing best practices

## License

MIT — see [LICENSE](LICENSE) for details.
