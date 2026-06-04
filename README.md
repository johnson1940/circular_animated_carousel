# Circular Animated Carousel 🎡

[![pub package](https://img.shields.io/pub/v/circular_animated_carousel.svg)](https://pub.dev/packages/circular_animated_carousel)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue.svg)](https://flutter.dev)

A premium, gesture-driven circular carousel for Flutter. Designed for high-end showcases—cards, luxury images, or interactive tickets. Featuring **3D Perspective**, **Garland Tilt**, and **Dynamic Focus** effects.

---

### 🌟 Vision
Most carousels are flat. This one has **depth**. As you scroll, items rise and tilt along a gentle arc, receding into 3D space with configurable perspective. It's not just a slider; it's a physical experience.

|         ArcDirection.up (Smile)         |         ArcDirection.down (Bowl)          |
|:---------------------------------------:|:-----------------------------------------:|
| <img src="doc/up_arc.webp" width="300"> | <img src="doc/down_arc.webp" width="300"> |
| *Side items rise above & tilt inward.*  |  *Side items drop below & tilt outward.*  |

---

### ✨ Premium Features

*   🎭 **3D Perspective** — Items recede and "face" the center as they move, creating real physical depth.
*   📐 **Garland Tilt** — Elegant cosine-based arc transitions for both position and rotation.
*   🎯 **Dynamic Focus** — Access `focusWeight` to animate scale, opacity, or custom effects as items enter focus.
*   ✨ **Glassmorphism & Glow** — Built-in support for spotlight-style opacity and focused scaling.
*   🎬 **Cinematic Entrances** — High-end "stream-in" animations that feel alive.
*   📱 **Tactile Feedback** — Integrated haptic "clicks" on every snap.
*   ⌨️ **Accessibility First** — Full support for Screen Readers and Keyboard navigation.
*   📏 **Responsive by Design** — Auto-scales layout proportions across all screen sizes.

---

### 🚀 Getting Started

Add the dependency to your `pubspec.yaml`:

```bash
flutter pub add circular_animated_carousel
```

### 💎 The "Luxury" Setup

Create a high-end experience with just a few lines of code:

```dart
CircularAnimatedCarousel(
  itemCount: 5,
  itemWidth: 240,
  itemHeight: 360,
  perspective: 0.0015,       // Subtle 3D depth
  focusedScale: 1.2,         // Focused item pops out
  unfocusedOpacity: 0.5,     // Side items fade into background
  sideLift: 100,             // Elegant arc height
  circular: true,            // Infinite looping
  entranceDuration: Duration(milliseconds: 2400),
  itemBuilder: (context, info) => MyPremiumCard(
    focusWeight: info.focusWeight, // Animate internals based on focus
  ),
)
```

---

### 🎮 Total Control

The `CircularAnimatedCarouselController` gives you programmatic power:

```dart
final controller = CircularAnimatedCarouselController();

// Navigate smoothly
controller.next();
controller.previous();
controller.animateTo(3);

// Observe state
print(controller.currentIndex);     // Current focused index
print(controller.currentPosition);  // Live fractional position
```

---

### 🛠️ Configuration

| Property | Default | Description |
| :--- | :--- | :--- |
| `perspective` | `0.001` | The intensity of the 3D distortion. |
| `focusedScale` | `1.0` | Scale multiplier for the focused item. |
| `unfocusedScale` | `1.0` | Scale multiplier for side items. |
| `unfocusedOpacity`| `1.0` | Opacity of side items (spotlight effect). |
| `sideLift` | `80.0` | How high/low the arc reaches. |
| `arcDirection` | `up` | `ArcDirection.up` (Smile) or `down` (Bowl). |
| `circular` | `false` | Enable infinite looping. |
| `enableSnap` | `true` | Snaps to the nearest item after drag. |
| `autoplay` | `false` | Auto-advance timer. |

---

### 🌍 Accessibility & Web

This package is optimized for all platforms:
- **Keyboard:** Use Left/Right arrows to navigate.
- **Screen Readers:** Semantic labels automatically identify "Item X of Y".
- **Haptics:** Light vibration on every selection change.

---

### 📖 Example
Check out the [`example`](example/) folder for a complete **Luxury Destination Showcase** featuring Unsplash imagery and glassmorphism effects.

```bash
cd example && flutter run
```

---

### 📄 License
MIT © [Johnson](https://github.com/johnson1940)
