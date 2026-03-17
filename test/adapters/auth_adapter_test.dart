import 'dart:convert';

import 'package:test/test.dart';
import 'package:koi_network/src/adapters/auth_adapter.dart';

/// Creates a test JWT token
String _createTestToken(Map<String, dynamic> payload) {
  final header = base64Url.encode(
    utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final body = base64Url.encode(utf8.encode(json.encode(payload)));
  return '$header.$body.test_signature';
}

void main() {
  group('KoiDefaultAuthAdapter', () {
    late KoiDefaultAuthAdapter adapter;

    setUp(() {
      adapter = KoiDefaultAuthAdapter();
    });

    test('getToken should return null by default', () {
      expect(adapter.getToken(), isNull);
    });

    test('getRefreshToken should return null by default', () {
      expect(adapter.getRefreshToken(), isNull);
    });

    test('refresh should return false by default', () async {
      expect(await adapter.refresh(), isFalse);
    });

    test('saveToken should store token', () async {
      await adapter.saveToken('test_token');
      expect(adapter.getToken(), 'test_token');
    });

    test('saveRefreshToken should store refresh token', () async {
      await adapter.saveRefreshToken('refresh_token');
      expect(adapter.getRefreshToken(), 'refresh_token');
    });

    test('clearToken should clear all tokens', () async {
      await adapter.saveToken('token');
      await adapter.saveRefreshToken('refresh');
      await adapter.clearToken();
      expect(adapter.getToken(), isNull);
      expect(adapter.getRefreshToken(), isNull);
    });

    test('isLoggedIn should return false when no token', () {
      expect(adapter.isLoggedIn(), isFalse);
    });

    test('isLoggedIn should return true when token exists', () async {
      await adapter.saveToken('some_token');
      expect(adapter.isLoggedIn(), isTrue);
    });
  });

  group('KoiJwtTokenMixin (via KoiDefaultAuthAdapter)', () {
    late KoiDefaultAuthAdapter adapter;

    setUp(() {
      adapter = KoiDefaultAuthAdapter();
    });

    test('isTokenExpired should return true when no token', () {
      expect(adapter.isTokenExpired(), isTrue);
    });

    test('isTokenExpired should return true for expired token', () async {
      final pastExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;
      final token = _createTestToken({'exp': pastExp});
      await adapter.saveToken(token);
      expect(adapter.isTokenExpired(), isTrue);
    });

    test('isTokenExpired should return false for valid token', () async {
      final futureExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final token = _createTestToken({'exp': futureExp});
      await adapter.saveToken(token);
      expect(adapter.isTokenExpired(), isFalse);
    });

    test(
      'isTokenExpiringSoon should return true when close to expiry',
      () async {
        final soonExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30;
        final token = _createTestToken({'exp': soonExp});
        await adapter.saveToken(token);
        expect(
          adapter.isTokenExpiringSoon(threshold: const Duration(minutes: 1)),
          isTrue,
        );
      },
    );

    test(
      'isTokenExpiringSoon should return false when far from expiry',
      () async {
        final farExp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200;
        final token = _createTestToken({'exp': farExp});
        await adapter.saveToken(token);
        expect(
          adapter.isTokenExpiringSoon(threshold: const Duration(minutes: 5)),
          isFalse,
        );
      },
    );

    test('getTokenExpiration should return expiration DateTime', () async {
      final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final token = _createTestToken({'exp': exp});
      await adapter.saveToken(token);
      final result = adapter.getTokenExpiration();
      expect(result, isNotNull);
    });

    test('getTokenExpiration should return null when no token', () {
      expect(adapter.getTokenExpiration(), isNull);
    });
  });
}
