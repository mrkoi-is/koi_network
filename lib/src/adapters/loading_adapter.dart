/// Koi 加载提示适配器接口
/// Koi Loading Prompt Adapter Interface
///
/// 用于解耦网络库和项目特定的加载提示逻辑
/// Used to decouple the network library from project-specific loading prompt logic
abstract class KoiLoadingAdapter {
  /// 显示加载提示
  /// Show loading prompt
  void showLoading({String? message});

  /// 隐藏加载提示
  /// Hide loading prompt
  void hideLoading();

  /// 显示进度加载（可选，用于文件上传/下载）
  /// Show progress loading (optional, used for file upload/download)
  void showProgress({required double progress, String? message}) {}

  /// 隐藏进度加载
  /// Hide progress loading
  void hideProgress() {}

  /// 检查是否正在显示加载提示
  /// Check if the loading prompt is currently being displayed
  bool isLoading() => false;
}

/// 默认的加载适配器（静默模式）
/// Default loading adapter (silent mode)
class KoiDefaultLoadingAdapter implements KoiLoadingAdapter {
  bool _isLoading = false;

  @override
  void showLoading({String? message}) {
    _isLoading = true;
  }

  @override
  void hideLoading() {
    _isLoading = false;
  }

  @override
  void showProgress({required double progress, String? message}) {}

  @override
  void hideProgress() {}

  @override
  bool isLoading() => _isLoading;
}
