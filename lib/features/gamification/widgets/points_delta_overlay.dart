// lib/features/gamification/widgets/points_delta_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/discipline_viewmodel.dart';

class PointsDeltaOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const PointsDeltaOverlay({super.key, required this.child});

  @override
  ConsumerState<PointsDeltaOverlay> createState() => _PointsDeltaOverlayState();
}

class _PointsDeltaOverlayState extends ConsumerState<PointsDeltaOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  // Fix: theo dõi pointsDeltaId thay vì giá trị delta
  // → phân biệt được 2 lần cộng cùng số điểm (+10 rồi +10)
  int _lastDeltaId = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(disciplineViewModelProvider.notifier).clearPointsDelta();
        _ctrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fix: so sánh pointsDeltaId (int tăng dần) thay vì giá trị delta
    ref.listen<DisciplineState>(disciplineViewModelProvider, (prev, next) {
      if (next.lastPointsDelta != null &&
          next.pointsDeltaId != _lastDeltaId) {
        _lastDeltaId = next.pointsDeltaId;
        _ctrl.forward(from: 0);
      }
    });

    final delta = ref.watch(
      disciplineViewModelProvider.select((s) => s.lastPointsDelta),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (delta != null)
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: delta > 0
                            ? const Color(0xFF4CAF50)
                            : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        delta > 0 ? '+$delta điểm' : '$delta điểm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakBadgeRow
// ─────────────────────────────────────────────────────────────────────────────

class StreakBadgeRow extends ConsumerWidget {
  const StreakBadgeRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(disciplineViewModelProvider);

    if (state.isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Badge(
          emoji: '🔥',
          value: state.currentStreak.toString(),
          unit: 'ngày',
          label: 'Chuỗi hiện tại',
          bgColor: const Color(0xFFFFF3E0),
        ),
        _Badge(
          emoji: '🏆',
          value: state.bestStreak.toString(),
          unit: 'ngày',
          label: 'Best Streak',
          bgColor: const Color(0xFFFFF9C4),
        ),
        _Badge(
          emoji: '⭐',
          value: state.totalPoints.toString(),
          unit: 'pts',
          label: 'Điểm thưởng',
          bgColor: const Color(0xFFFFF9C4),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final String label;
  final Color bgColor;

  const _Badge({
    required this.emoji,
    required this.value,
    required this.unit,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '\n$unit',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}