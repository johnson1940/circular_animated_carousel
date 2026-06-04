import 'package:circular_animated_carousel/circular_animated_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircularAnimatedCarousel', () {
    testWidgets('renders cards within maxRenderDistance', (tester) async {
      final builtIndices = <int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 10,
                enableEntrance: false,
                enableNudge: false,
                itemBuilder: (context, info) {
                  builtIndices.add(info.index);
                  return Container(
                    key: ValueKey('card-${info.index}'),
                    color: Colors.blue,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // At rest, position=0 → cards within distance 1.5 are: 0 (focused)
      // and 1 (next). Indices -1, -2 are clipped (below 0); 2 is clipped
      // (distance > 1.5).
      expect(builtIndices, containsAll([0, 1]));
      expect(
        builtIndices.contains(2),
        isFalse,
        reason: 'index 2 is at distance 2.0, outside maxRenderDistance',
      );
    });

    testWidgets('focused card reports focusWeight ≈ 1.0', (tester) async {
      double? focusedWeight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 3,
                initialPosition: 1,
                enableEntrance: false,
                enableNudge: false,
                itemBuilder: (context, info) {
                  if (info.index == 1) focusedWeight = info.focusWeight;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(focusedWeight, isNotNull);
      expect(focusedWeight, closeTo(1.0, 1e-9));
    });

    testWidgets('onIndexChanged fires after snap settles', (tester) async {
      final reported = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 5,
                enableEntrance: false,
                enableNudge: false,
                onIndexChanged: reported.add,
                itemBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      // Drag left ≈ one slot. viewportFraction defaults to 0.65, viewport
      // 400 → itemSpacing 260. Drag the gesture across 260 px so the
      // carousel lands exactly on index 1.
      await tester.drag(
        find.byType(CircularAnimatedCarousel),
        const Offset(-260, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last, 1);
    });
  });

  group('CircularAnimatedCarouselController', () {
    testWidgets('next() advances by one and fires onIndexChanged',
        (tester) async {
      final controller = CircularAnimatedCarouselController();
      final reported = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 5,
                controller: controller,
                enableEntrance: false,
                enableNudge: false,
                onIndexChanged: reported.add,
                itemBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(controller.currentIndex, 0);
      // Don't `await` the controller call — its Future only completes
      // when the snap animation finishes, but the snap can't advance
      // until `tester.pumpAndSettle()` pumps frames. Awaiting first
      // deadlocks the test. Fire-and-forget, then pump.
      controller.next();
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(reported.last, 1);
      controller.dispose();
    });

    testWidgets('jumpTo() moves immediately without animation',
        (tester) async {
      final controller = CircularAnimatedCarouselController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 10,
                controller: controller,
                enableEntrance: false,
                enableNudge: false,
                itemBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      controller.jumpTo(7);
      await tester.pump();
      expect(controller.currentIndex, 7);
      expect(controller.currentPosition, 7.0);
      controller.dispose();
    });

    testWidgets('previous() at index 0 is a no-op in linear mode',
        (tester) async {
      final controller = CircularAnimatedCarouselController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 5,
                controller: controller,
                circular: false,
                enableEntrance: false,
                enableNudge: false,
                itemBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      controller.previous();
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 0);
      controller.dispose();
    });

    testWidgets('previous() at index 0 wraps to last in circular mode',
        (tester) async {
      final controller = CircularAnimatedCarouselController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CircularAnimatedCarousel(
                itemCount: 5,
                controller: controller,
                circular: true,
                enableEntrance: false,
                enableNudge: false,
                itemBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      controller.previous();
      await tester.pumpAndSettle();
      // -1 wraps to 4.
      expect(controller.currentIndex, 4);
      controller.dispose();
    });
  });

  testWidgets('onTap fires with the tapped item index', (tester) async {
    final taps = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: CircularAnimatedCarousel(
              itemCount: 5,
              enableEntrance: false,
              enableNudge: false,
              onTap: taps.add,
              itemBuilder: (_, info) => Container(
                key: ValueKey('item-${info.index}'),
                color: const Color(0xFFEEEEEE),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap the focused (centre) item.
    await tester.tap(find.byKey(const ValueKey('item-0')));
    await tester.pumpAndSettle();

    expect(taps, isNotEmpty);
    expect(taps.last, 0);
  });

  group('route teardown', () {
    testWidgets(
        'settles the entrance when the hosting route pops (no focus flash)',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      // Non-focused indices that momentarily reached full focus while the
      // route was popping — i.e. a neighbour "flash" mid-slide-out.
      final flashedWhilePopping = <int>{};
      var popping = false;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => navKey.currentState!.push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Center(
                          child: CircularAnimatedCarousel(
                            itemCount: 5,
                            circular: true,
                            initialPosition: 0,
                            // Long position-stream entrance: `_position`
                            // sweeps -9 → 0 through every index.
                            entranceStartOffset: -9.0,
                            entranceDuration:
                                const Duration(milliseconds: 2000),
                            enableNudge: false,
                            itemBuilder: (_, info) {
                              // When settled at index 0, every neighbour
                              // has focusWeight 0. Any non-focused index
                              // climbing past 0.5 means the carousel is
                              // still streaming — a neighbour sweeping
                              // through focus = the flash.
                              if (popping &&
                                  info.focusWeight > 0.5 &&
                                  info.index != 0) {
                                flashedWhilePopping.add(info.index);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );

      // Push the carousel route and advance only partway into the 2 s
      // entrance, so `_position` is still streaming when we pop.
      await tester.tap(find.text('go'));
      await tester.pump(); // build the pushed route
      await tester.pump(const Duration(milliseconds: 300));

      // Pop and pump through the exit transition in fine steps so we
      // actually sample frames while a still-running entrance would be
      // streaming neighbours through focus.
      popping = true;
      navKey.currentState!.pop();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();

      expect(
        flashedWhilePopping,
        isEmpty,
        reason: 'no non-focused index should reach full focus during the '
            'route pop — the entrance must settle to initialPosition '
            'instead of streaming through neighbours while the page '
            'slides away',
      );
    });
  });
}
