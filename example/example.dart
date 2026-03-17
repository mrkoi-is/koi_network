import 'package:koi_network/koi_network.dart';

void main() async {
  print('========================');
  print(' Koi Network 示例程序');
  print('========================\n');

  // 1. 注册核心功能适配器
  // 在实际项目中，你应该实现自己的适配器来连接项目的 UI 和底层存储
  KoiNetworkAdapters.register(
    authAdapter: KoiDefaultAuthAdapter(),
    errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
    loadingAdapter: KoiDefaultLoadingAdapter(),
    platformAdapter: KoiDefaultPlatformAdapter(),
    loggerAdapter: KoiDefaultLoggerAdapter(),
    // 覆盖默认的 ResponseParser 以适配 JSONPlaceholder 的格式 (它直接返回数据)
    responseParser: _JsonPlaceholderParser(),
  );

  // 2. 初始化网络配置
  await KoiNetworkInitializer.initialize(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    environment: 'development',
  );

  final dio = KoiNetworkServiceManager.instance.mainDio;

  // 3. 执行简单的 GET 请求
  try {
    print('发起请求: GET /users/1');

    final result = await KoiRequestExecutor.execute<Map<String, dynamic>>(
      request: () => dio.get('/users/1'),
    );

    if (result != null) {
      print('\n请求成功！');
      print('用户名称: ${result['name']}');
      print('用户邮箱: ${result['email']}');
    }
  } catch (e) {
    print('\n发生错误: $e');
  }

  // 4. 展示拦截器功能 (例如无效端点)
  try {
    print('\n发起错误请求: GET /invalid-endpoint');
    await KoiRequestExecutor.execute<dynamic>(
      request: () => dio.get('/invalid-endpoint'),
      options: RequestExecutionOptions<dynamic>(
        showError: true, // 允许适配器打印错误
      ),
    );
  } catch (e) {
    // 错误已经被适配器拦截并打印，这里主要捕获并防止程序崩溃
  }
}

/// 自定义响应解析器适配 JSONPlaceholder
class _JsonPlaceholderParser implements KoiResponseParser {
  @override
  bool isSuccess(Map<String, dynamic> response) {
    // JSONPlaceholder 只要返回 MAP 就是成功的业务实体
    return true;
  }

  @override
  dynamic getData(Map<String, dynamic> response) {
    return response; // 整个 Map 就是数据
  }

  @override
  int getCode(Map<String, dynamic> response) {
    return 200; // 模拟永远返回成功的业务码
  }

  @override
  String? getMessage(Map<String, dynamic> response) {
    return null;
  }

  @override
  bool isAuthError(int? statusCode, Map<String, dynamic>? response) {
    return statusCode == 401 || statusCode == 403;
  }
}
