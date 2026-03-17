import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/mixins/network_request_mixin.dart';

/// Test controller that uses the mixin
class _TestController with KoiNetworkRequestMixin {}

void main() {
  late _TestController controller;

  setUp(() {
    KoiNetworkAdapters.registerDefaults();
    controller = _TestController();
  });

  tearDown(() {
    KoiNetworkAdapters.clear();
  });

  Response<dynamic> _successResponse(dynamic data) {
    return Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: {'code': 200, 'msg': 'ok', 'data': data},
    );
  }

  Response<dynamic> _failResponse() {
    return Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: {'code': 500, 'msg': 'error', 'data': null},
    );
  }

  group('KoiNetworkRequestMixin', () {
    test('universalRequest should return data on success', () async {
      final result = await controller.universalRequest<String>(
        request: () async => _successResponse('hello'),
        fromJson: (json) => json.toString(),
        showLoading: false,
        showError: false,
        needRethrow: false,
      );
      expect(result, 'hello');
    });

    test('silentRequest should return data', () async {
      final result = await controller.silentRequest<int>(
        request: () async => _successResponse(42),
        fromJson: (json) => json as int,
      );
      expect(result, 42);
    });

    test('quickRequest should return data', () async {
      final result = await controller.quickRequest<String>(
        request: () async => _successResponse('quick'),
        fromJson: (json) => json.toString(),
      );
      expect(result, 'quick');
    });

    test('batchRequest should return list of results', () async {
      final results = await controller.batchRequest<int>(
        [() async => _successResponse(1), () async => _successResponse(2)],
        fromJson: (json) => json as int,
        showLoading: false,
      );
      expect(results, [1, 2]);
    });

    test('silentRequest should return null on error', () async {
      final result = await controller.silentRequest<String>(
        request: () async => _failResponse(),
      );
      expect(result, isNull);
    });
  });

  group('NetworkRequestUtils', () {
    test('universalRequest should work statically', () async {
      final result = await NetworkRequestUtils.universalRequest<String>(
        request: () async => _successResponse('static'),
        fromJson: (json) => json.toString(),
        showLoading: false,
        showError: false,
        needRethrow: false,
      );
      expect(result, 'static');
    });

    test('silentRequest should work statically', () async {
      final result = await NetworkRequestUtils.silentRequest<int>(
        request: () async => _successResponse(99),
        fromJson: (json) => json as int,
      );
      expect(result, 99);
    });

    test('quickRequest should work statically', () async {
      final result = await NetworkRequestUtils.quickRequest<String>(
        request: () async => _successResponse('fast'),
        fromJson: (json) => json.toString(),
      );
      expect(result, 'fast');
    });
  });
}
