import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'types.dart';

/// A gesture-driven carousel that lays cards out along a gentle arc, leans
/// side cards inward like a garland, and keeps the focused card on top.
///
/// The carousel owns its own position state and gesture/snap animations.
/// Consumers supply card content via [itemBuilder] and react to focus
/// changes through the [CarouselItemInfo] passed in.
///
/// ```dart
/// CircularAnimatedCarousel(
///   itemCount: 3,
///   itemWidth: 200,
///   itemHeight: 280,
///   initialPosition: 1,
///   enableEntrance: true,
///   enableNudge: true,
///   itemBuilder: (context, info) => MyCard(
///     focusWeight: info.focusWeight,
///   ),
/// )
/// ```
class CircularAnimatedCarousel extends StatefulWidget {
  /// Number of cards the carousel will render. Indices passed back through
  /// [CarouselItemInfo.index] range from `0` to `itemCount - 1`.
  final int itemCount;

  /// Builder for each visible card.
  final CarouselItemBuilder itemBuilder;

  /// Logical width of each card.
  final double itemWidth;

  /// Logical height of each card.
  final double itemHeight;

  /// Fraction of the viewport width used as the gap (slot size) between
  /// adjacent cards. With a viewport of 360 px and the default `0.65`,
  /// adjacent card centers sit 234 px apart.
  ///
  /// Ignored when [itemSpacing] is set.
  final double viewportFraction;

  /// Absolute spacing (in logical pixels) between the centers of adjacent
  /// items. When non-null this overrides [viewportFraction] — useful when
  /// you want the same visual gap regardless of viewport width (small
  /// phones won't crowd, large phones won't spread out).
  ///
  /// Leave `null` to use the viewport-fraction calculation.
  final double? itemSpacing;

  /// Starting position (in slot units). `0` means the first card is
  /// focused. Fractional values are valid and useful when restoring
  /// state mid-drag.
  final double initialPosition;

  /// Maximum tilt (radians) applied to cards at offset `±1`. Cards beyond
  /// that distance are clamped at this tilt. Negative side cards tilt
  /// inward (tops lean toward the focused card) like a garland.
  final double maxTilt;

  /// Pixels each side card is lifted along a cosine arc relative to the
  /// focused card. Use `0` for a flat-line carousel.
  final double sideLift;

  /// Cards farther than this offset from focus are dropped from the
  /// render tree. Smaller values save GPU work; raise it if you see
  /// pop-in at the edges.
  final double maxRenderDistance;

  /// When true, on first mount the cards slide in from the right.
  /// Decoupled from the position tween — the entrance offset is squashed
  /// into the first 20 % of [entranceDuration] so cards have settled
  /// off-screen by the time mid-flight crossfade would kick in.
  final bool enableEntrance;

  /// Delay before the entrance slide begins. Useful when the carousel is
  /// mounted inside a bottom-sheet / modal that has its own open
  /// animation — set this to the sheet's open duration so the slide
  /// doesn't fire while the sheet is still moving into view.
  final Duration entranceDelay;

  /// Starting position for the entrance, in slot units. When non-zero
  /// the entrance becomes a *position-based stream* — `position` is
  /// tweened from this value to [initialPosition] over the full
  /// [entranceDuration] with [entranceCurve], so cards visibly stream
  /// past the viewport from right to left (or left to right for positive
  /// offsets).
  ///
  /// Setting `-9.0` produces the same streaming effect as a 9-slot
  /// scroll into the focused position — the look used by the Innopay
  /// coupon celebration sheet.
  ///
  /// Default `0.0` falls back to a quick horizontal *displacement* slide
  /// (cards start off-screen right, slide into place during the first
  /// 20 % of [entranceDuration]). Use this when the carousel is in a
  /// static surface and you want a shorter, sharper arrival.
  final double entranceStartOffset;

  /// Curve applied to whichever entrance mode is active.
  final Curve entranceCurve;

