import 'package:flutter/material.dart';

import '../../models/farm_model.dart';

// ═══════════════════════════════════════════════════════════════════════
// Design palette — extracted from the colour reference
// ═══════════════════════════════════════════════════════════════════════

const Color _kPrimary = Color(0xFF1B6E3C);
const Color _kPrimaryBg = Color(0xFFEEF6F1);
const Color _kStatGreenBg = Color(0xFFE2F5E9);
const Color _kStatGreenIcon = Color(0xFF1B6E3C);
const Color _kStatIndigoBg = Color(0xFFE8ECFE);
const Color _kStatIndigoIcon = Color(0xFF5B6499);
const Color _kTextPrimary = Color(0xFF0A0F14);
const Color _kTextSecondary = Color(0xFF6B7680);

// ═══════════════════════════════════════════════════════════════════════
// DetailScreen — full farm detail page
// ═══════════════════════════════════════════════════════════════════════

class DetailScreen extends StatelessWidget {
  final Farm farm;

  const DetailScreen({super.key, required this.farm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPrimaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _kTextPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title card ──────────────────────────────────────
            _TitleCard(farm: farm),
            const SizedBox(height: 10),

            // ── Status ──────────────────────────────────────────
            _StatCard(
              icon: Icons.eco_outlined,
              iconBg: _kStatGreenBg,
              iconColor: _kStatGreenIcon,
              label: 'Status',
              value: farm.status,
              valueColor: farm.isSiapPanen ? _kPrimary : null,
            ),
            const SizedBox(height: 10),

            // ── Luas Lahan ──────────────────────────────────────
            _StatCard(
              icon: Icons.terrain_outlined,
              iconBg: _kStatIndigoBg,
              iconColor: _kStatIndigoIcon,
              label: 'Luas Lahan',
              value: farm.luasLahan,
              valueColor: _kPrimary,
            ),
            const SizedBox(height: 10),

            // ── Estimasi Panen ──────────────────────────────────
            _StatCard(
              icon: Icons.hourglass_bottom_rounded,
              iconBg: const Color(0xFFE2F5E9), // using green bg for consistency with design
              iconColor: const Color(0xFF1B6E3C),
              label: 'Estimasi Panen',
              value: farm.estimasiPanen,
              valueColor: _kPrimary,
            ),
            const SizedBox(height: 22),

            // ── Tentang Lahan ───────────────────────────────────
            const Text(
              'Tentang Lahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              farm.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 22),

            // ── Varietas Kopi ───────────────────────────────────
            _SectionCard(
              icon: Icons.local_cafe_outlined,
              title: 'Varietas Kopi',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: farm.varieties
                    .map((v) => _VarietyChip(v))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),

            // ── Kontak Informasi ────────────────────────────────
            _SectionCard(
              icon: Icons.phone_outlined,
              title: 'Kontak Informasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.contactPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    farm.contactEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _TitleCard — farm name, location, subtitle
// ═══════════════════════════════════════════════════════════════════════

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.farm});
  final Farm farm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            farm.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: _kPrimary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  farm.locationText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            farm.subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _StatCard — icon circle + label + value (Status, Luas, Estimasi)
// ═══════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),

          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _kTextSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? _kTextPrimary,
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

// ═══════════════════════════════════════════════════════════════════════
// _SectionCard — icon header + arbitrary child (Varietas, Kontak)
// ═══════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(icon, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _VarietyChip — bordered rounded chip for variety tags
// ═══════════════════════════════════════════════════════════════════════

class _VarietyChip extends StatelessWidget {
  const _VarietyChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _kTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
