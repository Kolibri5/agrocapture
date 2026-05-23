import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'result_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
// Variety data — simulated ML classification results
// ═══════════════════════════════════════════════════════════════════════

class VarietyInfo {
  final String name;
  final String recommendation;
  final Color thumbnailColor;

  const VarietyInfo({
    required this.name,
    required this.recommendation,
    required this.thumbnailColor,
  });
}

const List<VarietyInfo> kVarieties = [
  VarietyInfo(
    name: 'Arabika',
    recommendation:
        'Rentan terhadap penyakit karat daun (Leaf Rust). '
        'Pastikan naungan pohon pelindung cukup (sekitar 30-40%) '
        'untuk menjaga kelembaban. Lakukan pemangkasan rutin pada '
        'cabang yang tidak produktif untuk sirkulasi udara.',
    thumbnailColor: Color(0xFF2D5A27),
  ),
  VarietyInfo(
    name: 'Robusta',
    recommendation:
        'Membutuhkan asupan nutrisi yang lebih tinggi. Lakukan '
        'pemupukan berimbang dengan rasio NPK yang tepat, terutama '
        'menjelang masa pembungaan. Pangkas dahan vertikal untuk '
        'memaksimalkan pertumbuhan cabang horizontal (produktif).',
    thumbnailColor: Color(0xFF3E7A35),
  ),
  VarietyInfo(
    name: 'Excelsa',
    recommendation:
        'Tanaman ini cukup toleran terhadap kekeringan. Namun, '
        'karena kanopinya bisa tumbuh sangat besar dan tinggi, '
        'jarak tanam harus diperhatikan (idealnya 3x3 meter). '
        'Lakukan pemangkasan tinggi (topping) agar mudah dipanen.',
    thumbnailColor: Color(0xFF4A8B3F),
  ),
  VarietyInfo(
    name: 'Liberika',
    recommendation:
        'Sangat adaptif di lahan gambut atau tanah kurang subur. '
        'Jaga kebersihan gulma di sekitar piringan tanaman. '
        'Perhatikan pemangkasan bentuk karena daun dan buahnya '
        'berukuran lebih besar dari varietas lain.',
    thumbnailColor: Color(0xFF1E4D1A),
  ),
];

/// Randomly pick a variety.
VarietyInfo _randomVariety() {
  final rng = Random();
  return kVarieties[rng.nextInt(kVarieties.length)];
}

int _randomConfidence() {
  final rng = Random();
  return 75 + rng.nextInt(21); // 75–95
}

// ═══════════════════════════════════════════════════════════════════════
// Scan state machine (no more 'result' — we navigate to ResultScreen)
// ═══════════════════════════════════════════════════════════════════════

enum _ScanState { idle, scanning, scanned }

// ═══════════════════════════════════════════════════════════════════════
// ScannerScreen — full-screen camera viewfinder with simulated ML flow
// ═══════════════════════════════════════════════════════════════════════

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  // ── Camera ──────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isFlashOn = false;

  // ── Scan state ──────────────────────────────────────────────────
  _ScanState _scanState = _ScanState.idle;
  VarietyInfo? _classifiedVariety;
  int _confidence = 0;
  File? _capturedImage;

  // ── Animations ──────────────────────────────────────────────────
  late final AnimationController _pillController;

  // ── Timers ──────────────────────────────────────────────────────
  Timer? _stateTimer;

  // ── Gallery ─────────────────────────────────────────────────────
  final ImagePicker _imagePicker = ImagePicker();

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

  /// Opens the device's real photo gallery via image_picker.
  Future<void> _openGallery() async {
    if (_scanState != _ScanState.idle) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      _capturedImage = File(picked.path);
      _startClassification();
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }
  /// Captures a photo from the live camera and starts classification.
  Future<void> _captureAndClassify() async {
    if (_scanState != _ScanState.idle) return;
    if (_cameraController == null || !_isCameraReady) return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      if (!mounted) return;
      _capturedImage = File(photo.path);
      _startClassification();
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  /// Runs the simulated ML classification pipeline:
  ///  scanning (2 s) → scanned (1 s) → navigate to ResultScreen
  void _startClassification() {
    _classifiedVariety = _randomVariety();
    _confidence = _randomConfidence();

    setState(() => _scanState = _ScanState.scanning);
    _pillController.forward(from: 0);

    // Phase 1 — "scanning" for 2 seconds
    _stateTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Phase 2 — "scanned" for 1 second
      setState(() => _scanState = _ScanState.scanned);

      _stateTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        _pillController.reverse();

        // Capture references before resetting
        final image = _capturedImage!;
        final variety = _classifiedVariety!;
        final confidence = _confidence;

        // Reset scanner to idle so live camera resumes when user returns
        setState(() {
          _scanState = _ScanState.idle;
          _capturedImage = null;
          _classifiedVariety = null;
          _confidence = 0;
        });

        // Navigate to the dedicated result screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              imageFile: image,
              varietyName: variety.name,
              careRecommendation: variety.recommendation,
              confidence: confidence,
              varietyColor: variety.thumbnailColor,
            ),
          ),
        );
      });
    });
  }

  /// Resets the scan so the demo can be replayed.
  void _resetScan() {
    _stateTimer?.cancel();
    _pillController.reverse();
    if (!mounted) return;
    setState(() {
      _scanState = _ScanState.idle;
      _classifiedVariety = null;
      _capturedImage = null;
      _confidence = 0;
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
              // Layer 0 — Camera preview (or captured image)
              _buildCameraPreview(),

              // Layer 1 — Top overlay (gradient + back + title)
              _buildTopOverlay(),

              // Layer 2 — Bottom controls (gallery + flash)
              _buildBottomControls(),

              // Layer 3 — Scanning pill overlay
              if (_scanState == _ScanState.scanning ||
                  _scanState == _ScanState.scanned)
                _buildScanPill(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Camera preview ─────────────────────────────────────────────
  Widget _buildCameraPreview() {
    // Show captured image during scanning states
    if (_capturedImage != null && _scanState != _ScanState.idle) {
      return SizedBox.expand(
        child: Image.file(
          _capturedImage!,
          fit: BoxFit.cover,
        ),
      );
    }

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

  // ─── Bottom controls ─────────
  Widget _buildBottomControls() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _scanState != _ScanState.idle ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: _scanState != _ScanState.idle,
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
                  onTap: _openGallery,
                ),
                // Shutter button (center)
                _ShutterButton(
                  onTap: _captureAndClassify,
                  isProcessing: _scanState != _ScanState.idle,
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

    final Color pillBg = isScanning
        ? const Color(0xFF2C2C2E)
        : const Color(0xFF22A45D);
    final Color iconBg = isScanning
        ? const Color(0xFF3B82F6)
        : const Color(0xFF16A34A);
    final IconData iconData = isScanning
        ? Icons.search_rounded
        : Icons.eco_rounded;
    final String title = isScanning
        ? 'Menganalisis daun...'
        : 'Daun Teridentifikasi';
    final String subtitle = isScanning
        ? 'Sedang memproses klasifikasi'
        : 'Hasil klasifikasi siap';

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
                  child: isScanning
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(iconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
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

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap, required this.isProcessing});
  final VoidCallback onTap;
  final bool isProcessing;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedOpacity(
        opacity: isProcessing ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}