  /// When true, the carousel loops — scrolling past the last item brings
  /// you back to the first, and vice versa. Drag/flick targets are not
  /// clamped, and the index handed to [itemBuilder] and [onIndexChanged]
  /// is automatically wrapped to `[0, itemCount)`, so the builder can
  /// index a palette / data list directly without manual `% itemCount`.
  ///
  /// When false (default — *linear* mode), the carousel behaves like a
  /// paged list bounded to `[0, itemCount - 1]` and the user feels the
  /// end of the range when they reach it.
  final bool circular;

  /// When true, plays a single down + up bob on the focused card shortly
  /// after the entrance settles to hint at vertical drag.
  final bool enableNudge;

  /// Duration of the entrance slide.
  final Duration entranceDuration;

  /// Duration of the snap-to-index animation after a drag.
  final Duration snapDuration;

  /// Duration of one full down-and-up nudge cycle. Default ~1 s reads as
  /// a deliberate hint, not a fidget.
  final Duration nudgeDuration;

  /// Amplitude (pixels) of the nudge bob.
  final double nudgeAmplitude;

  /// Maximum swing angle (radians) used by the side-lift cosine arc. Tune
  /// alongside [sideLift] when changing the carousel's overall shape.
  final double swingAngleMax;

  /// Multiplier applied to flick velocity when computing the snap target
  /// after a drag ends. Higher = more "throw".
  final double flickFactor;

  /// Optional external controller for programmatic `animateTo` /
  /// `jumpTo` / `next` / `previous`. Wire it up the same way you would a
  /// [TextEditingController] — instantiate once, pass here, and `dispose`
  /// on State teardown.
  final CircularAnimatedCarouselController? controller;

  /// When true, the carousel auto-advances to the next index every
  /// [autoplayInterval]. Wraps in circular mode; stops at the last
  /// index in linear mode.
  final bool autoplay;

  /// Delay between auto-advances. Ignored when [autoplay] is false.
  final Duration autoplayInterval;

  /// When true, autoplay pauses the moment the user starts a drag and
  /// resumes when they release. Highly recommended — without this,
  /// autoplay can fight the user's finger.
  final bool pauseOnInteraction;

  /// When true (default), drag-end snaps to the nearest integer index
  /// using [snapDuration] / [Curves.easeOutCubic]. When false, the
  /// carousel free-scrolls and leaves the position wherever the user
  /// released — useful for galleries where items aren't paged.
  final bool enableSnap;

  /// Which side of the focused item the arc lives on. See
  /// [ArcDirection] — default [ArcDirection.up] (side items rise above
  /// the focused one with tops tilted inward). Flip to
  /// [ArcDirection.down] for a mirrored "bowl" arc where side items
  /// drop below the focused one with tops tilted outward.
  final ArcDirection arcDirection;

  /// Baseline viewport width (logical pixels) that [itemWidth],
  /// [itemHeight], [itemSpacing], [sideLift], and [nudgeAmplitude] were
  /// designed for. The package scales them by
  /// `actualViewport / referenceWidth` so the layout looks the same
  /// across every screen size — 360 px phone, 411 px phone, tablet.
  ///
  /// Default `360.0` (the standard Android `mdpi` baseline, close to
  /// most Figma designs). Pass `null` to opt out and use your values
  /// as raw logical pixels regardless of viewport.
  final double? referenceWidth;

  /// Fires when an item is tapped (a tap that didn't escalate into a
  /// drag). Receives the tapped item's index — already wrapped to
  /// `[0, itemCount)` in circular mode.
  ///
  /// When set, tapping a **non-focused** item also animates the focus
  /// to that item (the typical "tap a side card to bring it in" UX).
  /// Tapping the focused item just fires the callback.
  final ValueChanged<int>? onTap;

  /// Called whenever the focused integer index changes.
  final ValueChanged<int>? onIndexChanged;

