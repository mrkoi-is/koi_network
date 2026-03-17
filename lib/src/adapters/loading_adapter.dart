/// Koi 加载提示适配器接口。
/// Interface for loading feedback in Koi Network.
///
/// 用于解耦网络库和项目特定的加载提示逻辑。
/// Decouples the networking layer from project-specific loading UI logic.
abstract class KoiLoadingAdapter {
  /// 显示加载提示。
  /// Shows a loading prompt.
  void showLoading({String? message});

  /// 隐藏加载提示。
  /// Hides the loading prompt.
  void hideLoading();

  /// 显示进度加载，可选，通常用于上传或下载。
  /// Shows progress feedback, typically for uploads or downloads.
  void showProgress({required double progress, String? message}) {}

  /// 隐藏进度加载。
  /// Hides progress feedback.
  void hideProgress() {}

  /// 检查是否正在显示加载提示。
  /// Returns whether a loading prompt is currently shown.
  bool isLoading() => false;
}

/// 默认加载适配器，采用静默模式。
/// Default loading adapter that operates in silent mode.
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
