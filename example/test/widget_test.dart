import 'package:circular_animated_carousel_example/main.dart';
import 'package:circular_animated_carousel/circular_animated_carousel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app mounts and renders the carousel', (tester) async {
    await tester.pumpWidget(const CarouselExampleApp());

    // The example wires a CircularAnimatedCarousel into a dark Scaffold.
    // Asserting the widget shows up gives us coverage that the package's
    // public API still satisfies what the example asks for — without
    // pinning to specific demo content (the quote text could change).
    expect(find.byType(CarouselExampleApp), findsOneWidget);
    expect(find.byType(CircularAnimatedCarousel), findsOneWidget);
  });
}
