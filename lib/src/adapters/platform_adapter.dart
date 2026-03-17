import 'dart:io' show Platform;

/// Koi 平台工具适配器接口
///
/// 用于解耦网络库和项目特定的平台检测逻辑。
/// 项目端应实现此接口以提供平台信息、应用版本、User-Agent 等。
abstract class KoiPlatformAdapter {
  /// 获取平台标识 (如 'ios', 'android', 'web')
  String get platform;

  /// 获取平台显示名称 (如 'iOS', 'Android', 'Web')
  String get platformDisplayName;

  /// 应用版本号 (如 '1.0.0')
  String get appVersion;

  /// User-Agent 字符串
  String get userAgent;

  /// 是否为移动平台
  bool get isMobile;

  /// 是否为桌面平台
  bool get isDesktop;

  /// 是否为Web平台
  bool get isWeb;

  /// 获取平台配置信息
  Map<String, dynamic> getPlatformConfig();
}

/// 默认的平台适配器（纯 Dart，不依赖 Flutter）
///
/// 注意：此实现在 Web 平台不可用（dart:io 在 Web 上不存在）。
/// Web 项目应提供自己的 KoiPlatformAdapter 实现。
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
