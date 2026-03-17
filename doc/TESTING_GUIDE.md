# Koi Network 测试指南

`koi_network` 是一个 **Dart package**，测试命令以 `dart test` 为主。
如果你在 Flutter 工程中开发这个包，也可以使用 `flutter test`，但对当前仓库而言，
推荐始终以 Dart 包流程为准。

---

## 覆盖范围

当前测试主要覆盖这些模块：

- `utils/`：JWT 解析工具
- `adapters/`：认证、加载、错误处理、日志、请求编码、响应解析
- `interceptors/`：认证、token 刷新、错误处理
- `core/`：初始化、Dio 工厂、服务管理器
- `executors/`：动态请求执行器、强类型请求执行器
- `mixins/`：`KoiNetworkRequestMixin`

除了按目录组织的测试外，仓库还包含若干覆盖补强文件，用于补齐关键分支逻辑。

---

## 快速开始

### 安装依赖

```bash
cd /path/to/koi_network
dart pub get
```

### 运行全部测试

```bash
dart test
```

### 运行单个测试文件

```bash
dart test test/utils/jwt_decoder_test.dart
dart test test/interceptors/token_refresh_interceptor_test.dart
dart test test/executors/request_executor_test.dart
dart test test/typed_request_executor_test.dart
```

### 生成覆盖率

```bash
dart test --coverage=coverage
```

如果本地安装了 `lcov`，可以继续生成 HTML 报告：

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 依赖与工具

当前测试依赖位于 `pubspec.yaml`：

```yaml
dev_dependencies:
  fake_async: ^1.3.0
  http_mock_adapter: ^0.6.0
  mocktail: ^1.0.0
  test: any
  very_good_analysis: ^7.0.0
```

说明：

- `test`：Dart 官方测试框架
- `mocktail`：Mock 与行为校验
- `fake_async`：时间推进与异步控制
- `http_mock_adapter`：Dio 请求 mock

---

## 常见测试模式

### 1. Mock 依赖

```dart
class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

setUpAll(() {
  registerFallbackValue(FakeRequestOptions());
});
```

### 2. Arrange / Act / Assert

```dart
test('should return parsed user when request succeeds', () async {
  // Arrange
  when(() => mockAuthAdapter.getToken()).thenReturn('test_token');

  // Act
  final result = await subject.loadUser();

  // Assert
  expect(result, isNotNull);
  verify(() => mockAuthAdapter.getToken()).called(1);
});
```

### 3. 测试异步逻辑

```dart
test('should complete refresh successfully', () async {
  final result = await adapter.refresh();
  expect(result, isTrue);
});
```

---

## 编写新测试的建议

1. 优先覆盖公开 API 和关键分支逻辑。
2. 对拦截器类同时覆盖成功路径、失败路径和并发路径。
3. 对执行器类同时覆盖：
   - 成功返回
   - 业务失败
   - 空数据
   - 自定义 `successCheck`
   - 自定义 `dataCheck`
4. 对配置类覆盖边界值和默认值。
5. 需要时间推进时优先使用 `fake_async`，不要依赖真实等待。

---

## 常见问题

### 测试运行失败，提示找不到依赖

先执行：

```bash
dart pub get
```

### Mock 对象报 `Missing stub`

为对应方法提供 `when(...).thenReturn(...)` 或 `thenAnswer(...)`。

### 如何只跑一个测试名称

```bash
dart test --plain-name "token refresh"
```

---

## 参考资料

- [Dart test package](https://pub.dev/packages/test)
- [Mocktail](https://pub.dev/packages/mocktail)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [测试目录说明](../test/README.md)
