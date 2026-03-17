import 'package:dio/dio.dart';
import 'package:dio/io.dart' show IOHttpClientAdapter;

import 'package:koi_network/src/config/network_config.dart';

/// 为当前平台创建 [HttpClientAdapter]。
/// Creates an [HttpClientAdapter] for the current platform.
///
/// 在原生平台 (iOS, Android, macOS 等) 上，返回配置了 SSL 和连接设置的 [IOHttpClientAdapter]。
/// On native platforms (iOS, Android, macOS, etc.), this returns an
/// [IOHttpClientAdapter] with SSL and connection settings.
///
/// 在 Web 平台上，返回 `null` (Dio 使用其默认的浏览器适配器)。
/// On web, this returns `null` (Dio uses its default browser adapter).
HttpClientAdapter? createPlatformAdapter(KoiNetworkConfig config) {
  // Web platform: no custom adapter needed, Dio uses BrowserHttpClientAdapter
  // Web 平台：不需要自定义适配器，Dio 使用内置的 BrowserHttpClientAdapter
  return null;
}
