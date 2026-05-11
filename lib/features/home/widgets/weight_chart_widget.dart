// lib/features/home/widgets/weight_chart_widget.dart
//
// Biểu đồ đường (line chart) cân nặng theo thời gian.
// Vẽ thủ công bằng CustomPaint — không cần thư viện ngoài.
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bmi_viewmodel.dart';

class WeightChartWidget extends StatelessWidget {
  final List<WeightRecord> history;
  const WeightChartWidget({super.key, required this.history});

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
              const Text(
                '📈  Biểu đồ cân nặng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${history.length} lần đo',
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

          // Chart
          history.isEmpty
              ? _emptyChart()
              : SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _LineChartPainter(history: history),
              size: Size.infinite,
            ),
          ),

          const SizedBox(height: 8),

          // Legend
          Row(
            children: [
              Container(
                width: 20,
                height: 2,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Cân nặng (kg)',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyChart() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu.\nCập nhật cân nặng để xem biểu đồ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.black.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CustomPainter vẽ line chart ───────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<WeightRecord> history;
  _LineChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const paddingLeft   = 40.0;
    const paddingBottom = 30.0;
    const paddingTop    = 10.0;
    const paddingRight  = 10.0;

    final chartW = size.width  - paddingLeft - paddingRight;
    final chartH = size.height - paddingBottom - paddingTop;

    // Min/max weight với padding 2kg
    final weights = history.map((r) => r.weightKg).toList();
    final minW    = (weights.reduce(min) - 2).floorToDouble();
    final maxW    = (weights.reduce(max) + 2).ceilToDouble();
    final rangeW  = maxW - minW;

    // Convert record → point trên canvas
    Offset toPoint(int i, double w) {
      final x = paddingLeft +
          (history.length == 1
              ? chartW / 2
              : i / (history.length - 1) * chartW);
      final y = paddingTop + (1 - (w - minW) / rangeW) * chartH;
      return Offset(x, y);
    }

    // Vẽ grid lines
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + (i / 4) * chartH;
      canvas.drawLine(
          Offset(paddingLeft, y), Offset(size.width - paddingRight, y),
          gridPaint);

      // Y labels
      // Y labels
      final labelW = maxW - (i / 4) * rangeW;

      final tp = TextPainter(
        text: TextSpan(
          text: labelW.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black38,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )
        ..layout();

      tp.paint(canvas, Offset(0, y - 5));
    }
    // Vẽ đường line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final pt = toPoint(i, history[i].weightKg);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        // Bezier curve cho mượt
        final prev = toPoint(i - 1, history[i - 1].weightKg);
        final cpX  = (prev.dx + pt.dx) / 2;
        path.cubicTo(cpX, prev.dy, cpX, pt.dy, pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Vẽ dots + X labels
    final dotPaint  = Paint()..color = AppColors.primary;
    final dotWhite  = Paint()..color = Colors.white;

    for (int i = 0; i < history.length; i++) {
      final pt = toPoint(i, history[i].weightKg);

      // Dot
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 3, dotWhite);

      // X label (ngày đo)
      final label = 'T${i + 1}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black38,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pt.dx - tp.width / 2,
            size.height - paddingBottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.history.length != history.length;
}