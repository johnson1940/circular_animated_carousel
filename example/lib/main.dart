import 'package:circular_animated_carousel/circular_animated_carousel.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CarouselExampleApp());

/// Scaffold background — referenced by the ticket/coupon "notch" circles
/// so they punch a clean bite out of the card edge.
const _bg = Color(0xFF0E0E12);

class CarouselExampleApp extends StatelessWidget {
  const CarouselExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'circular_animated_carousel demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: _bg,
      ),
      home: const ShowcaseScreen(),
    );
  }
}

/// The four content showcases. Each carries its own *natural* arc
/// direction so both [ArcDirection.up] (smile) and [ArcDirection.down]
/// (bowl) are on display as you flip between demos — and the arc can
/// still be toggled live from the control bar.
enum _Demo {
  quotes('Quotes', ArcDirection.up),
  gallery('Gallery', ArcDirection.down),
  coupons('Coupons', ArcDirection.up),
  tickets('Tickets', ArcDirection.down);

  const _Demo(this.label, this.defaultArc);
  final String label;
  final ArcDirection defaultArc;
}

/// A single interactive screen that drives one [CircularAnimatedCarousel]
/// through every content type and every toggle the package exposes.
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  _Demo _demo = _Demo.quotes;
  late ArcDirection _arc = _demo.defaultArc;
  bool _circular = true;
  bool _autoplay = false;
  bool _snap = true;

  /// Live fractional position, updated on every drag/snap/entrance tick.
  /// Held in a notifier so the readout repaints without rebuilding the
  /// carousel itself.
  final ValueNotifier<double> _position = ValueNotifier<double>(0);

  /// One controller per demo. Each demo's carousel is keyed (so switching
  /// demos remounts it and replays the entrance); giving every demo its
  /// own controller keeps `attach`/`detach` from overlapping across that
  /// remount.
  late final Map<_Demo, CircularAnimatedCarouselController> _controllers = {
    for (final d in _Demo.values) d: CircularAnimatedCarouselController(),
  };

  CircularAnimatedCarouselController get _controller => _controllers[_demo]!;

  @override
  void dispose() {
    _position.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectDemo(_Demo d) {
    setState(() {
      _demo = d;
      _arc = d.defaultArc;
      _position.value = 0;
    });
  }

  int get _itemCount => switch (_demo) {
        _Demo.quotes => _quotes.length,
        _Demo.gallery => _photos.length,
        _Demo.coupons => _coupons.length,
        _Demo.tickets => _tickets.length,
      };

  ({double w, double h}) get _itemSize => switch (_demo) {
        _Demo.quotes => (w: 210, h: 300),
        _Demo.gallery => (w: 220, h: 300),
        _Demo.coupons => (w: 230, h: 300),
        _Demo.tickets => (w: 220, h: 320),
      };

  Widget _buildCard(CarouselItemInfo info) {
    // `info.index` is already wrapped to [0, itemCount) in circular mode,
    // so the data lists can be indexed directly.
    switch (_demo) {
      case _Demo.quotes:
        return _QuoteCard(
            quote: _quotes[info.index], focusWeight: info.focusWeight);
      case _Demo.gallery:
        return _GalleryCard(
            photo: _photos[info.index], focusWeight: info.focusWeight);
      case _Demo.coupons:
        return _CouponCard(
            coupon: _coupons[info.index], focusWeight: info.focusWeight);
      case _Demo.tickets:
        return _TicketCard(
            ticket: _tickets[info.index], focusWeight: info.focusWeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _itemSize;
    return Scaffold(
      appBar: AppBar(
        title: const Text('circular_animated_carousel'),
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _DemoSelector(value: _demo, onChanged: _selectDemo),
            Expanded(
              child: Center(
                child: CircularAnimatedCarousel(
                  // Remount (and replay the entrance) when the content
                  // type changes.
                  key: ValueKey(_demo),
                  controller: _controller,
                  itemCount: _itemCount,
                  itemWidth: size.w,
                  itemHeight: size.h,
                  circular: _circular,
                  autoplay: _autoplay,
                  enableSnap: _snap,
                  arcDirection: _arc,
                  itemSpacing: 280,
                  entranceDuration: const Duration(milliseconds: 1000),
                  // Enabling onTap turns on tap-to-focus: tapping a side
                  // card animates it into the centre.
                  onTap: (_) {},
                  onPositionChanged: (p) => _position.value = p,
                  itemBuilder: (context, info) => _buildCard(info),
                ),
              ),
            ),
            _ControlBar(
              circular: _circular,
              autoplay: _autoplay,
              snap: _snap,
              arc: _arc,
              itemCount: _itemCount,
              position: _position,
              onCircular: (v) => setState(() => _circular = v),
              onAutoplay: (v) => setState(() => _autoplay = v),
              onSnap: (v) => setState(() => _snap = v),
              onToggleArc: () => setState(() => _arc =
                  _arc == ArcDirection.up ? ArcDirection.down : ArcDirection.up),
              onPrevious: () => _controller.previous(),
              onNext: () => _controller.next(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chrome ──────────────────────────────────────────────────────────────

/// Segmented selector across the four content types.
class _DemoSelector extends StatelessWidget {
  final _Demo value;
  final ValueChanged<_Demo> onChanged;
  const _DemoSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<_Demo>(
          showSelectedIcon: false,
          segments: [
            for (final d in _Demo.values)
              ButtonSegment(value: d, label: Text(d.label)),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

/// Toggles (circular / autoplay / snap / arc), prev-next buttons, and the
/// live position + index readout.
class _ControlBar extends StatelessWidget {
  final bool circular;
  final bool autoplay;
  final bool snap;
  final ArcDirection arc;
  final int itemCount;
  final ValueNotifier<double> position;
  final ValueChanged<bool> onCircular;
  final ValueChanged<bool> onAutoplay;
  final ValueChanged<bool> onSnap;
  final VoidCallback onToggleArc;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _ControlBar({
    required this.circular,
    required this.autoplay,
    required this.snap,
    required this.arc,
    required this.itemCount,
    required this.position,
    required this.onCircular,
    required this.onAutoplay,
    required this.onSnap,
    required this.onToggleArc,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final arcUp = arc == ArcDirection.up;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF16161D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: position,
            builder: (context, p, _) {
              final idx = circular
                  ? ((p.round() % itemCount) + itemCount) % itemCount
                  : p.round().clamp(0, itemCount - 1);
              return Text(
                'index $idx   •   position ${p.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilterChip(
                label: const Text('Circular'),
                selected: circular,
                onSelected: onCircular,
              ),
              FilterChip(
                label: const Text('Autoplay'),
                selected: autoplay,
                onSelected: onAutoplay,
              ),
              FilterChip(
                label: const Text('Snap'),
                selected: snap,
                onSelected: onSnap,
              ),
              ActionChip(
                avatar: Icon(arcUp
                    ? Icons.sentiment_satisfied_alt
                    : Icons.sentiment_dissatisfied),
                label: Text('Arc: ${arcUp ? 'up' : 'down'}'),
                onPressed: onToggleArc,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Tap a side card, drag, or use the arrows',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared card primitives ───────────────────────────────────────────────

/// A horizontal dashed rule sized to its parent's width.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const dash = 6.0;
        const gap = 5.0;
        final count = (c.maxWidth / (dash + gap)).floor().clamp(1, 200);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: dash,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A scaffold-coloured circle that bites into a card edge to fake a
/// ticket/coupon perforation notch. [yFraction] is the vertical position
/// (0 = top, 1 = bottom) of the tear line it sits on.
class _EdgeNotches extends StatelessWidget {
  final double yFraction;
  const _EdgeNotches({required this.yFraction});

  @override
  Widget build(BuildContext context) {
    final align = yFraction * 2 - 1;
    const notch = SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
      ),
    );
    return Stack(
      children: [
        Align(alignment: Alignment(-1, align), child: notch),
        Align(alignment: Alignment(1, align), child: notch),
      ],
    );
  }
}

// ─── Quotes ────────────────────────────────────────────────────────────────

class _Quote {
  final String text;
  final String author;
  final Color start;
  final Color end;
  const _Quote(this.text, this.author, this.start, this.end);
}

const _quotes = <_Quote>[
  _Quote('The only way to do great work is to love what you do.', 'Steve Jobs',
      Color(0xFF7B1FFA), Color(0xFF3D0A8C)),
  _Quote(
      'Success is not final, failure is not fatal — it is the courage to continue that counts.',
      'Winston Churchill',
      Color(0xFFFA7B1F),
      Color(0xFF8C3D0A)),
  _Quote('Be yourself; everyone else is already taken.', 'Oscar Wilde',
      Color(0xFFFA1F7B), Color(0xFF8C0A3D)),
  _Quote('In the middle of difficulty lies opportunity.', 'Albert Einstein',
      Color(0xFF1F7BFA), Color(0xFF0A3D8C)),
  _Quote('The journey of a thousand miles begins with one step.', 'Lao Tzu',
      Color(0xFF00B894), Color(0xFF066B57)),
];

/// Gradient quote card — drop shadow, body size, and author opacity all
/// ride on [focusWeight] so the centred card pops.
class _QuoteCard extends StatelessWidget {
  final _Quote quote;
  final double focusWeight;
  const _QuoteCard({required this.quote, required this.focusWeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [quote.start, quote.end],
        ),
        borderRadius: BorderRadius.circular(24),
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

// ─── Gallery ─────────────────────────────────────────────────────────────

class _Photo {
  final String seed;
  final String title;
  const _Photo(this.seed, this.title);

  String get url => 'https://picsum.photos/seed/$seed/440/600';
}

const _photos = <_Photo>[
  _Photo('arch-canyon', 'Desert Arch'),
  _Photo('pine-forest', 'Pine Forest'),
  _Photo('neon-city', 'Neon City'),
  _Photo('ocean-wave', 'Ocean Wave'),
  _Photo('snow-peak', 'Snow Peak'),
  _Photo('aurora-sky', 'Aurora Sky'),
];

/// Image card — side images dim and the caption fades out as
/// [focusWeight] drops, so the centred photo is the clear subject.
class _GalleryCard extends StatelessWidget {
  final _Photo photo;
  final double focusWeight;
  const _GalleryCard({required this.photo, required this.focusWeight});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photo.url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const ColoredBox(
                    color: Color(0xFF1A1A22),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
            errorBuilder: (context, error, stack) => const ColoredBox(
              color: Color(0xFF1A1A22),
              child: Icon(Icons.image_not_supported_outlined,
                  color: Colors.white24, size: 36),
            ),
          ),
          // Dim side cards.
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.45 * (1 - focusWeight)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: Opacity(
                opacity: focusWeight,
                child: Text(
                  photo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Coupons ─────────────────────────────────────────────────────────────

class _Coupon {
  final String store;
  final String headline;
  final String detail;
  final String code;
  final Color color;
  const _Coupon(
      this.store, this.headline, this.detail, this.code, this.color);
}

const _coupons = <_Coupon>[
  _Coupon('NOVA COFFEE', '50% OFF', 'Any handcrafted drink', 'NOVA50',
      Color(0xFFE5533C)),
  _Coupon('URBAN THREADS', '\$25 OFF', 'Orders over \$100', 'STYLE25',
      Color(0xFF6C5CE7)),
  _Coupon('FRESH MART', 'BUY 1 GET 1', 'On all fresh produce', 'BOGOFRESH',
      Color(0xFF16A34A)),
  _Coupon('PIXEL PLAY', '30% OFF', 'Annual game pass', 'PLAY30',
      Color(0xFF0EA5E9)),
  _Coupon('AERO FITNESS', '1 MONTH FREE', 'New annual members', 'FIT1FREE',
      Color(0xFFD946A6)),
];

/// Coupon card — colour header with the offer, a perforated tear line
/// with edge notches, and a redeem button whose glow rides [focusWeight].
class _CouponCard extends StatelessWidget {
  final _Coupon coupon;
  final double focusWeight;
  const _CouponCard({required this.coupon, required this.focusWeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header — the offer.
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        coupon.color,
                        Color.lerp(coupon.color, Colors.black, 0.35)!,
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        coupon.store,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coupon.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        coupon.detail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer — code + redeem.
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _DashedLine(),
                      Row(
                        children: [
                          Text(
                            'CODE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            coupon.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: coupon.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  coupon.color.withValues(alpha: 0.6 * focusWeight),
                              blurRadius: 18 * focusWeight,
                              spreadRadius: 1 * focusWeight,
                            ),
                          ],
                        ),
                        child: const Text(
                          'REDEEM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tear line sits at the 3:2 split → 60% down the card.
        const Positioned.fill(child: _EdgeNotches(yFraction: 0.6)),
      ],
    );
  }
}

// ─── Tickets ─────────────────────────────────────────────────────────────

class _Ticket {
  final String event;
  final String artist;
  final String date;
  final String seat;
  final Color color;
  const _Ticket(this.event, this.artist, this.date, this.seat, this.color);
}

const _tickets = <_Ticket>[
  _Ticket('SYNTH NIGHTS', 'Aurora Wave', 'FRI · 12 SEP · 20:00', 'GA · ROW 4',
      Color(0xFF8B5CF6)),
  _Ticket('JAZZ IN THE PARK', 'The Blue Quartet', 'SUN · 21 SEP · 18:30',
      'SEC B · R12 · S7', Color(0xFF0EA5E9)),
  _Ticket('INDIE FEST', 'Paper Lanterns', 'SAT · 04 OCT · 16:00', 'VIP · STANDING',
      Color(0xFFF59E0B)),
  _Ticket('CITY MARATHON', 'Wave Start C', 'SUN · 19 OCT · 07:00', 'BIB · 2048',
      Color(0xFF10B981)),
];

/// Event ticket — gradient stub with the event details, a perforation,
/// then a barcode footer whose contrast rises with [focusWeight].
class _TicketCard extends StatelessWidget {
  final _Ticket ticket;
  final double focusWeight;
  const _TicketCard({required this.ticket, required this.focusWeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C26),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ticket.color.withValues(alpha: 0.4 * focusWeight),
                blurRadius: 34 * focusWeight,
                spreadRadius: 2 * focusWeight,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ticket.color,
                        Color.lerp(ticket.color, Colors.black, 0.45)!,
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'E-TICKET',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        ticket.event,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.artist,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ticket.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket.seat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _Barcode(opacity: 0.4 + 0.6 * focusWeight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Perforation at the 7:3 split → 70% down the card.
        const Positioned.fill(child: _EdgeNotches(yFraction: 0.7)),
      ],
    );
  }
}

/// A faux barcode — fixed bar pattern so it renders identically every
/// frame (no per-frame randomness to fight the carousel's caching).
class _Barcode extends StatelessWidget {
  final double opacity;
  const _Barcode({required this.opacity});

  static const _pattern = '3112213122312133122131233211';

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _pattern.length; i++)
              Container(
                width: int.parse(_pattern[i]) * 1.7,
                color: i.isEven ? Colors.white : Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
