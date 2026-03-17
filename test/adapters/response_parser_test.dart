import 'package:test/test.dart';
import 'package:koi_network/src/adapters/response_parser.dart';

void main() {
  group('KoiDefaultResponseParser', () {
    late KoiDefaultResponseParser parser;

    setUp(() {
      parser = KoiDefaultResponseParser();
    });

    group('isSuccess', () {
      test('should return true for code 200', () {
        expect(parser.isSuccess({'code': 200, 'msg': 'ok'}), isTrue);
      });

      test('should return true for code 0', () {
        expect(parser.isSuccess({'code': 0, 'msg': 'ok'}), isTrue);
      });

      test('should return false for code 500', () {
        expect(parser.isSuccess({'code': 500, 'msg': 'error'}), isFalse);
      });

      test('should return false for missing code', () {
        expect(parser.isSuccess({'msg': 'no code'}), isFalse);
      });
    });

    group('getMessage', () {
      test('should extract msg field', () {
        expect(
          parser.getMessage({'code': 500, 'msg': 'Server Error'}),
          'Server Error',
        );
      });

      test('should fallback to message field', () {
        expect(
          parser.getMessage({'code': 500, 'message': 'Fallback'}),
          'Fallback',
        );
      });

      test('should fallback to error field', () {
        expect(
          parser.getMessage({'code': 500, 'error': 'Error text'}),
          'Error text',
        );
      });

      test('should return null when no message fields exist', () {
        expect(parser.getMessage({'code': 500}), isNull);
      });
    });

    group('getData', () {
      test('should extract data field', () {
        final data = {
          'code': 200,
          'data': {'id': 1, 'name': 'test'},
        };
        expect(parser.getData(data), {'id': 1, 'name': 'test'});
      });

      test('should return null when data field is absent', () {
        expect(parser.getData({'code': 200}), isNull);
      });
    });

    group('getCode', () {
      test('should extract code field', () {
        expect(parser.getCode({'code': 200}), 200);
      });

      test('should return -1 when code is not int', () {
        expect(parser.getCode({'code': 'abc'}), -1);
      });

      test('should return -1 when code field is absent', () {
        expect(parser.getCode({}), -1);
      });
    });

    group('isAuthError', () {
      test('should return true for HTTP 401', () {
        expect(parser.isAuthError(401, null), isTrue);
      });

      test('should return true for HTTP 403', () {
        expect(parser.isAuthError(403, null), isTrue);
      });

      test('should return false for HTTP 200', () {
        expect(parser.isAuthError(200, null), isFalse);
      });

      test('should return false for null status code', () {
        expect(parser.isAuthError(null, null), isFalse);
      });

      test('should return false for HTTP 500', () {
        expect(parser.isAuthError(500, {'code': 500}), isFalse);
      });
    });

    group('custom success codes', () {
      test('should respect custom success codes', () {
        final customParser = KoiDefaultResponseParser(successCodes: [1, 200]);
        expect(customParser.isSuccess({'code': 1}), isTrue);
        expect(customParser.isSuccess({'code': 0}), isFalse);
      });

      test('should respect custom auth error codes', () {
        final customParser = KoiDefaultResponseParser(
          authErrorHttpCodes: [401],
        );
        expect(customParser.isAuthError(401, null), isTrue);
        expect(customParser.isAuthError(403, null), isFalse);
      });
    });
  });

  group('KoiResponseParser interface', () {
    test('custom parser can override all methods', () {
      final customParser = _CustomSuccessParser();
      expect(customParser.isSuccess({'status': 1}), isTrue);
      expect(customParser.isSuccess({'status': 0}), isFalse);
      expect(customParser.getCode({'status': 1}), 1);
      expect(customParser.getMessage({'status': 0}), 'failed');
    });
  });
}

/// Custom parser for testing interface extensibility
class _CustomSuccessParser implements KoiResponseParser {
  @override
  bool isSuccess(Map<String, dynamic> json) => json['status'] == 1;

  @override
  String? getMessage(Map<String, dynamic> json) =>
      json['status'] == 0 ? 'failed' : null;

  @override
  dynamic getData(Map<String, dynamic> json) => json;

  @override
  int getCode(Map<String, dynamic> json) => json['status'] as int? ?? -1;

  @override
  bool isAuthError(int? httpStatusCode, Map<String, dynamic>? body) => false;
}
