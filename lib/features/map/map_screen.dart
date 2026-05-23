import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/farm_model.dart';
import '../directory/detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
// Design palette
// ═══════════════════════════════════════════════════════════════════════

const Color _kPrimary = Color(0xFF1B6E3C);
const Color _kTextPrimary = Color(0xFF0A0F14);
const double _kNavBarHeight = 68;

// ═══════════════════════════════════════════════════════════════════════
// Map region — Greater Malang
// ═══════════════════════════════════════════════════════════════════════

const LatLng _kMalangCenter = LatLng(-7.9839, 112.6214);
LatLngBounds _kMalangBounds = LatLngBounds(
  southwest: LatLng(-8.1000, 112.5000),
  northeast: LatLng(-7.8500, 112.7500),
);

// ═══════════════════════════════════════════════════════════════════════
// Map style — hide default POIs for a clean look
// ═══════════════════════════════════════════════════════════════════════

const String _kMapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';

// ═══════════════════════════════════════════════════════════════════════
// MapScreen
// ═══════════════════════════════════════════════════════════════════════

class MapScreen extends StatefulWidget {
  final VoidCallback onSwitchToList;
  const MapScreen({super.key, required this.onSwitchToList});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── Map ─────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;

  // ── Location ────────────────────────────────────────────────────
  LatLng _userLocation = _kMalangCenter;

  // ── UI / selection state ────────────────────────────────────────
  bool _showFarmSheet = false;
  Farm? _selectedFarm;
  String? _selectedFarmId;

  // ── Markers ─────────────────────────────────────────────────────
  Set<Marker> _markers = {};

  // Pre-generated marker icons (selected + unselected per farm)
  final Map<String, BitmapDescriptor> _unselectedIcons = {};
  final Map<String, BitmapDescriptor> _selectedIcons = {};
  bool _iconsReady = false;

