import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Programmatic control surface for [CircularAnimatedCarousel]. Pass an
/// instance via the `controller` parameter and call its methods to
/// animate / jump to specific indices from outside the widget — e.g.
/// "Next" buttons, deep links, or analytics-driven navigation.
///
/// One controller controls one carousel. Calling controller methods
/// before the carousel mounts (or after it disposes) is a no-op.
///
/// ```dart
/// final controller = CircularAnimatedCarouselController();
/// // ...
/// CircularAnimatedCarousel(
///   controller: controller,
///   itemCount: 5,
///   itemBuilder: (c, info) => MyCard(),
/// );
/// // ...
/// ElevatedButton(
///   onPressed: () => controller.next(),
///   child: Text('Next'),
/// );
/// ```
///
/// Don't forget to `dispose()` the controller when the host State is
/// disposed — same convention as [TextEditingController] /
/// [PageController].
class CircularAnimatedCarouselController extends ChangeNotifier {
  CircularAnimatedCarouselControllerBinding? _binding;

  /// Wired by [CircularAnimatedCarousel] in its initState. Internal —
  /// consumers should never call this directly. (Not enforced via
  /// `@protected` because the carousel State isn't a subclass; the
  /// underscore prefix would break public-API stability for a feature
  /// that's effectively private.)
  void attach(CircularAnimatedCarouselControllerBinding binding) {
    assert(
      _binding == null,
      'CircularAnimatedCarouselController is already attached. A controller can only '
      'drive one CircularAnimatedCarousel at a time.',
    );
    _binding = binding;
  }

  /// Wired by [CircularAnimatedCarousel] in its dispose. Internal.
  void detach() {
    _binding = null;
  }

  /// `true` once the controller is attached to a live carousel.
  bool get hasClient => _binding != null;

  /// Current focused integer index, or `null` if not attached.
  /// In circular mode this is wrapped to `[0, itemCount)`; in linear
  /// mode it's clamped to `[0, itemCount - 1]`.
  int? get currentIndex => _binding?.currentIndex;

  /// Current fractional position (settled or mid-drag). `null` if not
  /// attached. Useful for restoring state across rebuilds.
  double? get currentPosition => _binding?.currentPosition;

  /// Animate to [index] using [duration] / [curve]. If null, the
  /// carousel's `snapDuration` and `Curves.easeOutCubic` are used.
  ///
  /// In circular mode, [index] can be larger than `itemCount` — the
  /// carousel picks the shortest direction to reach the wrapped target.
  Future<void> animateTo(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    final b = _binding;
    if (b == null) return;
    await b.animateToIndex(index, duration: duration, curve: curve);
  }

  /// Immediately set position to [index] — no animation.
  void jumpTo(int index) {
    _binding?.jumpToIndex(index);
  }

  /// Animate to the next index. In linear mode at the last index this
  /// is a no-op; in circular mode it wraps to 0.
  Future<void> next({Duration? duration, Curve? curve}) async {
    final b = _binding;
    if (b == null) return;
    await b.animateToIndex(
      b.currentIndex + 1,
      duration: duration,
      curve: curve,
    );
  }

  /// Animate to the previous index. In linear mode at index 0 this is a
  /// no-op; in circular mode it wraps to `itemCount - 1`.
  Future<void> previous({Duration? duration, Curve? curve}) async {
    final b = _binding;
    if (b == null) return;
    await b.animateToIndex(
      b.currentIndex - 1,
      duration: duration,
      curve: curve,
    );
  }
}

/// Internal interface implemented by `_CircularAnimatedCarouselState` so
/// the controller can drive it without leaking widget internals.
/// Consumers should never see this class.
abstract class CircularAnimatedCarouselControllerBinding {
  int get currentIndex;
  double get currentPosition;
  Future<void> animateToIndex(
    int index, {
    Duration? duration,
    Curve? curve,
  });
  void jumpToIndex(int index);
}
