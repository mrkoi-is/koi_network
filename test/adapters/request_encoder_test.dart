import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:koi_network/src/adapters/request_encoder.dart';

void main() {
  group('KoiJsonRequestEncoder', () {
    late KoiJsonRequestEncoder encoder;

    setUp(() {
      encoder = KoiJsonRequestEncoder();
    });

    test('should return data as-is for Map', () {
      final data = {'key': 'value', 'num': 42};
      expect(encoder.encode(data), data);
    });

    test('contentType should be application/json', () {
      expect(encoder.contentType, 'application/json');
    });
  });

  group('KoiFormDataRequestEncoder', () {
    late KoiFormDataRequestEncoder encoder;

    setUp(() {
      encoder = KoiFormDataRequestEncoder();
    });

    test('should convert Map to FormData', () {
      final data = {'name': 'test', 'age': 25};
      final result = encoder.encode(data);
      expect(result, isA<FormData>());
    });

    test('contentType should be multipart/form-data', () {
      expect(encoder.contentType, 'multipart/form-data');
    });
  });

  group('KoiUrlEncodedRequestEncoder', () {
    late KoiUrlEncodedRequestEncoder encoder;

    setUp(() {
      encoder = KoiUrlEncodedRequestEncoder();
    });

    test('should return Map data as-is (Dio handles encoding)', () {
      final data = {'key': 'value'};
      expect(encoder.encode(data), data);
    });

    test('contentType should be application/x-www-form-urlencoded', () {
      expect(encoder.contentType, 'application/x-www-form-urlencoded');
    });
  });
}