  // ═════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _generateMarkerIcons();
    _initLocation();
  }

  // ═════════════════════════════════════════════════════════════════
  // Custom labelled marker generation
  // ═════════════════════════════════════════════════════════════════

  Future<void> _generateMarkerIcons() async {
    for (final farm in Farm.dummyFarms) {
      _unselectedIcons[farm.id] = await _createLabeledMarker(
        label: farm.name,
        isSelected: false,
      );
      _selectedIcons[farm.id] = await _createLabeledMarker(
        label: farm.name,
        isSelected: true,
      );
    }
    _iconsReady = true;
    _rebuildMarkers();
  }

  /// Renders a widget-like marker to a [BitmapDescriptor]:
  ///   [ 📍  Farm Name ]
  /// Selected = green pin + green label bg.
  /// Unselected = gray pin + white label bg.
  static Future<BitmapDescriptor> _createLabeledMarker({
    required String label,
    required bool isSelected,
  }) async {
    const double scale = 2.5; // render at 2.5× for sharp markers

    // Logical sizes
    const double pinW = 22;
    const double pinH = 28;
    const double gap = 4;
    const double padH = 10;
    const double padV = 6;
    const double fontSize = 11;
    const double radius = 8;

    // Measure text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isSelected
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF6B7280),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 200);

    final textW = textPainter.width.ceilToDouble() + 2;
    final boxH = fontSize + padV * 2;
    final totalW = pinW + gap + padH * 2 + textW;
    final totalH = boxH > pinH ? boxH : pinH;

    // Physical pixel canvas
    final pxW = (totalW * scale).ceil();
    final pxH = (totalH * scale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pxW.toDouble(), pxH.toDouble()),
    );
    canvas.scale(scale);

    // Colours
    final pinColor = isSelected
        ? const Color(0xFF1B6E3C)
        : const Color(0xFF9CA3AF);
    final labelBg = isSelected
        ? const Color(0xFF1B6E3C)
        : const Color(0xFFFFFFFF);
    final borderColor = isSelected
        ? const Color(0xFF1B6E3C)
        : const Color(0xFFD1D5DB);

    // ── Pin icon (circle + triangle) ──────────────────────────
    final pinCx = pinW / 2;
    final pinCy = totalH / 2 - 3;
    final pinPaint = Paint()..color = pinColor;

    canvas.drawCircle(Offset(pinCx, pinCy - 2), 7, pinPaint);

    final pinPath = Path()
      ..moveTo(pinCx - 5, pinCy + 3)
      ..lineTo(pinCx + 5, pinCy + 3)
      ..lineTo(pinCx, pinCy + 12)
      ..close();
    canvas.drawPath(pinPath, pinPaint);

    // White dot
    canvas.drawCircle(
      Offset(pinCx, pinCy - 2),
      3,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // ── Label box ─────────────────────────────────────────────
    final boxLeft = pinW + gap;
    final boxTop = (totalH - boxH) / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, boxTop, textW + padH * 2, boxH),
      Radius.circular(radius),
    );

    canvas.drawRRect(rrect, Paint()..color = labelBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Text ──────────────────────────────────────────────────
    textPainter.paint(canvas, Offset(boxLeft + padH, boxTop + padV - 1));

    // Convert to image bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(pxW, pxH);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: totalW,
      height: totalH,
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // Rebuild markers with current selection state
  // ═════════════════════════════════════════════════════════════════

  void _rebuildMarkers() {
    _markers = Farm.dummyFarms.map((farm) {
      final isSelected = farm.id == _selectedFarmId;
      BitmapDescriptor icon;
      if (_iconsReady) {
        icon = isSelected
            ? (_selectedIcons[farm.id] ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen))
            : (_unselectedIcons[farm.id] ?? BitmapDescriptor.defaultMarker);
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen);
      }

      return Marker(
        markerId: MarkerId(farm.id),
        position: LatLng(farm.latitude, farm.longitude),
        icon: icon,
        // Anchor at the pin tip (left side, towards bottom)
        anchor: Offset(
          _iconsReady ? 0.07 : 0.5,
          _iconsReady ? 0.85 : 1.0,
        ),
        onTap: () => _onMarkerTapped(farm),
      );
    }).toSet();

    if (mounted) setState(() {});
  }

  // ═════════════════════════════════════════════════════════════════
  // Location
  // ═════════════════════════════════════════════════════════════════

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);

      if (_kMalangBounds.contains(latLng)) {
        _userLocation = latLng;
      }

      _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation));
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // Map callbacks & actions
  // ═════════════════════════════════════════════════════════════════

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapCompleter.isCompleted) {
      _mapCompleter.complete(controller);
    }
    _mapController = controller;
  }

  void _onMarkerTapped(Farm farm) {
    _selectedFarmId = farm.id;
    _selectedFarm = farm;
    _showFarmSheet = true;
    _rebuildMarkers();
  }

  void _closeFarmSheet() {
    _selectedFarmId = null;
    _selectedFarm = null;
    _showFarmSheet = false;
    _rebuildMarkers();
  }

  void _animateToNorth() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation, zoom: 14, bearing: 0),
      ),
    );
  }

  void _animateToUser() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation, zoom: 15),
      ),
    );
  }

  void _openDetail(Farm farm) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(farm: farm)),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final navTotal = _kNavBarHeight + botPad;

    return Stack(
      children: [
        // ── Google Map ─────────────────────────────────────────
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _userLocation,
            zoom: 14,
          ),
          style: _kMapStyle,
          minMaxZoomPreference: const MinMaxZoomPreference(11.0, null),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          cameraTargetBounds: CameraTargetBounds(_kMalangBounds),
          padding: EdgeInsets.only(bottom: navTotal),
          onTap: (_) => _closeFarmSheet(),
        ),

        // ── Search bar ─────────────────────────────────────────
        Positioned(
          top: topPad + 8,
          left: 16,
          right: 16,
          child: _buildSearchBar(),
        ),

        // ── Map / List toggle ──────────────────────────────────
        Positioned(
          top: topPad + 68,
          left: 16,
          child: _buildToggle(),
        ),

        // ── Custom map controls ────────────────────────────────
        Positioned(
          bottom: navTotal + 16,
          right: 16,
          child: AnimatedOpacity(
            opacity: _showFarmSheet ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _showFarmSheet,
              child: _buildMapControls(),
            ),
          ),
        ),

        // ── Farm detail sheet ──────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: _showFarmSheet ? Curves.easeOutCubic : Curves.easeInCubic,
          bottom: _showFarmSheet ? navTotal + 4 : -420,
          left: 16,
          right: 16,
          child: _buildFarmSheet(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Search bar
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cari disini',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded,
                color: Colors.grey.shade700, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Map / List toggle
  // ─────────────────────────────────────────────────────────────────

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTab(
            icon: Icons.map_outlined,
            label: 'Map',
            isActive: true,
            onTap: () {},
          ),
          _ToggleTab(
            icon: Icons.format_list_bulleted_rounded,
            label: 'List',
            isActive: false,
            onTap: widget.onSwitchToList,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Map controls
  // ─────────────────────────────────────────────────────────────────

  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButton(icon: Icons.explore_outlined, onTap: _animateToNorth),
        const SizedBox(height: 10),
        _MapButton(icon: Icons.my_location_rounded, onTap: _animateToUser),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Farm detail bottom sheet (data-driven by _selectedFarm)
  // ─────────────────────────────────────────────────────────────────

  Widget _buildFarmSheet() {
    final farm = _selectedFarm ?? Farm.dummyFarms.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    farm.imageUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF2E7D32),
                            Color(0xFF1B5E20),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.landscape_rounded,
                          color: Colors.white38, size: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          farm.groupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${farm.locationText} , Indonesia',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 17),
                        child: Text(
                          farm.altitude,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          ...farm.varieties.map((v) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _ChipTag(v),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: _closeFarmSheet,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 14),

            // ── Stats row ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'STATUS',
                    value: farm.status,
                    valueColor: farm.isSiapPanen ? _kPrimary : null,
                  ),
                ),
                Expanded(
                  child:
                      _StatCell(label: 'LUAS LAHAN', value: farm.luasLahan),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'ESTIMASI\nPANEN',
                    value: farm.estimasiPanen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── CTA button → navigates to DetailScreen ────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _openDetail(farm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private reusable widgets
// ═══════════════════════════════════════════════════════════════════════

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: Colors.grey.shade700),
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
            letterSpacing: 0.4,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _kTextPrimary,
          ),
        ),
      ],
    );
  }
}
