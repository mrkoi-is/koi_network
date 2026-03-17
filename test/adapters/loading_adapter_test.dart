import 'package:test/test.dart';
import 'package:koi_network/src/adapters/loading_adapter.dart';

void main() {
  group('KoiDefaultLoadingAdapter', () {
    late KoiDefaultLoadingAdapter adapter;

    setUp(() {
      adapter = KoiDefaultLoadingAdapter();
    });

    test('showLoading should set isLoading to true', () {
      expect(adapter.isLoading(), isFalse);
      adapter.showLoading();
      expect(adapter.isLoading(), isTrue);
    });

    test('showLoading with message should not throw', () {
      expect(() => adapter.showLoading(message: 'Loading...'), returnsNormally);
    });

    test('hideLoading should set isLoading to false', () {
      adapter.showLoading();
      expect(adapter.isLoading(), isTrue);
      adapter.hideLoading();
      expect(adapter.isLoading(), isFalse);
    });

    test('showProgress should not throw', () {
      expect(
        () => adapter.showProgress(progress: 0.5, message: 'Uploading...'),
        returnsNormally,
      );
    });

    test('hideProgress should not throw', () {
      expect(() => adapter.hideProgress(), returnsNormally);
    });

    test('isLoading default should be false', () {
      expect(adapter.isLoading(), isFalse);
    });
  });

  group('KoiLoadingAdapter interface', () {
    test('custom adapter can track loading state', () {
      final tracker = _TrackingLoadingAdapter();

      expect(tracker.isLoading(), isFalse);

      tracker.showLoading(message: 'Test');
      expect(tracker.isLoading(), isTrue);
      expect(tracker.lastMessage, 'Test');

      tracker.hideLoading();
      expect(tracker.isLoading(), isFalse);
    });
  });
}

/// Custom adapter that tracks loading state for testing
class _TrackingLoadingAdapter implements KoiLoadingAdapter {
  bool _isShowing = false;
  String? lastMessage;

  @override
  void showLoading({String? message}) {
    _isShowing = true;
    lastMessage = message;
  }

  @override
  void hideLoading() {
    _isShowing = false;
  }

  @override
  void showProgress({required double progress, String? message}) {
    lastMessage = message;
  }

  @override
  void hideProgress() {}

  @override
  bool isLoading() => _isShowing;
}
