// lib/features/home/widgets/calorie_ring_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/home_state.dart';

// ── Entry point: tự watch HomeState, không cần truyền param từ ngoài ─────────
class CalorieRingWidget extends ConsumerStatefulWidget {
  const CalorieRingWidget({super.key});

  @override
  ConsumerState<CalorieRingWidget> createState() => _CalorieRingWidgetState();
}

class _CalorieRingWidgetState extends ConsumerState<CalorieRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _progressAnim;

  // Lưu prev values để animate từ → đến
  double _prevRingProgress    = 0;
  double _prevProteinProgress = 0;
  double _prevCarbsProgress   = 0;
  double _prevFatProgress     = 0;

  // Animation riêng cho từng bar macro
  late Animation<double> _proteinAnim;
  late Animation<double> _carbsAnim;
  late Animation<double> _fatAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim  = _tweenAnim(0, 0);
    _proteinAnim   = _tweenAnim(0, 0);
    _carbsAnim     = _tweenAnim(0, 0);
    _fatAnim       = _tweenAnim(0, 0);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Animation<double> _tweenAnim(double from, double to) {
    return Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
  }

  // Chạy tất cả animation khi state thay đổi
  void _animateTo({
    required double ring,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    _progressAnim  = _tweenAnim(_prevRingProgress,    ring);
    _proteinAnim   = _tweenAnim(_prevProteinProgress, protein);
    _carbsAnim     = _tweenAnim(_prevCarbsProgress,   carbs);
    _fatAnim       = _tweenAnim(_prevFatProgress,      fat);

    _prevRingProgress    = ring;
    _prevProteinProgress = protein;
    _prevCarbsProgress   = carbs;
    _prevFatProgress     = fat;

    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    // Tính progress từ Firebase data
    final ringProgress    = state.targetKcal > 0
        ? (state.consumedKcal  / state.targetKcal).clamp(0.0, 1.0) : 0.0;
    final proteinProgress = state.protein > 0
        ? (state.consumedProtein / state.protein).clamp(0.0, 1.0) : 0.0;
    final carbsProgress   = state.carbs > 0
        ? (state.consumedCarbs   / state.carbs).clamp(0.0, 1.0) : 0.0;
    final fatProgress     = state.fat > 0
        ? (state.consumedFat     / state.fat).clamp(0.0, 1.0) : 0.0;

    // Trigger animation khi bất kỳ giá trị nào thay đổi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final changed = (ringProgress    - _prevRingProgress).abs()    > 0.001 ||
          (proteinProgress - _prevProteinProgress).abs() > 0.001 ||
          (carbsProgress   - _prevCarbsProgress).abs()   > 0.001 ||
          (fatProgress     - _prevFatProgress).abs()     > 0.001;
      if (changed) {
        _animateTo(
          ring:    ringProgress,
          protein: proteinProgress,
          carbs:   carbsProgress,
          fat:     fatProgress,
        );
      }
    });

    // Loading skeleton
    if (state.status == HomeStatus.loading) {
      return _buildSkeleton();
    }

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
          // ── Header ──────────────────────────────────────────────────────
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.mealsCompleted}/4 bữa xong',
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

          // ── Ring + Macros ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (_, __) => Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Vòng tròn animate
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: _CalorieRingPainter(
                          progress: _progressAnim.value,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              state.consumedKcal.toInt().toString(),
                              key: ValueKey(state.consumedKcal.toInt()),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Text(
                            '/ ${state.targetKcal.toInt()}',
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

                // Macro bars — luôn hiển thị, progress animate từ 0 lên khi hoàn thành bữa
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MacroBar(
                        label:    'Protein',
                        value:    state.consumedProtein,
                        target:   state.protein,
                        progress: _proteinAnim.value,
                        color:    const Color(0xFF0284C7),
                      ),
                      const SizedBox(height: 10),
                      _MacroBar(
                        label:    'Carbs',
                        value:    state.consumedCarbs,
                        target:   state.carbs,
                        progress: _carbsAnim.value,
                        color:    const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 10),
                      _MacroBar(
                        label:    'Chất béo',
                        value:    state.consumedFat,
                        target:   state.fat,
                        progress: _fatAnim.value,
                        color:    const Color(0xFFEA580C),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Loading skeleton
  Widget _buildSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _skeletonBox(80, 14),
              const Spacer(),
              _skeletonBox(80, 24, radius: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _skeletonBox(120, 120, radius: 60),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _skeletonBox(double.infinity, 10),
                    const SizedBox(height: 16),
                    _skeletonBox(double.infinity, 10),
                    const SizedBox(height: 16),
                    _skeletonBox(double.infinity, 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox(double w, double h, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
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

    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) => old.progress != progress;
}

// ── 1 dòng macro với animated progress bar ───────────────────────────────────
class _MacroBar extends StatelessWidget {
  final String label;
  final double value;     // consumed gram
  final double target;    // target gram từ Firebase
  final double progress;  // 0.0→1.0 đã được animate từ ngoài vào
  final Color  color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              // Luôn hiện value/target kể cả khi chưa ăn (0/130g)
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
            value: progress,   // animated value từ AnimatedBuilder cha
            minHeight: 5,
            backgroundColor: Colors.black.withOpacity(0.07),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}