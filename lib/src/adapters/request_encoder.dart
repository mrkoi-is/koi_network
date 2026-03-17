import 'package:dio/dio.dart';

/// Koi 请求编码器接口
/// Koi Request Encoder Interface
///
/// 控制请求数据如何编码（JSON / FormData / 自定义）。
/// Controls how request data is encoded (JSON / FormData / Custom).
///
/// 每个项目根据自己的后端要求实现此接口。
/// Each project implements this interface based on its backend requirements.
///
/// ## 示例 / Example
///
/// ### JSON 编码（默认，大多数现代 API）:
/// ### JSON Encoding (default, most modern APIs):
/// ```dart
/// final encoder = KoiJsonRequestEncoder();
/// // data → 直接作为 JSON body 发送 / Sent directly as JSON body
/// ```
///
/// ### FormData 编码（传统 API / 文件上传）:
/// ### FormData Encoding (legacy APIs / file uploads):
/// ```dart
/// final encoder = KoiFormDataRequestEncoder();
/// // data → FormData.fromMap(data)
/// ```
abstract class KoiRequestEncoder {
  /// 编码请求数据
  /// Encode request data
  ///
  /// 将 [data] Map 编码为 Dio 可接受的请求体格式。
  /// Encode the [data] Map into a request body format acceptable by Dio.
  ///
  /// 返回值可以是 Map (JSON), FormData, String 等。
  /// The return value can be Map (JSON), FormData, String, etc.
  dynamic encode(Map<String, dynamic> data);

  /// 对应的 Content-Type
  /// Corresponding Content-Type
  String get contentType;
}

/// JSON 编码器（默认）
/// JSON Encoder (Default)
///
/// 将数据作为 JSON body 发送。适用于大多数 RESTful API。
/// Sent data as JSON body. Suitable for most RESTful APIs.
class KoiJsonRequestEncoder implements KoiRequestEncoder {
  /// 创建 JSON 编码器
  /// Create JSON encoder
  const KoiJsonRequestEncoder();

  @override
  dynamic encode(Map<String, dynamic> data) => data;

  @override
  String get contentType => 'application/json';
}

/// FormData 编码器
/// FormData Encoder
///
/// 将数据编码为 `multipart/form-data`。适用于传统 API 或需要文件上传的场景。
/// Encodes data as `multipart/form-data`. Suitable for legacy APIs or scenarios requiring file uploads.
class KoiFormDataRequestEncoder implements KoiRequestEncoder {
  /// 创建 FormData 编码器
  /// Create FormData encoder
  const KoiFormDataRequestEncoder();

  @override
  dynamic encode(Map<String, dynamic> data) => FormData.fromMap(data);

  @override
  String get contentType => 'multipart/form-data';
}

/// URL-encoded 编码器
/// URL-encoded Encoder
///
/// 将数据编码为 `application/x-www-form-urlencoded`。
/// Encodes data as `application/x-www-form-urlencoded`.
class KoiUrlEncodedRequestEncoder implements KoiRequestEncoder {
  /// 创建 URL-encoded 编码器
  /// Create URL-encoded encoder
  const KoiUrlEncodedRequestEncoder();

  @override
  dynamic encode(Map<String, dynamic> data) => data;

  @override
  String get contentType => 'application/x-www-form-urlencoded';
}
