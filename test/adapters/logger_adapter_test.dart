import 'package:test/test.dart';
import 'package:koi_network/src/adapters/logger_adapter.dart';

void main() {
  group('KoiDefaultLoggerAdapter', () {
    late KoiDefaultLoggerAdapter adapter;

    setUp(() {
      adapter = KoiDefaultLoggerAdapter();
    });

    test('debug should not throw', () {
      expect(() => adapter.debug('debug message'), returnsNormally);
    });

    test('debug with error and stackTrace should not throw', () {
      expect(
        () => adapter.debug('debug message', 'error', StackTrace.current),
        returnsNormally,
      );
    });

    test('info should not throw', () {
      expect(() => adapter.info('info message'), returnsNormally);
    });

    test('info with error should not throw', () {
      expect(
        () => adapter.info('info message', Exception('test')),
        returnsNormally,
      );
    });

    test('warning should not throw', () {
      expect(() => adapter.warning('warning message'), returnsNormally);
    });

    test('warning with error and stackTrace should not throw', () {
      expect(
        () => adapter.warning('warning', Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });

    test('error should not throw', () {
      expect(() => adapter.error('error message'), returnsNormally);
    });

    test('error with error and stackTrace should not throw', () {
      expect(
        () => adapter.error('error', Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });

    test('fatal should not throw', () {
      expect(() => adapter.fatal('fatal message'), returnsNormally);
    });

    test('fatal with error and stackTrace should not throw', () {
      expect(
        () => adapter.fatal('fatal', Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
