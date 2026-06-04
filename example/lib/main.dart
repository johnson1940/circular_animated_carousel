import 'dart:ui';
import 'package:circular_animated_carousel/circular_animated_carousel.dart';
import 'package:flutter/material.dart';

void main() => runApp(const PremiumCarouselApp());

class PremiumCarouselApp extends StatelessWidget {
  const PremiumCarouselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Carousel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      home: const MainScreen(),
    );
  }
}

class Destination {
  final String title;
  final String location;
  final String imageUrl;
  final Color themeColor;

  const Destination(this.title, this.location, this.imageUrl, this.themeColor);
}

const List<Destination> _destinations = [
  Destination('Santorini', 'Greece', 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800', Colors.blue),
  Destination('Kyoto', 'Japan', 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800', Colors.orange),
  Destination('Zermatt', 'Switzerland', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', Colors.white70),
  Destination('Reykjavik', 'Iceland', 'https://images.unsplash.com/photo-1504109586057-7a2ae83d1338?w=800', Colors.indigo),
  Destination('Bora Bora', 'Polynesia', 'https://images.unsplash.com/photo-1500916434205-0c77489c6cf7?w=800', Colors.cyan),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final controller = CircularAnimatedCarouselController();
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF050505),
                  ],
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              const SizedBox(height: 100),
              const Text(
                'EXPLORE',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w300,
                  color: Colors.white60,
                ),
              ),
              const Text(
                'Luxury Stays',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
              Expanded(
                child: Center(
                  child: CircularAnimatedCarousel(
                    controller: controller,
                    itemCount: _destinations.length,
                    perspective: 0.0015,
                    focusedScale: 1.2,
                    unfocusedScale: 0.8,
                    unfocusedOpacity: 0.5,
                    enableEntrance: true,
                    arcDirection: ArcDirection.down,
                    entranceStartOffset: -9.0,
                    entranceDuration: const Duration(milliseconds: 2400),
                    sideLift: 120,
                    circular: true,
                    itemWidth: 200,
                    itemHeight: 320,
                    itemSpacing: 260,
                    onTap: (i) => debugPrint('Visiting ${_destinations[i].title}'),
                    itemBuilder: (context, info) {
                      final dest = _destinations[info.index];
                      return _PremiumCard(
                        destination: dest,
                        focusWeight: info.focusWeight,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 80), // Clean bottom spacing
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Destination destination;
  final double focusWeight;

  const _PremiumCard({
    required this.destination,
    required this.focusWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: destination.themeColor.withOpacity(0.2 * focusWeight),
            blurRadius: 30 * focusWeight,
            spreadRadius: 2 * focusWeight,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              destination.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
              ),
            ),
            
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: focusWeight,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - focusWeight)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination.location.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            destination.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (focusWeight > 0.1)
              Opacity(
                opacity: focusWeight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15 * focusWeight),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
