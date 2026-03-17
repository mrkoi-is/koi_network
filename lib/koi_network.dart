/// Koi Network - 企业级网络请求库
/// Koi Network - Enterprise-grade Networking Library
///
/// 基于 Dio 最佳实践设计，支持可配置的响应解析、请求编码、
/// Token 刷新、重试、缓存和适配器架构。
/// Designed based on Dio best practices, supporting configurable response parsing,
/// request encoding, token refreshing, retries, caching, and an adapter architecture.
///
/// ## 快速开始
/// ## Quick Start
///
/// ```dart
/// // 1. 注册适配器 / Register adapters
/// KoiNetworkAdapters.register(
///   authAdapter: MyAuthAdapter(),
///   errorHandlerAdapter: MyErrorHandler(),
///   loadingAdapter: MyLoadingAdapter(),
///   platformAdapter: MyPlatformAdapter(),
///   responseParser: MyResponseParser(), // 可选 / Optional
///   requestEncoder: KoiJsonRequestEncoder(), // 可选 / Optional
/// );
///
/// // 2. 初始化 / Initialize
/// await KoiNetworkInitializer.initialize(
///   baseUrl: 'https://api.example.com/',
///   environment: 'production',
/// );
///
/// // 3. 使用 / Usage
/// final result = await KoiRequestExecutor.instance.execute(
///   request: () => dio.get('/users'),
/// );
/// ```
library;

// ==================== 第三方导出 / Third-party Exports ====================

// ==================== 适配器 / Adapters ====================
export 'src/adapters/auth_adapter.dart';
export 'src/adapters/error_handler_adapter.dart';
export 'src/adapters/loading_adapter.dart';
export 'src/adapters/logger_adapter.dart';
export 'src/adapters/network_adapters.dart';
export 'src/adapters/platform_adapter.dart';
export 'src/adapters/request_encoder.dart';
export 'src/adapters/response_parser.dart';
// ==================== 配置 / Configuration ====================
export 'src/config/network_config.dart';
// ==================== 核心 / Core ====================
export 'src/core/dio_factory.dart';
export 'src/core/network_initializer.dart';
export 'src/core/network_service_manager.dart';
// ==================== 执行器 / Executors ====================
export 'src/executors/request_executor.dart';
export 'src/executors/typed_request_executor.dart';
// ==================== 拦截器 / Interceptors ====================
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/error_handling_interceptor.dart';
export 'src/interceptors/token_refresh_interceptor.dart';
// ==================== Constants ====================
export 'src/koi_network_constants.dart';
// ==================== Mixin ====================
export 'src/mixins/network_request_mixin.dart';
// ==================== 模型 / Models ====================
export 'src/models/request_execution_options.dart';
export 'src/models/typed_response.dart';
// ==================== 工具 / Utils ====================
export 'src/utils/jwt_decoder.dart';
