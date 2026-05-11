// lib/features/home/widgets/bmi_card_widget.dart
//
// Widget BMI hiển thị trên Home.
// Bấm vào → navigate sang BmiDetailScreen

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BmiCardWidget extends StatelessWidget {
  final double? bmi;
  final String  bmiLabel;
  final VoidCallback onTap;

  const BmiCardWidget({
    super.key,
    required this.bmi,
    required this.bmiLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('⚖️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                const Text(
                  'Chỉ số BMI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _labelBgColor(bmiLabel),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _labelTextColor(bmiLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.black26, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            // BMI value
            if (bmi != null)
              Text(
                bmi!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              )
            else
              Text(
                '—',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            const SizedBox(height: 14),

            // Thanh BMI ngang
            _BmiBar(bmi: bmi ?? 22),
            const SizedBox(height: 10),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Legend(color: const Color(0xFF60A5FA), label: 'Thiếu cân'),
                _Legend(color: const Color(0xFF34D399), label: 'Bình thường'),
                _Legend(color: const Color(0xFFFBBF24), label: 'Thừa cân'),
                _Legend(color: const Color(0xFFF87171), label: 'Béo phì'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _labelBgColor(String label) {
    switch (label) {
      case 'Thiếu cân':    return const Color(0xFFDBEAFE);
      case 'Bình thường':  return const Color(0xFFD1FAE5);
      case 'Thừa cân':     return const Color(0xFFFEF3C7);
      default:             return const Color(0xFFFFE0E0);
    }
  }

  Color _labelTextColor(String label) {
    switch (label) {
      case 'Thiếu cân':    return const Color(0xFF1D4ED8);
      case 'Bình thường':  return const Color(0xFF065F46);
      case 'Thừa cân':     return const Color(0xFFB45309);
      default:             return const Color(0xFFDC2626);
    }
  }
}

// ── Thanh BMI ngang với con trỏ ──────────────────────────────────────────────
class _BmiBar extends StatelessWidget {
  final double bmi;
  const _BmiBar({required this.bmi});

  // Chuyển BMI → vị trí 0.0→1.0 trên thanh (range 10→40)
  double get _position => ((bmi - 10) / 30).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbX = width * _position;

        return Column(
          children: [
            SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Thanh màu gradient
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF60A5FA), // xanh - thiếu cân
                              Color(0xFF34D399), // xanh lá - bình thường
                              Color(0xFFFBBF24), // vàng - thừa cân
                              Color(0xFFF87171), // đỏ - béo phì
                            ],
                            stops: [0.0, 0.4, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Con trỏ vị trí BMI
                  Positioned(
                    left: (thumbX - 2).clamp(0, width - 4),
                    top: -4,
                    child: Container(
                      width: 4,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Labels dưới thanh
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15', style: TextStyle(fontSize: 10, color: Colors.black45)),
                Text('18.5', style: TextStyle(fontSize: 10, color: Colors.black45)),
                Text('25', style: TextStyle(fontSize: 10, color: Colors.black45)),
                Text('30', style: TextStyle(fontSize: 10, color: Colors.black45)),
                Text('40', style: TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color  color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}