import 'package:circular_animated_carousel/circular_animated_carousel.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CarouselExampleApp());

class CarouselExampleApp extends StatelessWidget {
  const CarouselExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'circular_animated_carousel demo',
      // Dark theme — uses a deep neutral background so the gradient
      // quote cards pop without competing chrome.
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
      ),
      home: const _DemoScreen(),
    );
  }
}

/// A single quote card payload — quote text, author, and the two
/// gradient colours used for the card background.
class _Quote {
  final String text;
  final String author;
  final Color start;
  final Color end;
  const _Quote(this.text, this.author, this.start, this.end);
}

class _DemoScreen extends StatelessWidget {
  const _DemoScreen();

  static const _quotes = <_Quote>[
    _Quote(
      'The only way to do great work is to love what you do.',
      'Steve Jobs',
      Color(0xFF7B1FFA),
      Color(0xFF3D0A8C),
    ),
    _Quote(
      'Success is not final, failure is not fatal — it is the courage to continue that counts.',
      'Winston Churchill',
      Color(0xFFFA7B1F),
      Color(0xFF8C3D0A),
    ),
    _Quote(
      'Be yourself; everyone else is already taken.',
      'Oscar Wilde',
      Color(0xFFFA1F7B),
      Color(0xFF8C0A3D),
    ),
    _Quote(
      'In the middle of difficulty lies opportunity.',
      'Albert Einstein',
      Color(0xFF1F7BFA),
      Color(0xFF0A3D8C),
    ),
    _Quote(
      'The journey of a thousand miles begins with one step.',
      'Lao Tzu',
      Color(0xFF00B894),
      Color(0xFF066B57),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularAnimatedCarousel(
          itemCount: _quotes.length,
          itemWidth: 210,
          itemHeight: 300,
          itemSpacing: 255,
          circular: true,
          entranceStartOffset: -9.0,
          entranceDelay: const Duration(milliseconds: 180),
          entranceDuration: const Duration(milliseconds: 2400),
          itemBuilder: (context, info) => _QuoteCard(
            quote: _quotes[info.index],
            focusWeight: info.focusWeight,
          ),
        ),
      ),
    );
  }
}

/// A luxurious quote card — gradient backdrop, oversized opening
/// quote-mark glyph in the top-left, italic body text in the middle,
/// and a thin author attribution pinned to the bottom-right.
///
/// Several visual properties ride on [focusWeight] so the focused card
/// pops without changing layout:
///   • drop shadow blur/alpha (halo grows)
///   • inner highlight alpha (subtle glass effect)
///   • body font size
///   • author opacity
class _QuoteCard extends StatelessWidget {
  final _Quote quote;
  final double focusWeight;

  const _QuoteCard({
    required this.quote,
    required this.focusWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Two-stop diagonal gradient — brighter top-left, deeper
        // bottom-right. Gives the card depth without needing an image.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [quote.start, quote.end],
        ),
        borderRadius: BorderRadius.circular(24),
        // Coloured halo — alpha + blur ride on focusWeight so the
        // centred card glows and side cards stay flat.
        boxShadow: [
          BoxShadow(
            color: quote.start.withValues(alpha: 0.55 * focusWeight),
            blurRadius: 40 * focusWeight,
            spreadRadius: 4 * focusWeight,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top-left oversized opening quote glyph. Sits behind the
          // body text as a watermark — low opacity, large size.
          Positioned(
            left: 16,
            top: -8,
            child: Text(
              '“',
              style: TextStyle(
                fontSize: 110,
                height: 1,
                color: Colors.white.withValues(alpha: 0.22),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Subtle inner highlight stripe along the top edge — fakes a
          // glass reflection. Fades out on side cards.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.5 * focusWeight),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Body — quote text centred vertically, author bottom-right.
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 64, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      quote.text,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17 + 1.5 * focusWeight,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.7 + 0.3 * focusWeight),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
