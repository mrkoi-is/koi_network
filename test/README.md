# YX Network 测试套件

## 📋 测试概览

本测试套件为 `yx_network` 包提供全面的测试覆盖，确保所有核心功能正常工作。

### 测试结构

```
test/
├── utils/
│   └── jwt_decoder_test.dart              # JWT 解析器测试
├── interceptors/
│   ├── auth_interceptor_test.dart         # 认证拦截器测试
│   ├── token_refresh_interceptor_test.dart # Token 刷新拦截器测试（核心）
│   └── error_handling_interceptor_test.dart # 错误处理拦截器测试
├── executors/
│   ├── request_executor_test.dart         # 基础请求执行器测试
│   └── enterprise_request_executor_test.dart # 企业级执行器测试（核心）
├── adapters/
│   ├── auth_adapter_test.dart             # 认证适配器测试
│   ├── error_handler_adapter_test.dart    # 错误处理适配器测试
│   ├── loading_adapter_test.dart          # 加载适配器测试
│   └── logger_adapter_test.dart           # 日志适配器测试
├── core/
│   ├── dio_factory_test.dart              # Dio 工厂测试
│   ├── network_initializer_test.dart      # 网络初始化器测试
│   └── network_service_manager_test.dart  # 服务管理器测试
├── models/
│   ├── base_result_test.dart              # 基础结果模型测试
│   ├── enterprise_config_test.dart        # 企业配置测试
│   └── request_execution_options_test.dart # 请求执行选项测试
├── config/
│   └── network_config_test.dart           # 网络配置测试
└── monitor/
    └── request_monitor_test.dart          # 请求监控测试
```

## 🚀 运行测试

### 运行所有测试

```bash
cd new_architecture/learning_officer_oa/packages/yx_network
flutter test
```

### 运行特定测试文件

```bash
# JWT 解析器测试
flutter test test/utils/jwt_decoder_test.dart

# Token 刷新拦截器测试
flutter test test/interceptors/token_refresh_interceptor_test.dart

# 企业级执行器测试
flutter test test/executors/enterprise_request_executor_test.dart
```

### 运行特定测试组

```bash
# 运行 JWT 解析器的边界情况测试
flutter test test/utils/jwt_decoder_test.dart --plain-name "边界情况和错误处理"

# 运行 Token 刷新的主动刷新测试
flutter test test/interceptors/token_refresh_interceptor_test.dart --plain-name "主动刷新"
```

### 生成测试覆盖率报告

```bash
# 生成覆盖率数据
flutter test --coverage

# 查看覆盖率报告（需要安装 lcov）
# macOS: brew install lcov
# Linux: sudo apt-get install lcov

genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📊 测试优先级

### P0 - 核心功能测试（已完成）

- ✅ **JWT 解析器测试** (`test/utils/jwt_decoder_test.dart`)
  - 基础解析功能
  - 边界情况和错误处理
  - 用户信息提取
  - 过期时间检查

- ✅ **Token 刷新拦截器测试** (`test/interceptors/token_refresh_interceptor_test.dart`)
  - 主动刷新（Token 即将过期时）
  - 被动刷新（401/402 错误时）
  - 并发控制和请求队列
  - 跳过标记机制

- ✅ **企业级执行器测试** (`test/executors/enterprise_request_executor_test.dart`)
  - 请求去重（dedupKey 和 requestTag）
  - 请求取消（单个和批量）
  - 加载状态管理

- ✅ **认证拦截器测试** (`test/interceptors/auth_interceptor_test.dart`)
  - Token 添加到请求头
  - 自定义 header key 和前缀

### P1 - 拦截器和适配器测试（待完成）

- ⏳ 错误处理拦截器测试
- ⏳ Auth 适配器测试（JWT Mixin）
- ⏳ Dio 工厂测试
- ⏳ 网络初始化器测试

### P2 - 模型、配置和监控测试（待完成）

- ⏳ BaseResult 模型测试
- ⏳ 企业配置测试
- ⏳ 网络配置测试
- ⏳ 请求监控测试

## 🧪 测试技术栈

### 测试框架

- **flutter_test**: Flutter 官方测试框架
- **mocktail**: Mock 框架（推荐，语法简洁）
- **fake_async**: 时间控制（用于测试异步和延迟）

### Mock 策略

```dart
// 1. 创建 Mock 类
class MockAuthAdapter extends Mock implements YxAuthAdapter {}

// 2. 注册 Fallback 值（用于 any() 匹配）
setUpAll(() {
  registerFallbackValue(FakeRequestOptions());
});

// 3. 设置 Mock 行为
when(() => mockAuthAdapter.getToken()).thenReturn('test_token');

// 4. 验证调用
verify(() => mockAuthAdapter.getToken()).called(1);
```

## 📝 测试编写规范

### 测试结构

```dart
void main() {
  group('ComponentName', () {
    late MockDependency mockDep;
    late ComponentUnderTest component;
    
    setUp(() {
      // 每个测试前执行
      mockDep = MockDependency();
      component = ComponentUnderTest(mockDep);
    });
    
    tearDown(() {
      // 每个测试后执行（清理资源）
    });
    
    group('methodName', () {
      test('should do something when condition', () {
        // Arrange - 准备测试数据
        when(() => mockDep.method()).thenReturn(value);
        
        // Act - 执行被测试的方法
        final result = component.methodName();
        
        // Assert - 验证结果
        expect(result, expectedValue);
        verify(() => mockDep.method()).called(1);
      });
    });
  });
}
```

### 命名规范

- **测试文件**: `{component_name}_test.dart`
- **测试组**: 使用组件名或功能名
- **测试用例**: 使用 `should {action} when {condition}` 格式（中文项目可用中文）

### 测试覆盖要求

- ✅ 每个公共方法至少 1 个正常场景测试
- ✅ 每个公共方法至少 1 个异常场景测试
- ✅ 关键逻辑需要覆盖所有分支
- ✅ 目标覆盖率：80% 以上

## 🐛 常见问题

### Q: 测试运行失败，提示找不到依赖？

A: 确保已安装测试依赖：

```bash
flutter pub get
```

### Q: Mock 对象报错 "Missing stub"？

A: 需要为 Mock 方法设置返回值：

```dart
when(() => mockAdapter.method()).thenReturn(value);
```

### Q: 如何测试异步方法？

A: 使用 `async/await` 和 `expectLater`：

```dart
test('async method', () async {
  final result = await component.asyncMethod();
  expect(result, expectedValue);
});
```

### Q: 如何测试并发请求？

A: 使用 `Future.wait()`：

```dart
final futures = [
  request1(),
  request2(),
];
final results = await Future.wait(futures);
```

## 📚 参考资料

- [Flutter 测试文档](https://docs.flutter.dev/testing)
- [Mocktail 文档](https://pub.dev/packages/mocktail)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)

## 🎯 下一步计划

1. ✅ 完成 P0 测试（JWT、Token 刷新、企业执行器）
2. ⏳ 完成 P1 测试（其他拦截器、适配器）
3. ⏳ 完成 P2 测试（模型、配置、监控）
4. ⏳ 达到 80% 测试覆盖率
5. ⏳ 集成 CI/CD 自动测试

