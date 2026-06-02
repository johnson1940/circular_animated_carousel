import 'package:flutter/widgets.dart';

/// Per-item state passed into [CarouselItemBuilder]. Items can be cards,
/// images, custom painters, or any widget — the carousel only cares
/// about distance-from-focus, not what's inside. Use these fields to
/// tint, scale, halo, or otherwise emphasise the focused item without
/// duplicating the carousel's offset math.
@immutable
class CarouselItemInfo {
  /// This item's index. Use `index % palette.length` (or similar) when
  /// you want to cycle through a finite set of colours / images across
  /// an effectively infinite carousel.
  final int index;

  /// Signed distance from the focused position, in slot units.
  /// `0.0` = exactly centered. Negative = item sits to the left.
  /// Positive = item sits to the right.
  final double offset;

  /// Absolute distance from focus (`offset.abs()`). Handy when you only
  /// care about "how far" not "which side".
  final double distance;

  /// `1.0` when this item is exactly focused, `0.0` at the neighbouring
  /// slot, and clamped to `[0, 1]` mid-drag. Wire this into halo alpha,
  /// scale, opacity, etc.
  final double focusWeight;

  const CarouselItemInfo({
    required this.index,
    required this.offset,
    required this.distance,
    required this.focusWeight,
  });
}

/// Builder signature consumers pass to the carousel. Returns the widget
/// to render at the given [CarouselItemInfo] slot — typically a card or
/// image but anything that fits in a `SizedBox(itemWidth, itemHeight)`
/// works.
typedef CarouselItemBuilder = Widget Function(
  BuildContext context,
  CarouselItemInfo info,
);

/// Deprecated alias kept for backwards compatibility with v0.0.1. Use
/// [CarouselItemInfo] instead.
@Deprecated('Renamed to CarouselItemInfo')
typedef CarouselCardInfo = CarouselItemInfo;

/// Which side of the focused item the arc's neighbouring items live on.
///
/// The two values flip both the **lift** (whether side items rise above
/// or drop below the focused one) AND the **tilt** (whether their tops
/// lean toward or away from focus). Flipping only one of those would
/// produce a geometrically inconsistent arc, so the package always
/// mirrors them together.
enum ArcDirection {
  /// Side items arc **above** the focused item and tilt their tops
  /// **inward** (toward focus). Visually: a hanging garland or smile.
  /// This is the default — what the package shipped with for v0.0.x.
  up,

  /// Side items arc **below** the focused item and tilt their tops
  /// **outward** (away from focus). Visually: a bowl or inverted
  /// smile. Useful when the focused card should feel like it's at the
  /// peak of a stack rather than the trough.
  down,
}
