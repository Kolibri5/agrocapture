import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════
// Design palette
// ═══════════════════════════════════════════════════════════════════════

const Color _kPrimary = Color(0xFF1B6E3C);
const Color _kTextPrimary = Color(0xFF1C1C1E);
const Color _kTextSecondary = Color(0xFF3A3A3C);
const Color _kTextTertiary = Color(0xFF8E8E93);

// ═══════════════════════════════════════════════════════════════════════
// Post-harvest recommendation data (per variety)
// ═══════════════════════════════════════════════════════════════════════

const Map<String, Map<String, String>> _kPostHarvestData = {
  'Arabika': {
    'fermentasi':
        'Gunakan metode \'Full-Wash\' dengan ragi khusus selama '
        '12-18 jam untuk meningkatkan keasaman (acidity) dan '
        'memunculkan cita rasa buah (fruity) dan bunga (floral) '
        'yang kompleks.',
    'roasting':
        'Disarankan tingkat roast \'Light-Medium\' (sekitar 12-15 '
        'menit setelah first crack) untuk mempertahankan keasaman '
        'unik dan aroma aslinya.',
  },
  'Robusta': {
    'fermentasi':
        'Terapkan fermentasi \'Honey Process\' atau \'Semi-Wash\' '
        'untuk memberikan sedikit rasa manis karamel dan body yang '
        'tebal, sambil mengurangi rasa pahit berlebih dan bau '
        'tanah (earthy).',
    'roasting':
        'Target roast \'Medium-Dark\' untuk menonjolkan rasa '
        'cokelat dan kacang yang pekat, serta body yang kuat.',
  },
  'Excelsa': {
    'fermentasi':
        'Tanaman ini cukup toleran. Gunakan metode fermentasi '
        '\'An-aerobic Natural\' selama 24 jam dengan kontrol sanitasi '
        'ketat untuk menyeimbangkan tingkat keasaman yang tinggi '
        'dengan rasa manis alami.',
    'roasting':
        'Gunakan profil roasting \'Slow Roast\' hingga tingkat '
        '\'Medium roast\' untuk menonjolkan aroma nangka yang unik '
        'dan khas Excelsa.',
  },
  'Liberika': {
    'fermentasi':
        'Sangat adaptif. Disarankan metode fermentasi \'Natural '
        'Process\' dengan pengeringan lambat selama 2-3 minggu '
        'untuk meningkatkan kompleksitas rasa buah nangka/cokelat '
        'dan body yang kental.',
    'roasting':
        'Target roast \'Medium-Dark\' untuk meningkatkan body dan '
        'mengurangi kegetiran.',
  },
};

// ═══════════════════════════════════════════════════════════════════════
// ResultScreen — DraggableScrollableSheet over captured leaf image
// ═══════════════════════════════════════════════════════════════════════

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final String varietyName;
  final String careRecommendation;
  final int confidence;
  final Color varietyColor;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.varietyName,
    required this.careRecommendation,
    required this.confidence,
    required this.varietyColor,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _detailRevealed = false;

  // ─── Expand to max and reveal post-harvest section ──────────────
  void _expandSheet() {
    _sheetController.animateTo(
      0.8,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    setState(() => _detailRevealed = true);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final postHarvest = _kPostHarvestData[widget.varietyName] ?? {};

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Background: captured / picked image ────────────
            SizedBox.expand(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),

            // ── Top overlay with back button ───────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: topInset + 10,
                  left: 16,
                  right: 16,
                  bottom: 40,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                  ],
                ),
              ),
            ),

            // ── DraggableScrollableSheet ───────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.3,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Drag handle ─────────────────────────
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // ── Section label ───────────────────────
                        Text(
                          'Hasil Analisis Daun',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Variety icon + name + confidence ────
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.varietyColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Colors.white70,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.varietyName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: _kTextPrimary,
                                      letterSpacing: -0.4,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.confidence}% confidence',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _kTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Rekomendasi Perawatan ───────────────
                        const Text(
                          'Rekomendasi Perawatan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.careRecommendation,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _kTextSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── "Lihat detail" link ─────────────────
                        if (!_detailRevealed)
                          GestureDetector(
                            onTap: _expandSheet,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Lihat detail',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: _kPrimary,
                                ),
                              ],
                            ),
                          ),

                        // ── Revealed: Rekomendasi Pascapanen ────
                        if (_detailRevealed && postHarvest.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade200),
                          const SizedBox(height: 16),

                          const Text(
                            'Rekomendasi Pascapanen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Fermentasi card
                          _InfoCard(
                            icon: Icons.science_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF3EEFF),
                            title: 'Fermentasi',
                            body: postHarvest['fermentasi'] ?? '',
                          ),
                          const SizedBox(height: 12),

                          // Roasting card
                          _InfoCard(
                            icon: Icons.local_fire_department_outlined,
                            iconColor: const Color(0xFFEA580C),
                            iconBg: const Color(0xFFFFF4ED),
                            title: 'Roasting',
                            body: postHarvest['roasting'] ?? '',
                          ),
                          const SizedBox(height: 24),

                          // Scan Lagi CTA
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Scan Lagi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _InfoCard — rounded card with icon circle + title + body
// ═══════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _kTextSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