  /// Called on every position update — drag ticks AND snap ticks. Fires
  /// with the live fractional position (e.g. `2.4` mid-drag between
  /// index 2 and 3). Use this when you need to interpolate something
  /// outside the carousel that depends on the live offset — e.g. a glow
  /// colour that blends between two adjacent cards' palettes as the user
  /// scrolls.
  ///
  /// If you only need to react to settled snaps, use [onIndexChanged].
  final ValueChanged<double>? onPositionChanged;

  const CircularAnimatedCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth = 200,
    this.itemHeight = 280,
    this.viewportFraction = 0.65,
    this.itemSpacing,
    this.initialPosition = 0,
    this.maxTilt = 0.6,
    this.sideLift = 80,
    this.maxRenderDistance = 1.5,
    this.enableEntrance = true,
    this.enableNudge = true,
    this.entranceDelay = Duration.zero,
    this.entranceDuration = const Duration(milliseconds: 2000),
    this.entranceStartOffset = 0.0,
    this.entranceCurve = Curves.easeOutCubic,
    this.circular = false,
    this.snapDuration = const Duration(milliseconds: 220),
    this.nudgeDuration = const Duration(milliseconds: 1000),
    this.nudgeAmplitude = 10,
    this.swingAngleMax = 0.6,
    this.flickFactor = 0.12,
    this.enableSnap = true,
    this.autoplay = false,
    this.autoplayInterval = const Duration(seconds: 3),
    this.pauseOnInteraction = true,
    this.referenceWidth = 360.0,
    this.arcDirection = ArcDirection.up,
    this.controller,
    this.onTap,
    this.onIndexChanged,
    this.onPositionChanged,
  })  : assert(itemCount > 0, 'itemCount must be positive'),
        assert(itemWidth > 0, 'itemWidth must be positive'),
        assert(itemHeight > 0, 'itemHeight must be positive'),
        assert(
          viewportFraction > 0 && viewportFraction <= 1,
          'viewportFraction must be in (0, 1]',
        );

  @override
  State<CircularAnimatedCarousel> createState() =>
      _CircularAnimatedCarouselState();
}

