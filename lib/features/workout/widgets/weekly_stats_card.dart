// lib/features/workout/widgets/weekly_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/data/repositories/health_repo.dart';
import '../viewmodels/workout_view_model.dart';

class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = ref.watch(selectedDayIndexProvider);
    final asyncPlan   = ref.watch(userPlanDaysProvider);
    final statsAsync  = ref.watch(planWeeklyStatsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề ───────────────────────────────────────────────────
          const Text(
            'Weekly Workout',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Lịch tập luyện cá nhân của bạn',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 16),

          // ── Thống kê tuần ─────────────────────────────────────────────
          statsAsync.when(
            loading: () => const SizedBox(height: 56),
            error:   (_, __) => const SizedBox(height: 56),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon:  '⏱️',
                    value: '${stats['minutes']}p',
                    label: 'Tổng thời gian',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatItem(
                    icon:  '🔥',
                    value: '${stats['calories']}',
                    label: 'Calo',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatItem(
                    icon:  '✅',
                    value: '${stats['done']}/${stats['total']}',
                    label: 'Hoàn thành',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Chọn ngày theo plan Firebase ──────────────────────────────
          asyncPlan.when(
            loading: () => _buildDaySkeleton(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (days) {
              if (days.isEmpty) return const SizedBox.shrink();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(days.length, (i) {
                    final day        = days[i];
                    final isSelected = i == selectedIdx;
                    final isToday    = _isToday(day.date);

                    return GestureDetector(
                      onTap: () =>
                      ref.read(selectedDayIndexProvider.notifier).state = i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Thứ viết tắt
                            Text(
                              day.dayShortLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Số ngày trong tháng
                            Text(
                              _dayNum(day.date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Emoji category hoặc nghỉ
                            Text(
                              day.hasWorkout
                                  ? day.workout!.emoji
                                  : '😴',
                              style: const TextStyle(fontSize: 15),
                            ),
                            // Dot indicator ngày hôm nay
                            if (isToday) ...[
                              const SizedBox(height: 3),
                              CircleAvatar(
                                radius: 2.5,
                                backgroundColor: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Skeleton khi đang load
  Widget _buildDaySkeleton() {
    return Row(
      children: List.generate(
        5,
            (_) => Container(
          margin: const EdgeInsets.only(right: 8),
          width: 44,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// "2026-05-18" → "18"
  String _dayNum(String date) {
    try {
      return date.split('-')[2];
    } catch (_) {
      return '';
    }
  }

  /// Kiểm tra date string có phải hôm nay không
  bool _isToday(String date) {
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return date == todayStr;
    } catch (_) {
      return false;
    }
  }
}

// ── Stat Item ──────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}