import 'package:test/test.dart';
import 'package:koi_network/src/adapters/network_adapters.dart';
import 'package:koi_network/src/adapters/auth_adapter.dart';
import 'package:koi_network/src/adapters/error_handler_adapter.dart';
import 'package:koi_network/src/adapters/loading_adapter.dart';
import 'package:koi_network/src/adapters/logger_adapter.dart';
import 'package:koi_network/src/adapters/platform_adapter.dart';
import 'package:koi_network/src/adapters/response_parser.dart';
import 'package:koi_network/src/adapters/request_encoder.dart';

void main() {
  group('KoiNetworkAdapters', () {
    tearDown(() {
      KoiNetworkAdapters.clear();
    });

    test('isRegistered should be false before registration', () {
      expect(KoiNetworkAdapters.isRegistered, isFalse);
    });

    test('register should set all adapters', () {
      KoiNetworkAdapters.register(
        authAdapter: KoiDefaultAuthAdapter(),
        errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
        loadingAdapter: KoiDefaultLoadingAdapter(),
        platformAdapter: KoiDefaultPlatformAdapter(),
      );

      expect(KoiNetworkAdapters.isRegistered, isTrue);
      expect(KoiNetworkAdapters.auth, isA<KoiDefaultAuthAdapter>());
      expect(
        KoiNetworkAdapters.errorHandler,
        isA<KoiDefaultErrorHandlerAdapter>(),
      );
      expect(KoiNetworkAdapters.loading, isA<KoiDefaultLoadingAdapter>());
      expect(KoiNetworkAdapters.platform, isA<KoiDefaultPlatformAdapter>());
    });

    test('register should use defaults for optional adapters', () {
      KoiNetworkAdapters.register(
        authAdapter: KoiDefaultAuthAdapter(),
        errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
        loadingAdapter: KoiDefaultLoadingAdapter(),
        platformAdapter: KoiDefaultPlatformAdapter(),
      );

      expect(KoiNetworkAdapters.logger, isA<KoiDefaultLoggerAdapter>());
      expect(
        KoiNetworkAdapters.responseParser,
        isA<KoiDefaultResponseParser>(),
      );
      expect(KoiNetworkAdapters.requestEncoder, isA<KoiJsonRequestEncoder>());
    });

    test('register should accept custom response parser', () {
      final customParser = KoiDefaultResponseParser();
      KoiNetworkAdapters.register(
        authAdapter: KoiDefaultAuthAdapter(),
        errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
        loadingAdapter: KoiDefaultLoadingAdapter(),
        platformAdapter: KoiDefaultPlatformAdapter(),
        responseParser: customParser,
      );

      expect(KoiNetworkAdapters.responseParser, same(customParser));
    });

    test(
      'accessing required adapters before registration should throw StateError',
      () {
        // Required adapters throw StateError
        expect(() => KoiNetworkAdapters.auth, throwsStateError);
        expect(() => KoiNetworkAdapters.errorHandler, throwsStateError);
        expect(() => KoiNetworkAdapters.loading, throwsStateError);
        expect(() => KoiNetworkAdapters.platform, throwsStateError);
      },
    );

    test(
      'optional adapters should return defaults even before registration',
      () {
        // Optional adapters have lazy defaults (no throw)
        expect(KoiNetworkAdapters.logger, isA<KoiDefaultLoggerAdapter>());
        expect(
          KoiNetworkAdapters.responseParser,
          isA<KoiDefaultResponseParser>(),
        );
        expect(KoiNetworkAdapters.requestEncoder, isA<KoiJsonRequestEncoder>());
      },
    );

    test('clear should reset registration status', () {
      KoiNetworkAdapters.register(
        authAdapter: KoiDefaultAuthAdapter(),
        errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
        loadingAdapter: KoiDefaultLoadingAdapter(),
        platformAdapter: KoiDefaultPlatformAdapter(),
      );

      expect(KoiNetworkAdapters.isRegistered, isTrue);

      KoiNetworkAdapters.clear();

      expect(KoiNetworkAdapters.isRegistered, isFalse);
    });

    test('registerDefaults should register all default adapters', () {
      KoiNetworkAdapters.registerDefaults();

      expect(KoiNetworkAdapters.isRegistered, isTrue);
      expect(KoiNetworkAdapters.auth, isA<KoiDefaultAuthAdapter>());
      expect(KoiNetworkAdapters.logger, isA<KoiDefaultLoggerAdapter>());
    });

    test('getStatus should return adapter registration status', () {
      KoiNetworkAdapters.register(
        authAdapter: KoiDefaultAuthAdapter(),
        errorHandlerAdapter: KoiDefaultErrorHandlerAdapter(),
        loadingAdapter: KoiDefaultLoadingAdapter(),
        platformAdapter: KoiDefaultPlatformAdapter(),
      );

      final status = KoiNetworkAdapters.getStatus();
      expect(status['authAdapter'], isTrue);
      expect(status['errorHandlerAdapter'], isTrue);
      expect(status['loadingAdapter'], isTrue);
      expect(status['platformAdapter'], isTrue);
      expect(status['loggerAdapter'], isTrue);
      expect(status['responseParser'], isTrue);
      expect(status['requestEncoder'], isTrue);
    });

    test('getStatus should show unregistered adapters after clear', () {
      KoiNetworkAdapters.clear();
      final status = KoiNetworkAdapters.getStatus();
      expect(status['authAdapter'], isFalse);
      expect(status['errorHandlerAdapter'], isFalse);
    });
  });
}
