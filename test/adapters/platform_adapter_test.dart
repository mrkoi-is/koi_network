import 'package:test/test.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart';

void main() {
  group('KoiDefaultPlatformAdapter', () {
    late KoiDefaultPlatformAdapter adapter;

    setUp(() {
      adapter = KoiDefaultPlatformAdapter();
    });

    test('platform should return a non-empty string', () {
      expect(adapter.platform, isA<String>());
      expect(adapter.platform, isNotEmpty);
    });

    test('platformDisplayName should return a non-empty string', () {
      expect(adapter.platformDisplayName, isA<String>());
      expect(adapter.platformDisplayName, isNotEmpty);
    });

    test('appVersion should return default version', () {
      expect(adapter.appVersion, '1.0.0');
    });

    test('userAgent should contain platform info', () {
      expect(adapter.userAgent, isA<String>());
      expect(adapter.userAgent, isNotEmpty);
    });

    test('isMobile should return a bool', () {
      expect(adapter.isMobile, isA<bool>());
    });

    test('isDesktop should return a bool', () {
      expect(adapter.isDesktop, isA<bool>());
    });

    test('isWeb should return false for default (dart:io) adapter', () {
      expect(adapter.isWeb, isFalse);
    });

    test('getPlatformConfig should return a Map with required keys', () {
      final config = adapter.getPlatformConfig();
      expect(config, isA<Map<String, dynamic>>());
      expect(config, contains('platform'));
      expect(config, contains('version'));
    });
  });

  group('KoiPlatformAdapter interface', () {
    test('custom adapter can provide custom values', () {
      final custom = _TestPlatformAdapter();
      expect(custom.platform, 'test');
      expect(custom.platformDisplayName, 'Test OS');
      expect(custom.appVersion, '2.0.0');
      expect(custom.userAgent, 'TestApp/2.0.0 (Test OS)');
      expect(custom.isMobile, isFalse);
      expect(custom.isDesktop, isFalse);
      expect(custom.isWeb, isTrue);
    });
  });
}

class _TestPlatformAdapter implements KoiPlatformAdapter {
  @override
  String get platform => 'test';

  @override
  String get platformDisplayName => 'Test OS';

  @override
  String get appVersion => '2.0.0';

  @override
  String get userAgent => 'TestApp/2.0.0 (Test OS)';

  @override
  bool get isMobile => false;

  @override
  bool get isDesktop => false;

  @override
  bool get isWeb => true;

  @override
  Map<String, dynamic> getPlatformConfig() => {
    'platform': platform,
    'version': appVersion,
  };
}
