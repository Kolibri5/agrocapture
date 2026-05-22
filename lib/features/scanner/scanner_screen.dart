import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════
// Mock data — rigged results for each dummy leaf asset
// ═══════════════════════════════════════════════════════════════════════

class MockLeaf {
  final String assetPath;
  final String name;
  final String confidence;
  final String description;
  final Color thumbnailColor;

  const MockLeaf({
    required this.assetPath,
    required this.name,
    required this.confidence,
    required this.description,
    required this.thumbnailColor,
  });
}

const List<MockLeaf> _kMockLeaves = [
  MockLeaf(
    assetPath: 'assets/images/dummy_leaves/arabica.jpg',
    name: 'Arabica',
    confidence: '86% confidence',
    description:
        'Lorem ipsum dolor sit amet consectetur. '
        'Integer cursus nulla ullamcorper est dictum '
        'risus elit dapibus.',
    thumbnailColor: Color(0xFF2D5A27),
  ),
  MockLeaf(
    assetPath: 'assets/images/dummy_leaves/robusta.jpg',
    name: 'Robusta',
    confidence: '92% confidence',
    description:
        'Lorem ipsum dolor sit amet consectetur. '
        'Integer cursus nulla ullamcorper est dictum '
        'risus elit dapibus.',
    thumbnailColor: Color(0xFF3E7A35),
  ),
  MockLeaf(
    assetPath: 'assets/images/dummy_leaves/excelsa.jpg',
    name: 'Excelsa',
    confidence: '78% confidence',
    description:
        'Lorem ipsum dolor sit amet consectetur. '
        'Integer cursus nulla ullamcorper est dictum '
        'risus elit dapibus.',
    thumbnailColor: Color(0xFF4A8B3F),
  ),
  MockLeaf(
    assetPath: 'assets/images/dummy_leaves/liberika.jpg',
    name: 'Liberika',
    confidence: '81% confidence',
    description:
        'Lorem ipsum dolor sit amet consectetur. '
        'Integer cursus nulla ullamcorper est dictum '
        'risus elit dapibus.',
    thumbnailColor: Color(0xFF1E4D1A),
  ),
];

// ═══════════════════════════════════════════════════════════════════════
// Scan state machine
// ═══════════════════════════════════════════════════════════════════════

enum _ScanState { idle, scanning, scanned, result }

