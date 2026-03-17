import 'dart:io' show Platform;

/// Koi 平台工具适配器接口。
/// Platform abstraction interface for Koi Network.
///
/// 用于解耦网络库和项目特定的平台检测逻辑。
/// Decouples the library from project-specific platform detection logic.
///
/// 项目端应实现此接口以提供平台信息、应用版本、User-Agent 等。
/// Host applications should implement this interface to provide platform
/// information, app version, User-Agent, and related metadata.
abstract class KoiPlatformAdapter {
  /// 获取平台标识，例如 `ios`、`android`、`web`。
  /// Returns the platform key, such as `ios`, `android`, or `web`.
  String get platform;

  /// 获取平台显示名称，例如 `iOS`、`Android`、`Web`。
  /// Returns the display name of the platform.
  String get platformDisplayName;

  /// 应用版本号，例如 `1.0.0`。
  /// Returns the application version string.
  String get appVersion;

  /// User-Agent 字符串。
  /// Returns the User-Agent string.
  String get userAgent;

  /// 是否为移动平台。
  /// Returns whether the platform is mobile.
  bool get isMobile;

  /// 是否为桌面平台。
  /// Returns whether the platform is desktop.
  bool get isDesktop;

  /// 是否为 Web 平台。
  /// Returns whether the platform is web.
  bool get isWeb;

  /// 获取平台配置信息。
  /// Returns structured platform configuration information.
  Map<String, dynamic> getPlatformConfig();
}

/// 默认的平台适配器，纯 Dart 实现且不依赖 Flutter。
/// Default platform adapter implemented in pure Dart without Flutter dependencies.
///
/// 注意：此实现在 Web 平台不可用，因为 `dart:io` 不支持 Web。
/// Note: this implementation is not available on Web because `dart:io` is not
/// supported there.
///
/// Web 项目应提供自己的 `KoiPlatformAdapter` 实现。
/// Web projects should provide their own `KoiPlatformAdapter` implementation.
class KoiDefaultPlatformAdapter implements KoiPlatformAdapter {
  @override
  String get platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux'; // coverage:ignore-line
    return 'unknown';
  }

  @override
  String get platformDisplayName {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux'; // coverage:ignore-line
    return 'Unknown';
  }

  @override
  String get appVersion => '1.0.0';

  @override
  String get userAgent => 'KoiApp/$appVersion ($platformDisplayName)';

  @override
  bool get isMobile => Platform.isIOS || Platform.isAndroid;

  @override
  bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  bool get isWeb => false;

  @override
  Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': platform,
      'platformName': platformDisplayName,
      'isMobile': isMobile,
      'isDesktop': isDesktop,
      'isWeb': isWeb,
      'version': Platform.operatingSystemVersion,
      'appVersion': appVersion,
    };
  }
}
