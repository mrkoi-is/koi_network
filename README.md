# Koi Network

[![pub package](https://img.shields.io/pub/v/koi_network.svg)](https://pub.dev/packages/koi_network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A flexible Dio-based networking library for Dart and Flutter projects.

`koi_network` provides a reusable network layer with adapter-based integration,
configurable response parsing, request execution helpers, token refresh,
retry, caching, and multi-module Dio management.

## Why Koi Network

Many projects need the same network capabilities, but do not want to bind the
network layer to a specific UI framework, state management solution, or backend
response format.

`koi_network` solves that by separating infrastructure from project-specific
logic:

- Adapter-based auth, loading, error handling, platform, logging, parsing, and request encoding
- Works with custom response envelopes such as `{code, msg, data}` or other backend formats
- Built-in request execution patterns for normal, silent, quick, batch, and retry flows
- Proactive and reactive token refresh support
- Optional retry and cache support through Dio middleware
- Support for both raw Dio responses and already typed API wrappers

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  koi_network: ^0.0.1
```

Then install dependencies:

```bash
dart pub get
```

If you use Flutter, `flutter pub get` also works.

## Minimal Setup

The smallest working setup is:

1. Register adapters
2. Initialize the network layer
3. Get a Dio instance and make requests

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

After initialization:

```dart
final dio = KoiNetworkServiceManager.instance.mainDio;

final profile = await KoiRequestExecutor.execute<Map<String, dynamic>>(
  request: () => dio.get('/user/profile'),
);
```

## Custom Adapters

In real projects, you usually replace the default adapters with application
implementations.

Example auth adapter with JWT support:

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
    // For example: clear session and redirect to login
    return true;
  }

  @override
  String formatErrorMessage(DioException error) {
    return error.message ?? error.toString();
  }
}
```

## Request Execution

`KoiRequestExecutor` is the main entry point for standard Dio requests.

### Parse JSON into a model

```dart
final user = await KoiRequestExecutor.execute<User>(
  request: () => dio.get('/user/profile'),
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

### Silent request

```dart
final settings = await KoiRequestExecutor.executeSilent<Map<String, dynamic>>(
  request: () => dio.get('/settings'),
);
```

### Quick request

```dart
final notifications = await KoiRequestExecutor.executeQuick<List<dynamic>>(
  request: () => dio.get('/notifications'),
);
```

### Batch request

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

### Retry at the application layer

```dart
final criticalData = await KoiRequestExecutor.executeWithRetry<MyData>(
  request: () => dio.get('/critical-data'),
  fromJson: (json) => MyData.fromJson(json as Map<String, dynamic>),
  maxRetries: 3,
  delay: const Duration(seconds: 2),
);
```

## Use the Mixin

For controllers or business classes that repeatedly issue requests,
`KoiNetworkRequestMixin` provides a simpler API.

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

Common helpers:

- `universalRequest`
- `silentRequest`
- `quickRequest`
- `batchRequest`
- `retryRequest`

## Typed Response Support

If your API layer already returns typed response wrappers, implement
`KoiTypedResponse<T>` and use `KoiTypedRequestExecutor`.

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

## Token Refresh

`koi_network` supports two refresh paths:

- Proactive refresh before token expiration
- Reactive refresh after authentication failures

Recommended JWT setup:

- implement `KoiAuthAdapter`
- mix in `KoiJwtTokenMixin`
- use `KoiDioFactory.createTokenDio(null)` inside `refresh()`
- add login and refresh endpoints to `tokenRefreshWhiteList`

Example:

```dart
await KoiNetworkInitializer.initialize(
  baseUrl: 'https://api.example.com',
  enableProactiveTokenRefresh: true,
  tokenRefreshWhiteList: ['/auth/login', '/auth/refresh'],
);
```

## Multi-Module Support

You can initialize more than one backend module in the same app.

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

## Main Public APIs

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

## Documentation

- [Quick Start](doc/QUICK_START.md)
- [Usage Examples](doc/USAGE_EXAMPLE.md)
- [Token Refresh Guide](doc/TOKEN_REFRESH_GUIDE.md)
- [Testing Guide](doc/TESTING_GUIDE.md)
- [Tech Stack](doc/TECH_STACK.md)
- [Changelog](CHANGELOG.md)

## License

MIT. See [LICENSE](LICENSE).
