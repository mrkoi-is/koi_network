import 'dart:convert';

import 'package:test/test.dart';
import 'package:koi_network/src/utils/jwt_decoder.dart';

/// 创建一个测试用的 JWT Token
String _createTestToken(Map<String, dynamic> payload) {
  final header = base64Url.encode(
    utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final body = base64Url.encode(utf8.encode(json.encode(payload)));
  return '$header.$body.test_signature';
}

void main() {
  group('KoiJwtDecoder', () {
    group('decode', () {
      test('should decode valid JWT payload', () {
        final token = _createTestToken({
          'sub': '12345',
          'name': 'John Doe',
          'exp': 1700000000,
        });
        final payload = KoiJwtDecoder.decode(token);

        expect(payload, isNotNull);
        expect(payload!['sub'], '12345');
        expect(payload['name'], 'John Doe');
        expect(payload['exp'], 1700000000);
      });

      test('should return null for empty string', () {
        expect(KoiJwtDecoder.decode(''), isNull);
      });

      test('should return null for malformed token (missing parts)', () {
        expect(KoiJwtDecoder.decode('only.two'), isNull);
      });

      test('should return null for invalid base64', () {
        expect(KoiJwtDecoder.decode('header.!!!invalid!!!.sig'), isNull);
      });
    });

    group('isExpired', () {
      test('should return false for token expiring in the future', () {
        final futureExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
        final token = _createTestToken({'exp': futureExp});
        expect(KoiJwtDecoder.isExpired(token), isFalse);
      });

      test('should return true for token expired in the past', () {
        final pastExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;
        final token = _createTestToken({'exp': pastExp});
        expect(KoiJwtDecoder.isExpired(token), isTrue);
      });

      test('should return true for empty token', () {
        expect(KoiJwtDecoder.isExpired(''), isTrue);
      });

      test('should return true for token without exp claim', () {
        final token = _createTestToken({'sub': '123'});
        expect(KoiJwtDecoder.isExpired(token), isTrue);
      });
    });

    group('isExpiringSoon', () {
      test('should return true when token expires within threshold', () {
        final soonExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30;
        final token = _createTestToken({'exp': soonExp});
        expect(
          KoiJwtDecoder.isExpiringSoon(
            token,
            threshold: const Duration(minutes: 1),
          ),
          isTrue,
        );
      });

      test('should return false when token has plenty of time', () {
        final farExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200;
        final token = _createTestToken({'exp': farExp});
        expect(
          KoiJwtDecoder.isExpiringSoon(
            token,
            threshold: const Duration(minutes: 5),
          ),
          isFalse,
        );
      });

      test('should return true for empty token', () {
        expect(KoiJwtDecoder.isExpiringSoon(''), isTrue);
      });
    });

    group('getExpiration', () {
      test('should return expiration DateTime from exp claim', () {
        const expTime = 1700000000;
        final token = _createTestToken({'exp': expTime});
        final result = KoiJwtDecoder.getExpiration(token);

        expect(result, isNotNull);
        expect(
          result,
          DateTime.fromMillisecondsSinceEpoch(expTime * 1000, isUtc: true),
        );
      });

      test('should handle string exp value', () {
        final token = _createTestToken({'exp': '1700000000'});
        final result = KoiJwtDecoder.getExpiration(token);
        expect(result, isNotNull);
      });

      test('should return null when no exp claim', () {
        final token = _createTestToken({'sub': '123'});
        expect(KoiJwtDecoder.getExpiration(token), isNull);
      });

      test('should return null for empty token', () {
        expect(KoiJwtDecoder.getExpiration(''), isNull);
      });
    });

    group('getCustomExpiration', () {
      test('should extract custom date field from payload', () {
        final token = _createTestToken({
          'customExpiry': '2025-01-01T00:00:00Z',
        });
        final result = KoiJwtDecoder.getCustomExpiration(
          token,
          'customExpiry',
          (value) => DateTime.parse(value),
        );
        expect(result, DateTime.utc(2025));
      });

      test('should return null for empty token', () {
        final result = KoiJwtDecoder.getCustomExpiration(
          '',
          'customExpiry',
          (value) => DateTime.parse(value),
        );
        expect(result, isNull);
      });

      test('should return null for non-string claim', () {
        final token = _createTestToken({'customExpiry': 12345});
        final result = KoiJwtDecoder.getCustomExpiration(
          token,
          'customExpiry',
          (value) => DateTime.parse(value),
        );
        expect(result, isNull);
      });
    });

    group('getIssuedAt', () {
      test('should return iat DateTime', () {
        const iatTime = 1700000000;
        final token = _createTestToken({'iat': iatTime});
        final result = KoiJwtDecoder.getIssuedAt(token);
        expect(result, isNotNull);
        expect(
          result,
          DateTime.fromMillisecondsSinceEpoch(iatTime * 1000, isUtc: true),
        );
      });

      test('should return null when no iat', () {
        final token = _createTestToken({'sub': '123'});
        expect(KoiJwtDecoder.getIssuedAt(token), isNull);
      });
    });

    group('getUserId', () {
      test('should return sub claim', () {
        final token = _createTestToken({'sub': 'user_123'});
        expect(KoiJwtDecoder.getUserId(token), 'user_123');
      });

      test('should return UserId claim when sub is absent', () {
        final token = _createTestToken({'UserId': 'uid_456'});
        expect(KoiJwtDecoder.getUserId(token), 'uid_456');
      });

      test('should return userId claim when others are absent', () {
        final token = _createTestToken({'userId': 'uid_789'});
        expect(KoiJwtDecoder.getUserId(token), 'uid_789');
      });

      test('should return null when no userId fields present', () {
        final token = _createTestToken({'foo': 'bar'});
        expect(KoiJwtDecoder.getUserId(token), isNull);
      });

      test('should return null for empty token', () {
        expect(KoiJwtDecoder.getUserId(''), isNull);
      });
    });

    group('getUsername', () {
      test('should return name claim', () {
        final token = _createTestToken({'name': 'John Doe'});
        expect(KoiJwtDecoder.getUsername(token), 'John Doe');
      });

      test('should return UserName claim when name is absent', () {
        final token = _createTestToken({'UserName': 'Jane'});
        expect(KoiJwtDecoder.getUsername(token), 'Jane');
      });

      test('should return null when no name fields present', () {
        final token = _createTestToken({'foo': 'bar'});
        expect(KoiJwtDecoder.getUsername(token), isNull);
      });
    });
  });
}
