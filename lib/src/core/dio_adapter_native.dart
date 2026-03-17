import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/config/network_config.dart';
import 'package:koi_network/src/koi_network_constants.dart';

/// 为原生平台 (iOS, Android, macOS 等) 创建 [HttpClientAdapter]。
/// Creates an [HttpClientAdapter] for native platforms (iOS, Android, macOS, etc.).
///
/// 配置 SSL 验证、连接池和超时设置。
/// Configures SSL verification, connection pooling, and timeout settings.
HttpClientAdapter? createPlatformAdapter(KoiNetworkConfig config) {
  final httpClient = config.validateCertificate
      ? HttpClient()
      : HttpClient(context: SecurityContext());

  httpClient
    ..maxConnectionsPerHost = config.maxConnectionsPerHost
    ..connectionTimeout = config.connectTimeout
    ..idleTimeout = const Duration(seconds: 30);

  if (!config.validateCertificate) {
    // coverage:ignore-start
    httpClient.badCertificateCallback = (cert, host, port) {
      if (KoiNetworkConstants.debugEnabled) {
        KoiNetworkAdapters.logger.debug(
          '🔓 [SSL] Dev mode: ignoring cert for $host:$port',
        );
      }
      return true;
    };
    // coverage:ignore-end
  }

  return IOHttpClientAdapter(createHttpClient: () => httpClient);
}