class _CircularAnimatedCarouselState extends State<CircularAnimatedCarousel>
    with TickerProviderStateMixin
    implements CircularAnimatedCarouselControllerBinding {
  /// Current carousel position in slot units. Centered cards land on
  /// integers. Fractional values are valid mid-drag.
  late double _position;

  /// Drives the post-flick snap back to the nearest (or velocity-aware)
  /// integer position.
  late final AnimationController _snapController;
  Animation<double>? _snapAnim;

  /// Drives the entrance slide. Held at `1.0` when entrance is disabled.
  late final AnimationController _entranceController;

  /// Portion of [_entranceController]'s timeline reserved for the
  /// horizontal entrance offset. Position settling rides the remainder.
  static const double _entrancePortion = 0.20;

  /// Drives the one-shot nudge bob.
  late final AnimationController _nudgeController;
  bool _nudgePlayed = false;

  /// Last integer index we reported through [widget.onIndexChanged]. Lets
  /// us debounce the callback so listeners only see "snap settled" events.
  int? _lastReportedIndex;

  /// True while we're holding the carousel blank during
  /// [CircularAnimatedCarousel.entranceDelay]. Lets the host show an
  /// empty slot for a beat before the cards stream in — matches the
  /// original Innopay sheet's "register the empty state first" pre-roll.
  /// Flips to false the moment [_entranceController.forward] is called.
  bool _entranceWaiting = false;

  /// Autoplay timer — `null` when autoplay is disabled or the user has
  /// just touched the carousel (and `pauseOnInteraction` is on).
  Timer? _autoplayTimer;

  /// The [ModalRoute] hosting this carousel, if any. We watch its primary
  /// animation so that the instant the route starts popping we can freeze
  /// the entrance/nudge and settle to the resting position. Without this,
  /// the intro animations keep ticking through the route's ~300 ms exit
  /// transition (the outgoing route stays on-stage, so its `TickerMode`
  /// stays enabled), and a neighbour sweeping through focus mid-stream
  /// "flashes" as the focused card while the page slides away. Null when
  /// the carousel isn't inside a route (e.g. embedded in an overlay).
  ModalRoute<dynamic>? _route;

  /// Cancellable timers for entrance/nudge/autoplay-start delays. We
  /// hold these so [dispose] can cancel any still-pending fires —
  /// otherwise the `flutter_test` `!timersPending` invariant would fail
  /// and, more importantly, a callback could fire on a disposed State
  /// in production (the `if (!mounted) return` early-out exists but
  /// keeping the timer alive past dispose still wastes work).
  final List<Timer> _scheduledTimers = [];

  /// True when the entrance should stream `_position` from
  /// [CircularAnimatedCarousel.entranceStartOffset] to
  /// [CircularAnimatedCarousel.initialPosition] over the full
  /// entranceDuration. False ⇒ the legacy "X displacement" entrance
  /// (cards slide in from off-screen right during the first 20 % of the
  /// timeline) is used instead.
  bool get _positionEntrance =>
      widget.enableEntrance && widget.entranceStartOffset != 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    _position = _positionEntrance
        ? widget.entranceStartOffset
        : widget.initialPosition;

    _snapController = AnimationController(
      vsync: this,
      duration: widget.snapDuration,
    )..addListener(_onSnapTick);

    _entranceController = AnimationController(
      vsync: this,
      duration: widget.entranceDuration,
    )..addListener(_onEntranceTick);

    _nudgeController = AnimationController(
      vsync: this,
      duration: widget.nudgeDuration,
    )..addListener(_onNudgeTick);

    if (widget.enableEntrance) {
      // entranceDelay lets the host (e.g. a bottom sheet) finish its own
      // open animation before the carousel slides in, so the slide isn't
      // hidden behind the sheet's chrome. While we're waiting,
      // [_entranceWaiting] suppresses card rendering so the user sees an
      // empty slot first — the cards then visibly stream in when the
      // timer fires.
      if (widget.entranceDelay == Duration.zero) {
        _entranceController.forward(from: 0);
      } else {
        _entranceWaiting = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scheduleTimer(widget.entranceDelay, () {
            setState(() => _entranceWaiting = false);
            _entranceController.forward(from: 0);
          });
        });
      }
    } else {
      _entranceController.value = 1.0;
    }

    if (widget.enableNudge) {
      // Fire the nudge once the entrance has settled. We don't wait for
      // the full duration — playing slightly before the very end keeps
      // the bob feeling connected to the arrival. Includes any
      // entranceDelay so the nudge follows the actual slide, not the
      // moment of mount.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final delay = widget.enableEntrance
            ? widget.entranceDelay + widget.entranceDuration * 0.85
            : Duration.zero;
        _scheduleTimer(delay, _playNudgeOnce);
      });
    }

    // Autoplay only starts after the entrance has settled, otherwise
    // its first tick can fire mid-slide and feel jarring. If entrance
    // is disabled we start immediately.
    if (widget.autoplay) {
      final delay = widget.enableEntrance
          ? widget.entranceDelay + widget.entranceDuration
          : Duration.zero;
      _scheduleTimer(delay, _startAutoplay);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-resolve the hosting route whenever our dependencies change
    // (covers being moved between routes, though that's rare). We listen
    // to the route's primary animation status so we can settle the
    // carousel the moment a pop starts — see [_route] and
    // [_handleRouteStatus].
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.animation?.removeStatusListener(_handleRouteStatus);
      _route = route;
      _route?.animation?.addStatusListener(_handleRouteStatus);
    }
  }

  /// Fires when the hosting route's primary animation changes status.
  /// [AnimationStatus.reverse] means the route is popping (sliding out),
  /// which is exactly when we must stop the still-running intro
  /// animations — otherwise a neighbour mid-stream flashes as focused
  /// while the page slides away. See [_settleNow].
  void _handleRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse && mounted) {
      setState(_settleNow);
    }
  }

  /// Freezes any in-flight intro animations and snaps the carousel to its
  /// resting position. Called when the hosting route begins to pop so the
  /// frame painted during the exit transition shows the settled layout
  /// (focused item centred, neighbours at the sides) rather than a card
  /// caught sweeping through focus. A no-op once everything has settled.
  void _settleNow() {
    _entranceWaiting = false;
    // Complete — not merely stop — the entrance so BOTH modes land in
    // their finished state: position-stream → `_position` reaches
    // `initialPosition` (via _onEntranceTick), displacement → `entranceX`
    // collapses to 0. Stopping mid-flight would leave displacement cards
    // frozen off-screen right.
    if (_entranceController.value != 1.0) _entranceController.value = 1.0;
    if (_nudgeController.value != 0.0) {
      _nudgeController
        ..stop()
        ..value = 0.0;
    }
    if (_snapController.isAnimating) {
      _snapController.stop();
      _position = (_snapAnim?.value ?? _position).roundToDouble();
    }
    if (_positionEntrance) _position = widget.initialPosition;
  }

  /// Tracked replacement for `Future.delayed` — schedules [action] after
  /// [delay] using a real Timer that we hold in [_scheduledTimers] and
  /// cancel in [dispose]. The action only fires if the widget is still
  /// mounted, so callers don't need to repeat the `mounted` check.
  void _scheduleTimer(Duration delay, VoidCallback action) {
    final timer = Timer(delay, () {
      if (mounted) action();
    });
    _scheduledTimers.add(timer);
  }

  @override
  void didUpdateWidget(covariant CircularAnimatedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
    if (oldWidget.autoplay != widget.autoplay ||
        oldWidget.autoplayInterval != widget.autoplayInterval) {
      _restartAutoplay();
    }
  }

  @override
  void dispose() {
    for (final t in _scheduledTimers) {
      t.cancel();
    }
    _scheduledTimers.clear();
    _stopAutoplay();
    _route?.animation?.removeStatusListener(_handleRouteStatus);
    widget.controller?.detach();
    _snapController
      ..removeListener(_onSnapTick)
      ..dispose();
    _entranceController
      ..removeListener(_onEntranceTick)
      ..dispose();
    _nudgeController
      ..removeListener(_onNudgeTick)
      ..dispose();
    super.dispose();
  }

  // ─── CircularAnimatedCarouselControllerBinding ───────────────────────────────────────

  @override
  int get currentIndex => _wrappedIndex(_position.round());

  @override
  double get currentPosition => _position;

  @override
  Future<void> animateToIndex(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    // Linear mode: clamp to a valid index so the user can't animate
    // past the ends.
    if (!widget.circular) {
      index = index.clamp(0, widget.itemCount - 1);
    }
    // Already there → no-op.
    if (index.toDouble() == _position) return;
    if (_snapController.isAnimating) _snapController.stop();

    // Override the snap controller's duration just for this call if a
    // custom duration is provided. Reset to the configured default
    // afterwards so other drag-end snaps aren't affected.
    final originalDuration = _snapController.duration;
    if (duration != null) _snapController.duration = duration;

    _snapAnim = Tween<double>(begin: _position, end: index.toDouble()).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: curve ?? Curves.easeOutCubic,
      ),
    );
    try {
      await _snapController.forward(from: 0);
      _notifyIndexIfChanged();
    } finally {
      _snapController.duration = originalDuration;
    }
  }

  @override
  void jumpToIndex(int index) {
    if (!widget.circular) {
      index = index.clamp(0, widget.itemCount - 1);
    }
    if (_snapController.isAnimating) _snapController.stop();
    setState(() {
      _position = index.toDouble();
    });
    widget.onPositionChanged?.call(_position);
    _notifyIndexIfChanged();
  }

  // ─── Tap handling ────────────────────────────────────────────────────

  /// Called when an item is tapped. Fires the consumer's `onTap` with
  /// the wrapped index, then auto-animates focus to that item if it
  /// wasn't already focused — the typical "tap a side card to bring it
  /// in" UX. [rawIndex] is the carousel's internal (unwrapped) index so
  /// the animate target stays in the same wrap as the current position
  /// (otherwise tapping a circular carousel could animate the wrong
  /// direction across the wrap boundary).
  void _handleItemTap(int wrappedIndex, int rawIndex) {
    widget.onTap?.call(wrappedIndex);
    if (rawIndex.toDouble() != _position) {
      animateToIndex(rawIndex);
    }
  }

  // ─── Autoplay ────────────────────────────────────────────────────────

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    if (!widget.autoplay) return;
    _autoplayTimer = Timer.periodic(widget.autoplayInterval, (_) {
      if (!mounted) return;
      animateToIndex(_position.round() + 1);
    });
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
  }

  void _restartAutoplay() {
    _stopAutoplay();
    _startAutoplay();
  }

  void _onEntranceTick() {
    if (!mounted) return;
    if (_positionEntrance) {
      // Stream `_position` from entranceStartOffset → initialPosition.
      // The eased lerp drives the cards past the viewport directly so
      // consumers' `onPositionChanged` sees the full sweep — matches
      // the original Innopay sheet's behaviour where the focused index
      // really does scroll from -9 to 0.
      final t = widget.entranceCurve.transform(_entranceController.value);
      _position = widget.entranceStartOffset +
          (widget.initialPosition - widget.entranceStartOffset) * t;
      widget.onPositionChanged?.call(_position);
    }
    setState(() {});
  }

  void _onSnapTick() {
    final anim = _snapAnim;
    if (anim == null) return;
    setState(() {
      _position = anim.value;
    });
    widget.onPositionChanged?.call(_position);
  }

  /// Pumps a rebuild every nudge frame so the focused card's `dy`
  /// re-evaluates against the new controller value. Without this the
  /// nudge would tick internally but the screen wouldn't repaint —
  /// the down half coincides with the tail of [_entranceController]
  /// (which DOES rebuild), but the reverse plays past the entrance and
  /// would freeze mid-bob.
  void _onNudgeTick() {
    if (mounted) setState(() {});
  }

  void _playNudgeOnce() {
    if (_nudgePlayed || !mounted) return;
    _nudgePlayed = true;
    _nudgeController.forward(from: 0).then((_) {
      if (mounted) _nudgeController.reverse();
    });
  }

  /// Wraps a raw integer index to `[0, itemCount)` when [circular] is on.
  /// Dart's `%` is positive for positive divisor, but only for
  /// non-negative dividends — the extra `+ itemCount` keeps negatives
  /// (e.g. when the user scrolls past index 0 leftward) safe.
  int _wrappedIndex(int raw) {
    if (!widget.circular) return raw;
    final n = widget.itemCount;
    return ((raw % n) + n) % n;
  }

  void _notifyIndexIfChanged() {
    final settled = _wrappedIndex(_position.round());
    if (settled == _lastReportedIndex) return;
    // Linear mode: ignore out-of-range settled values (shouldn't happen
    // with the drag clamp but defensive). Circular mode: settled is
    // already wrapped to [0, itemCount) by _wrappedIndex.
    if (!widget.circular &&
        (settled < 0 || settled >= widget.itemCount)) {
      return;
    }
    _lastReportedIndex = settled;
    widget.onIndexChanged?.call(settled);
  }

  // ─── Drag handling ─────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_snapController.isAnimating) _snapController.stop();
    // Pause autoplay the moment the user grabs the carousel so the
    // timer doesn't fire under the finger.
    if (widget.pauseOnInteraction) _stopAutoplay();
  }

  void _onDragUpdate(DragUpdateDetails details, double itemSpacing) {
    setState(() {
      _position -= details.delta.dx / itemSpacing;
    });
    widget.onPositionChanged?.call(_position);
  }

  void _onDragEnd(DragEndDetails details, double itemSpacing) {
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final flick = -velocityX / itemSpacing * widget.flickFactor;
    // Resume autoplay when the finger lifts, regardless of snap mode.
    if (widget.pauseOnInteraction && widget.autoplay) _startAutoplay();

    if (!widget.enableSnap) {
      // Free-scroll mode: apply the flick once (as a momentum-style
      // settle), then leave the position wherever it lands. No snap to
      // an integer, no onIndexChanged on snap completion.
      var target = _position + flick;
      if (!widget.circular) {
        target = target.clamp(0.0, (widget.itemCount - 1).toDouble());
      }
      setState(() => _position = target);
      widget.onPositionChanged?.call(_position);
      _notifyIndexIfChanged();
      return;
    }

    var target = (_position + flick).roundToDouble();
    // Circular mode lets target run unbounded — indices wrap via
    // _wrappedIndex. Linear mode clamps to [0, itemCount - 1] so the
    // user feels the end of the list.
    if (!widget.circular) {
      target = target.clamp(0.0, (widget.itemCount - 1).toDouble());
    }

    _snapAnim = Tween<double>(begin: _position, end: target).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutCubic,
      ),
    );
    _snapController.forward(from: 0).whenComplete(_notifyIndexIfChanged);
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // Viewport-scale factor — all pixel-based dimensions (itemWidth,
        // itemHeight, itemSpacing, sideLift, nudgeAmplitude) are
        // multiplied by this so the layout looks identical across
        // screen sizes. When referenceWidth is null, no scaling
        // happens (values used as raw logical pixels).
        final scale = widget.referenceWidth != null && widget.referenceWidth! > 0
            ? width / widget.referenceWidth!
            : 1.0;
        // `itemSpacing` override is treated as a value designed for
        // referenceWidth, so it scales like the rest of the dimensions.
        // `viewportFraction` is already a viewport-relative ratio, so
        // it doesn't need an extra scale factor.
        final itemSpacing = widget.itemSpacing != null
            ? widget.itemSpacing! * scale
            : width * widget.viewportFraction;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, itemSpacing),
          onHorizontalDragEnd: (d) => _onDragEnd(d, itemSpacing),
          child: SizedBox(
            height: (widget.itemHeight + widget.sideLift) * scale + 40 * scale,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: _buildCards(itemSpacing, width, scale),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCards(double itemSpacing, double width, double scale) {
    // Pre-roll: host wants the slot empty for `entranceDelay` before the
    // slide starts. Returning no children keeps the layout in place
    // (the outer SizedBox still reserves space) but nothing paints.
    if (_entranceWaiting) return const <Widget>[];


    // Two entrance modes:
    //   • position-based: `_position` itself is streaming from
    //     entranceStartOffset → initialPosition, so cards already move
    //     past the viewport via their per-slot dx. No extra
    //     displacement needed — entranceX is zero.
    //   • displacement (legacy): keep `_position` fixed and slide cards
    //     in from off-screen right during the first 20 % of the
    //     timeline via an additive entranceX. Faster, snappier arrival.
    final effItemWidth = widget.itemWidth * scale;
    final effItemHeight = widget.itemHeight * scale;
    final effSideLift = widget.sideLift * scale;
    final effNudgeAmplitude = widget.nudgeAmplitude * scale;

    // Arc direction sign — flips both lift and tilt together so the
    // geometry stays consistent. `up` (default): negative sign → cards
    // rise above focus, tops tilt inward. `down`: positive sign →
    // cards drop below focus, tops tilt outward.
    final arcSign = widget.arcDirection == ArcDirection.up ? -1.0 : 1.0;

    final cardHalf = effItemWidth / 2;
    final entranceMax = width / 2 + cardHalf + itemSpacing + 20;
    final double entranceX;
    if (_positionEntrance) {
      entranceX = 0;
    } else {
      final entranceProgress =
          (_entranceController.value / _entrancePortion).clamp(0.0, 1.0);
      final easedT = widget.entranceCurve.transform(entranceProgress);
      entranceX = (1 - easedT) * entranceMax;
    }

    final centerIdx = _position.round();
    final entries = <_CarouselEntry>[];

    for (var i = centerIdx - 2; i <= centerIdx + 2; i++) {
      // Bounded mode skips indices outside the data range. Infinite mode
      // lets the builder receive negative or > itemCount indices — the
      // builder is expected to wrap via modulo when reading content.
      if (!widget.circular && (i < 0 || i >= widget.itemCount)) continue;

      final offset = i - _position;
      final distance = offset.abs();
      if (distance > widget.maxRenderDistance) continue;

      final clamped = offset.clamp(-1.0, 1.0);
      // Side cards tilt + lift are both signed by `arcSign`:
      //   • arcSign = -1 (ArcDirection.up, default): tops lean inward,
      //     cards rise above focus → hanging garland / smile.
      //   • arcSign = +1 (ArcDirection.down): tops lean outward,
      //     cards drop below focus → bowl / inverted smile.
      final angle = arcSign * clamped * widget.maxTilt;
      final swing = clamped.abs() * widget.swingAngleMax;
      final dy = arcSign *
          effSideLift *
          (1 - math.cos(swing)) /
          (1 - math.cos(widget.swingAngleMax));

      final focusWeight = (1.0 - clamped.abs()).clamp(0.0, 1.0);

      // Nudge bob — only the focused card (focusWeight ≈ 1).
      final nudgeDy =
          Curves.easeInOut.transform(_nudgeController.value) *
              effNudgeAmplitude *
              focusWeight;

      final dx = offset * itemSpacing + entranceX;

      // `index` handed to the builder is already wrapped to
      // [0, itemCount) when circular is on — so the builder can index
      // its data array directly, no manual modulo needed.
      final info = CarouselItemInfo(
        index: _wrappedIndex(i),
        offset: offset,
        distance: distance,
        focusWeight: focusWeight,
      );

      // Per-card content. Optionally wrapped in a tap GestureDetector
      // when `widget.onTap` is set — Flutter's gesture arena lets a
      // genuine tap win over the outer horizontal drag, so this doesn't
      // interfere with scrolling.
      Widget card = widget.itemBuilder(context, info);
      if (widget.onTap != null) {
        final rawIndex = i;
        card = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleItemTap(info.index, rawIndex),
          child: card,
        );
      }

      entries.add(
        _CarouselEntry(
          distance: distance,
          child: KeyedSubtree(
            // Stable identity by index — without this, the distance sort
            // below would reorder Stack children every frame and Flutter
            // would re-assign Elements to different configurations,
            // causing flicker on the first frames.
            key: ValueKey('cac-card-$i'),
            child: Transform.translate(
              offset: Offset(dx, dy + nudgeDy),
              child: Transform.rotate(
                angle: angle,
                alignment: Alignment.center,
                // RepaintBoundary sits inside the transforms so the card
                // subtree is rasterised once and cached as a GPU layer.
                // Subsequent drags / nudges just composite the cached
                // bitmap instead of repainting the whole card.
                child: RepaintBoundary(
                  child: SizedBox(
                    width: effItemWidth,
                    height: effItemHeight,
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Sort by distance descending so the focused card paints last (on
    // top). Stable sort isn't critical — the stable keys above keep
    // element identity tied to the underlying index.
    entries.sort((a, b) => b.distance.compareTo(a.distance));
    return entries.map((e) => e.child).toList(growable: false);
  }
}

/// Internal record used to pair a card with its distance-from-focus so
/// the Stack can be sorted before being handed to Flutter.
class _CarouselEntry {
  final double distance;
  final Widget child;
  const _CarouselEntry({required this.distance, required this.child});
}
