# Koi Network 技术选型说明

本页解释 `koi_network` 当前依赖栈和设计取舍，重点说明：

- 为什么基于 Dio 构建
- 为什么使用现成的缓存与重试中间件
- 为什么采用适配器架构，而不是把 UI / 日志 / 认证逻辑写死

---

## 当前核心依赖

### 1. `dio` `^5.8.0`

用途：

- 作为底层 HTTP 客户端
- 提供拦截器、超时、取消请求、错误封装等能力

选择原因：

- 生态成熟，文档完善
- 拦截器能力强，适合认证、错误处理、日志和重试扩展
- 在 Dart / Flutter 生态中应用广泛

文档：<https://pub.dev/packages/dio>

---

### 2. `dio_cache_interceptor` `^4.0.5`

用途：

- 为请求提供缓存策略支持
- 统一缓存过期和缓存命中逻辑

当前包内的使用方式：

- 在 `KoiDioFactory` 中按配置启用缓存拦截器
- 默认使用 `MemCacheStore`
- 由 `KoiNetworkConfig.enableCache` 和 `maxCacheSize` 控制

为什么选择它：

- 不需要自己维护缓存策略、过期、清理逻辑
- 能和 Dio 拦截器链自然集成
- 比手写缓存中间层更稳定、更易维护

文档：<https://pub.dev/packages/dio_cache_interceptor>

---

### 3. `dio_smart_retry` `^7.0.1`

用途：

- 自动处理网络层重试
- 统一超时、连接错误和部分服务端错误的重试策略

当前包内的使用方式：

- 在 `KoiDioFactory` 中按配置启用 `RetryInterceptor`
- 重试开关与参数由 `KoiNetworkConfig` 控制

为什么选择它：

- 省去自研重试策略带来的边界条件维护成本
- 与 Dio 拦截器链兼容性好
- 将“网络层重试”和“业务层重试”清晰分离

说明：

- 网络层自动重试由 `dio_smart_retry` 负责
- 应用层业务重试则由 `KoiRequestExecutor.executeWithRetry()` 等 API 提供

文档：<https://pub.dev/packages/dio_smart_retry>

---

### 4. `pretty_dio_logger` `^1.4.0`

用途：

- 在调试环境输出更易读的请求日志

当前包内的使用方式：

- 仅在 `KoiNetworkConfig.enableLogging` 为 `true` 时启用

为什么选择它：

- 对调试阶段很有帮助
- 接入成本低
- 不影响生产环境按需关闭

文档：<https://pub.dev/packages/pretty_dio_logger>

---

## 架构取舍

### 1. 采用适配器架构

`koi_network` 没有把以下逻辑直接写死在库里：

- token 存储
- 错误提示 UI
- loading UI
- 平台信息
- 日志框架

而是通过这些适配器暴露给宿主项目：

- `KoiAuthAdapter`
- `KoiErrorHandlerAdapter`
- `KoiLoadingAdapter`
- `KoiPlatformAdapter`
- `KoiLoggerAdapter`
- `KoiResponseParser`
- `KoiRequestEncoder`

这样做的好处：

- 包本身更通用
- 不依赖具体状态管理框架或 UI 框架
- 更适合在多项目间复用

---

### 2. 统一执行器入口

包里同时提供两类执行器：

- `KoiRequestExecutor`：处理普通 Dio 响应
- `KoiTypedRequestExecutor`：处理已强类型化的响应对象

这样可以兼容两类项目：

- 直接使用 Dio 的项目
- 已使用 Retrofit / OpenAPI 生成代码的项目

---

### 3. 将 token 刷新拆成独立 token Dio

刷新 token 时，包会使用单独的 token Dio 实例，而不是主业务 Dio。

原因：

- 避免 refresh 请求再次走完整认证/刷新链
- 降低循环依赖风险
- 让 refresh 请求路径更清晰、可控

---

## 为什么不做成“一体化网络框架”

`koi_network` 的目标不是替代应用层架构，而是提供一层稳定、可组合的网络基础设施。

因此它不会强制：

- 状态管理方案
- UI 提示方案
- 实体建模方式
- 接口定义工具链

这也是它和很多项目内自用网络封装的核心区别。

---

## 总结

`koi_network` 当前技术选型的核心原则是：

1. **复用成熟组件**，避免重复造轮子
2. **通过适配器解耦宿主项目**
3. **把网络层能力和业务层能力分清楚**
4. **优先保证可维护性和跨项目复用性**

如果你只关心如何接入，优先阅读 [QUICK_START.md](QUICK_START.md)。
如果你想看真实调用方式，继续阅读 [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)。

