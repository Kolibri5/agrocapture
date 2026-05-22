import 'package:flutter/material.dart';

import '../../models/farm_model.dart';
import 'detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
// Design palette
// ═══════════════════════════════════════════════════════════════════════

const Color _kPrimary = Color(0xFF1B6E3C);
const Color _kTextPrimary = Color(0xFF0A0F14);
const Color _kTextSecondary = Color(0xFF6B7680);
const Color _kBelumPanen = Color(0xFF6B7280);
const double _kNavBarHeight = 68;

// ═══════════════════════════════════════════════════════════════════════
// ListScreen — farm directory list view
// ═══════════════════════════════════════════════════════════════════════

class ListScreen extends StatelessWidget {
  final VoidCallback onSwitchToMap;

  const ListScreen({super.key, required this.onSwitchToMap});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final navTotal = _kNavBarHeight + botPad;
    final farms = Farm.dummyFarms;

    return Container(
      color: const Color(0xFFF6F6F6),
      child: Column(
        children: [
          // ── Fixed header ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(top: topPad + 8, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildToggleRow(farms.length),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Scrollable farm cards ─────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, navTotal + 16),
              itemCount: farms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _FarmCard(
                farm: farms[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(farm: farms[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
  // Toggle + dynamic counter
  // ─────────────────────────────────────────────────────────────────

  Widget _buildToggleRow(int farmCount) {
    return Row(
      children: [
        Container(
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
                isActive: false,
                onTap: onSwitchToMap,
              ),
              _ToggleTab(
                icon: Icons.format_list_bulleted_rounded,
                label: 'List',
                isActive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Menunjukkan $farmCount Lahan',
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _FarmCard — tappable row in the directory list
// ═══════════════════════════════════════════════════════════════════════

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm, required this.onTap});
  final Farm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusBg = farm.isSiapPanen ? _kPrimary : _kBelumPanen;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _kPrimary.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Text column ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        farm.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 15, color: _kTextSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farm.locationText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        ...farm.varieties
                            .map((v) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: _ChipTag(v),
                                ))
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Thumbnail ────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  farm.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
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
                        color: Colors.white38, size: 32),
                  ),
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
// Shared private widgets
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
