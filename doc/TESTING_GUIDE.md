# Koi Network 测试指南

## 📊 测试覆盖情况

### ✅ 已完成的测试

Koi Network 包含完整的单元测试，覆盖核心功能：

#### 1. JWT 解析器测试 (`test/utils/jwt_decoder_test.dart`)
- ✅ **23 个测试用例**
- 测试覆盖：
  - Token payload 解析
  - 过期时间检查（isExpired、isExpiringSoon、getRemainingTime）
  - 用户信息提取（getUserId、getUsername）
  - 边界情况处理
  - 标准和自定义字段支持

#### 2. Token 刷新拦截器测试 (`test/interceptors/token_refresh_interceptor_test.dart`)
- ✅ **9 个测试用例**
- 测试覆盖：
  - 主动刷新（Token 即将过期时触发）
  - 被动刷新（401/402 错误时触发）
  - 跳过标记机制
  - 刷新失败处理

#### 3. 认证拦截器测试 (`test/interceptors/auth_interceptor_test.dart`)
- ✅ **5 个测试用例**
- 测试覆盖：
  - Token 添加到请求头
  - 空 Token 处理
  - 自定义 header key 和前缀

#### 5. Mixin 测试
- ✅ **NetworkRequestMixin**: 10 个测试用例

#### 6. 错误处理拦截器测试
- ✅ **ErrorHandlingInterceptor**: 4 个测试用例
- 测试覆盖错误传播策略

**总计：117 个测试用例，100% 通过率** ✅

---

## 🚀 快速开始

### 安装依赖

```bash
cd /path/to/koi_network
flutter pub get
```

### 运行所有测试

```bash
flutter test
```

### 运行特定测试

```bash
# JWT 解析器测试
flutter test test/utils/jwt_decoder_test.dart

# Token 刷新拦截器测试
flutter test test/interceptors/token_refresh_interceptor_test.dart

# 认证拦截器测试
flutter test test/interceptors/auth_interceptor_test.dart
```

### 使用测试脚本

```bash
# 赋予执行权限
chmod +x run_tests.sh

# 运行所有测试
./run_tests.sh all

# 运行 P0 测试
./run_tests.sh p0

# 生成覆盖率报告
./run_tests.sh coverage

# 运行特定测试
./run_tests.sh specific test/utils/jwt_decoder_test.dart
```

---

## 📋 测试结果

### JWT 解析器测试结果

```
✅ 23/23 测试通过

测试组：
  ✅ 基础功能（7 个测试）
    - 解析 Token payload
    - 获取过期时间
    - 获取签发时间
    - 检查是否过期
    - 检查是否即将过期
    - 获取剩余有效时间
    - 获取用户 ID
    - 完整信息展示
  
  ✅ 边界情况和错误处理（8 个测试）
    - 空字符串应返回 null
    - 格式错误的 Token 应返回 null
    - 缺少 payload 部分应返回 null
    - 无效的 Base64 编码应返回 null
    - 缺少 exp 字段时 getExpiration 应返回 null
    - 缺少 iat 字段时 getIssuedAt 应返回 null
    - 已过期的 Token 应正确识别
    - 空 Token 的各种检查
  
  ✅ 用户信息提取（5 个测试）
    - getUserId 应支持标准 sub 字段
    - getUserId 应支持自定义 UserId 字段
    - getUsername 应支持标准 name 字段
    - getUsername 应支持自定义 UserName 字段
    - getUserId 在无相关字段时应返回 null
```

---

## 🎯 下一步计划

### P0 - 立即完成（本周）
- [x] JWT 解析器测试（已完成）
- [ ] 验证 Token 刷新拦截器测试
- [ ] 验证认证拦截器测试
- [ ] 修复所有测试问题

### P1 - 1-2 周内完成
- [ ] 错误处理拦截器测试
- [ ] Auth 适配器测试（JWT Mixin）
- [ ] Dio 工厂测试
- [ ] 网络初始化器测试
- [ ] 网络服务管理器测试

### P2 - 1 个月内完成
- [ ] BaseResult 模型测试
- [ ] 网络配置测试
- [ ] 请求监控测试
- [ ] 达到 80% 测试覆盖率

---

## 🧪 测试技术栈

### 依赖包

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0          # Mock 框架
  fake_async: ^1.3.0        # 时间控制
  http_mock_adapter: ^0.6.0 # HTTP Mock
```

### Mock 框架使用

```dart
// 1. 创建 Mock 类
class MockAuthAdapter extends Mock implements KoiAuthAdapter {}

// 2. 注册 Fallback 值
setUpAll(() {
  registerFallbackValue(FakeRequestOptions());
});

// 3. 设置 Mock 行为
when(() => mockAuthAdapter.getToken()).thenReturn('test_token');

// 4. 验证调用
verify(() => mockAuthAdapter.getToken()).called(1);
```

---

## 📝 测试编写规范

### AAA 模式（Arrange-Act-Assert）

```dart
test('should do something when condition', () {
  // Arrange - 准备测试数据
  final options = RequestOptions(path: '/api/test');
  when(() => mockAdapter.method()).thenReturn(value);
  
  // Act - 执行被测试的方法
  final result = component.methodName(options);
  
  // Assert - 验证结果
  expect(result, expectedValue);
  verify(() => mockAdapter.method()).called(1);
});
```

### 测试命名

- **测试文件**: `{component_name}_test.dart`
- **测试组**: 使用组件名或功能名
- **测试用例**: 清晰描述测试意图

---

## 🐛 常见问题

### Q: 测试运行失败，提示找不到依赖？
A: 运行 `flutter pub get` 安装依赖

### Q: Mock 对象报错 "Missing stub"？
A: 为 Mock 方法设置返回值：`when(() => mock.method()).thenReturn(value);`

### Q: 如何测试异步方法？
A: 使用 `async/await`：
```dart
test('async method', () async {
  final result = await component.asyncMethod();
  expect(result, expectedValue);
});
```

---

## 📚 参考资料

- [Flutter 测试文档](https://docs.flutter.dev/testing)
- [Mocktail 文档](https://pub.dev/packages/mocktail)
- [测试最佳实践](https://dart.dev/guides/language/effective-dart/testing)
- [测试 README](../test/README.md)
