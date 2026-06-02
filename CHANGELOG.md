## 0.1.0

First public release.

### Layout
- Continuous double position — smooth interpolation mid-drag, not just paged
  snaps.
- Distance-sorted Z-order: focused item always paints on top.
- Garland tilt: side items lean inward (or outward in inverted mode) at
  `±maxTilt` radians.
- Cosine side-lift arc — side items rise above the focused one (or drop
  below in inverted mode) along a configurable swing angle.
- Stable `ValueKey`s per slot so the distance sort doesn't reorder Element
  identities frame-to-frame.
- `RepaintBoundary` per item — every card subtree rasterised once and cached
  as a GPU layer.

### Modes & axes
- `circular: bool` — when true, last item wraps back to the first and
  `info.index` is auto-wrapped to `[0, itemCount)` so builders can index
  data arrays directly. When false, list is bounded.
- `ArcDirection.up` / `ArcDirection.down` — flip the arc to either a
  hanging-garland (default) or a bowl/inverted-smile shape. Lift and tilt
  flip together so the geometry stays consistent.

### Entrance
- Two entrance modes, picked by `entranceStartOffset`:
  - **Position-stream** (non-zero) — `_position` itself tweens from the
    start offset to `initialPosition` over the full duration, so items
    visibly scroll past from the right.
  - **Displacement slide** (zero) — items slide in from off-screen right
    during the first 20 % of the duration. Faster, sharper arrival.
- `entranceDelay` — hold the carousel blank for a beat before the slide
  starts. Lets host bottom-sheets / modals finish their open animation.
- `entranceCurve` — pluggable curve for both entrance modes.

### Interaction
- Horizontal drag + flick with velocity-aware snap-to-index.
- `enableSnap: false` for free-scroll galleries.
- `onTap` per item; non-focused taps auto-animate the focus to that item.
- One-shot focus nudge bob (`enableNudge`) after the entrance settles to
  hint at vertical interactions.
- `autoplay` with `autoplayInterval` and `pauseOnInteraction` (default true).

### Programmatic control
- `CircularAnimatedCarouselController` with `next`, `previous`, `animateTo`,
  `jumpTo`, `currentIndex`, `currentPosition`.
- Optional `duration` / `curve` overrides on `animateTo` / `next` / `previous`.

### Responsive sizing
- `referenceWidth` (default `360`) — pixel dimensions (`itemWidth`,
  `itemHeight`, `itemSpacing`, `sideLift`, `nudgeAmplitude`) are treated as
  designed for this baseline viewport and scale linearly with the actual
  viewport. Pass `null` to opt out and use raw logical pixels.
- `itemSpacing` (absolute, scaled by `referenceWidth`) or
  `viewportFraction` (proportional). Spacing override wins when both are
  present.

### Callbacks
- `onIndexChanged(int)` — fires once per settled integer index.
- `onPositionChanged(double)` — fires on every drag tick / snap tick /
  entrance tick with the live fractional position. Use this for continuous
  effects that need to blend between adjacent items (e.g. a glow colour
  interpolating across two palettes mid-drag).
