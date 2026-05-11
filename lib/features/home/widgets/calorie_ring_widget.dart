// lib/features/home/widgets/calorie_ring_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CalorieRingWidget extends StatelessWidget {
  final double consumedKcal;
  final double targetKcal;
  final double protein;
  final double carbs;
  final double fat;
  final int    mealsCompleted;

  const CalorieRingWidget({
    super.key,
    required this.consumedKcal,
    required this.targetKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealsCompleted,
  });

  double get _progress =>
      targetKcal > 0 ? (consumedKcal / targetKcal).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                'Calo hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$mealsCompleted/4 bữa xong',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ring + macros
          Row(
            children: [
              // Vòng tròn calo
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _CalorieRingPainter(progress: _progress),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          consumedKcal.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          '/ ${targetKcal.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.45),
                          ),
                        ),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Macros
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MacroRow(
                      label: 'Protein',
                      value: protein,
                      target: _macroTarget('protein'),
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(
                      label: 'Carbs',
                      value: carbs,
                      target: _macroTarget('carbs'),
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(
                      label: 'Chất béo',
                      value: fat,
                      target: _macroTarget('fat'),
                      color: const Color(0xFFEA580C),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Target macro ước tính từ target calo
  double _macroTarget(String type) {
    switch (type) {
      case 'protein': return (targetKcal * 0.25 / 4).roundToDouble();
      case 'carbs':   return (targetKcal * 0.50 / 4).roundToDouble();
      case 'fat':     return (targetKcal * 0.25 / 9).roundToDouble();
      default:        return 0;
    }
  }
}

// ── Vẽ vòng tròn progress ────────────────────────────────────────────────────
class _CalorieRingPainter extends CustomPainter {
  final double progress;
  _CalorieRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 10;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Progress arc (start từ top = -π/2)
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) => old.progress != progress;
}

// ── 1 dòng macro ─────────────────────────────────────────────────────────────
class _MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color  color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              '${value.toInt()}/${target.toInt()}g',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withOpacity(0.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.black.withOpacity(0.07),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}