// ═══════════════════════════════════════════════════════════════════════
// ScannerScreen — full-screen camera viewfinder with rigged demo flow
// ═══════════════════════════════════════════════════════════════════════

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  // ── Camera ──────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isFlashOn = false;

  // ── Scan state ──────────────────────────────────────────────────
  _ScanState _scanState = _ScanState.idle;
  MockLeaf? _selectedLeaf;

  // ── Animations ──────────────────────────────────────────────────
  late final AnimationController _pillController;
  late final AnimationController _resultController;
  late final Animation<Offset> _resultSlide;

  // ── Timers ──────────────────────────────────────────────────────
  Timer? _stateTimer;

  // ═════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutCubic,
    ));

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _cameraController?.dispose();
    _pillController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════
  // Actions
  // ═════════════════════════════════════════════════════════════════

  void _toggleFlash() async {
    if (_cameraController == null || !_isCameraReady) return;
    try {
      final next = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(next);
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (_) {}
  }

  /// Opens the rigged mock-gallery bottom sheet.
  void _openMockGallery() {
    if (_scanState != _ScanState.idle) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _MockGallerySheet(
        onLeafSelected: _onLeafSelected,
      ),
    );
  }

  /// Triggered when a leaf is picked from the mock gallery.
  void _onLeafSelected(MockLeaf leaf) {
    Navigator.of(context).pop(); // dismiss gallery sheet

    setState(() {
      _selectedLeaf = leaf;
      _scanState = _ScanState.scanning;
    });
    _pillController.forward(from: 0);

    // State 1 → scanning for 2 s
    _stateTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      // State 2 → scanned for 1 s
      setState(() => _scanState = _ScanState.scanned);

      _stateTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        _pillController.reverse();

        // State 3 → result
        setState(() => _scanState = _ScanState.result);
        _resultController.forward(from: 0);
      });
    });
  }

  /// Resets the scan so the demo can be replayed.
  void _resetScan() {
    _stateTimer?.cancel();
    _pillController.reverse();
    _resultController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _scanState = _ScanState.idle;
        _selectedLeaf = null;
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: _scanState == _ScanState.idle,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _resetScan();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 0 — Camera preview
              _buildCameraPreview(),

              // Layer 1 — Top overlay (gradient + back + title)
              _buildTopOverlay(),

              // Layer 2 — Bottom controls (gallery + flash)
              _buildBottomControls(),

              // Layer 3 — Scanning pill overlay
              if (_scanState == _ScanState.scanning ||
                  _scanState == _ScanState.scanned)
                _buildScanPill(),

              // Layer 4 — Result bottom sheet
              if (_selectedLeaf != null) _buildResultSheet(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Camera preview ─────────────────────────────────────────────
  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.white24,
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Memuat kamera…',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fill the entire screen with the camera, cropping as needed.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // ─── Top overlay ────────────────────────────────────────────────
  Widget _buildTopOverlay() {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: topInset + 10,
          left: 20,
          right: 20,
          bottom: 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.black.withValues(alpha: 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                if (_scanState != _ScanState.idle) {
                  _resetScan();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Daun Tanaman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pastikan daun terlihat jelas dan\n'
                      'memiliki penerangan yang memadai',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom controls ────────────────────────────────────────────
  Widget _buildBottomControls() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: _scanState == _ScanState.result,
        child: AnimatedOpacity(
          opacity: _scanState == _ScanState.result ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: EdgeInsets.only(
              bottom: bottomInset + 20,
              left: 24,
              right: 24,
              top: 80,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Gallery button (bottom-left)
                _OverlayCircleButton(
                  icon: Icons.photo_library_outlined,
                  onTap: _openMockGallery,
                ),
                // Flash toggle (bottom-right)
                _OverlayCircleButton(
                  icon: _isFlashOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Scanning pill ──────────────────────────────────────────────
  Widget _buildScanPill() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bool isScanning = _scanState == _ScanState.scanning;

    // ── Pill theme ───
    final Color pillBg = isScanning
        ? const Color(0xFF2C2C2E)       // dark charcoal
        : const Color(0xFF22A45D);       // green
    final Color iconBg = isScanning
        ? const Color(0xFF3B82F6)        // blue
        : const Color(0xFF16A34A);       // green
    final IconData iconData = isScanning
        ? Icons.search_rounded
        : Icons.eco_rounded;
    final String title = isScanning ? 'Mendeteksi Daun' : 'Daun Terfoto';
    final String subtitle = isScanning
        ? 'Harap stabilkan kamera'
        : 'Foto daun telah diambil';

    return Positioned(
      bottom: bottomInset + 26,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _pillController,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            decoration: BoxDecoration(
              color: pillBg.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Leading circle icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                // Two-line text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Result bottom sheet ────────────────────────────────────────
  Widget _buildResultSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Leaf name
              Text(
                _selectedLeaf!.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Confidence
              Text(
                _selectedLeaf!.confidence,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                _selectedLeaf!.description,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3A3A3C),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _OverlayCircleButton — translucent circle used for gallery & flash
// ═══════════════════════════════════════════════════════════════════════

class _OverlayCircleButton extends StatelessWidget {
  const _OverlayCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.40),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _MockGallerySheet — custom bottom sheet listing the 4 rigged leaves
// ═══════════════════════════════════════════════════════════════════════

class _MockGallerySheet extends StatelessWidget {
  const _MockGallerySheet({required this.onLeafSelected});

  final ValueChanged<MockLeaf> onLeafSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pilih Daun (Demo)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // 2×2 grid of mock leaves
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _kMockLeaves
                .map((leaf) => _MockLeafTile(
                      leaf: leaf,
                      onTap: () => onLeafSelected(leaf),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _MockLeafTile — individual tile in the mock gallery grid
// ═══════════════════════════════════════════════════════════════════════

class _MockLeafTile extends StatelessWidget {
  const _MockLeafTile({required this.leaf, required this.onTap});

  final MockLeaf leaf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: leaf.thumbnailColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: leaf.thumbnailColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco_rounded, color: Colors.white70, size: 32),
            const SizedBox(height: 6),
            Text(
              leaf.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
