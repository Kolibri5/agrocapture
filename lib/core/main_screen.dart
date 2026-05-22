import 'package:flutter/material.dart';
import '../features/map/map_screen.dart';
import '../features/directory/list_screen.dart';
import '../features/scanner/scanner_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// Placeholder screens — will be replaced with real feature widgets
// ═══════════════════════════════════════════════════════════════════

class MapScreenPlaceholder extends StatelessWidget {
  const MapScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Peta Lahan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Map screen akan ditampilkan di sini',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerScreenPlaceholder extends StatelessWidget {
  const ScannerScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner_rounded, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Scanner',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreenPlaceholder extends StatelessWidget {
  const HistoryScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Riwayat',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat scan akan ditampilkan di sini',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MainScreen — root shell with bottom navigation
// ═══════════════════════════════════════════════════════════════════

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  /// Sub-view toggle within the Map tab (false = map, true = list).
  bool _showListView = false;

  /// Returns the body widget for the current tab.
  Widget _currentBody() {
    switch (_currentIndex) {
      case 0:
        // Map tab — toggles between MapScreen and ListScreen
        if (_showListView) {
          return ListScreen(
            onSwitchToMap: () => setState(() => _showListView = false),
          );
        }
        return MapScreen(
          onSwitchToList: () => setState(() => _showListView = true),
        );
      case 2:
        return const HistoryScreenPlaceholder();
      default:
        return const ScannerScreenPlaceholder();
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // Center FAB → push scanner as a full-screen route
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
      // Reset to map view when switching tabs
      if (index != 0) _showListView = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Switch body based on selected tab
      body: _currentBody(),

      // We use extendBody so the nav bar can float over content.
      extendBody: true,

      bottomNavigationBar: _AgrocaptureBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
// Custom bottom navigation bar — matches design mockup exactly
// ═══════════════════════════════════════════════════════════════════

class _AgrocaptureBottomBar extends StatelessWidget {
  const _AgrocaptureBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // ── Design tokens ────────────────────────────────────────────
  static const double _barHeight = 68;
  static const double _fabSize = 62;
  static const double _fabElevation = 6;
  static const double _indicatorWidth = 40;
  static const double _indicatorThickness = 3;
  static const Color _activeColor = Color(0xFF1B6E3C);
  static const Color _inactiveColor = Color(0xFF9E9E9E);
  static const Color _fabColor = Color(0xFF1B6E3C);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Total height = bar + safe-area bottom inset
      height: _barHeight + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: [
            // ── Left tab: Map ──────────────────────────────────
            Expanded(child: _buildSideTab(0, Icons.location_on_outlined, 'Map')),

            // ── Center tab: AGROCAPTURE (raised FAB) ───────────
            _buildCenterFab(),

            // ── Right tab: Riwayat ─────────────────────────────
            Expanded(child: _buildSideTab(2, Icons.history_rounded, 'Riwayat')),
          ],
        ),
      ),
    );
  }

  // ── Side tab (Map / Riwayat) ───────────────────────────────────
  Widget _buildSideTab(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;
    final Color color = isActive ? _activeColor : _inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Green top indicator bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _indicatorWidth,
            height: _indicatorThickness,
            decoration: BoxDecoration(
              color: isActive ? _activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(_indicatorThickness / 2),
            ),
          ),
          const Spacer(),
          // Icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              key: ValueKey('$index-$isActive'),
              size: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Center FAB: AGROCAPTURE ────────────────────────────────────
  Widget _buildCenterFab() {
    final bool isActive = currentIndex == 1;

    return GestureDetector(
      onTap: () => onTap(1),
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The raised circular button — sits above the bar baseline
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: _fabSize,
                height: _fabSize,
                decoration: BoxDecoration(
                  color: _fabColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _fabColor.withValues(alpha: isActive ? 0.45 : 0.25),
                      blurRadius: _fabElevation * 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // Subtle border glow when active
                  border: isActive
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2.5,
                        )
                      : null,
                ),
                child: const Center(
                  child: _AgrocaptureIcon(size: 30, color: Colors.white),
                ),
              ),
            ),
            // Label sits below the circle
            Transform.translate(
              offset: const Offset(0, -10),
              child: Text(
                'AGROCAPTURE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? _activeColor : _inactiveColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Agrocapture logo icon — the recycling-leaf symbol from the design
//
// Drawn with CustomPainter so we don't need an image asset.
// Three curved arrows forming a rounded triangle with a leaf motif.
// ═══════════════════════════════════════════════════════════════════

class _AgrocaptureIcon extends StatelessWidget {
  const _AgrocaptureIcon({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _AgrocaptureIconPainter(color: color)),
    );
  }
}

class _AgrocaptureIconPainter extends CustomPainter {
  _AgrocaptureIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Three vertices of a rounded triangle (pointing up)
    final top = Offset(cx, cy - r);
    final bottomLeft = Offset(cx - r * 0.87, cy + r * 0.5);
    final bottomRight = Offset(cx + r * 0.87, cy + r * 0.5);

    // Draw three curved segments (recycling-style arrows)
    _drawCurvedArrow(canvas, paint, top, bottomRight, cx, cy, size);
    _drawCurvedArrow(canvas, paint, bottomRight, bottomLeft, cx, cy, size);
    _drawCurvedArrow(canvas, paint, bottomLeft, top, cx, cy, size);

    // Small leaf shape at center
    _drawLeaf(canvas, size, cx, cy);
  }

  void _drawCurvedArrow(
    Canvas canvas,
    Paint paint,
    Offset from,
    Offset to,
    double cx,
    double cy,
    Size size,
  ) {
    // Curve toward center
    final ctrl = Offset(
      cx + (from.dx + to.dx - 2 * cx) * 0.15,
      cy + (from.dy + to.dy - 2 * cy) * 0.15,
    );

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

    canvas.drawPath(path, paint);

    // Arrowhead
    final arrowSize = size.width * 0.13;
    final dx = to.dx - ctrl.dx;
    final dy = to.dy - ctrl.dy;
    final len = (dx * dx + dy * dy);
    if (len == 0) return;
    final mag = 1.0 / (len > 0 ? len.toDouble() : 1.0);
    final ndx = dx * mag * arrowSize;
    final ndy = dy * mag * arrowSize;

    // Simple chevron arrow
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final a1 = Offset(to.dx - ndx + ndy * 0.6, to.dy - ndy - ndx * 0.6);
    final a2 = Offset(to.dx - ndx - ndy * 0.6, to.dy - ndy + ndx * 0.6);
    canvas.drawLine(a1, to, arrowPaint);
    canvas.drawLine(a2, to, arrowPaint);
  }

  void _drawLeaf(Canvas canvas, Size size, double cx, double cy) {
    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final leafSize = size.width * 0.13;
    final path = Path()
      ..moveTo(cx, cy - leafSize)
      ..quadraticBezierTo(cx + leafSize, cy, cx, cy + leafSize)
      ..quadraticBezierTo(cx - leafSize, cy, cx, cy - leafSize)
      ..close();

    canvas.drawPath(path, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
