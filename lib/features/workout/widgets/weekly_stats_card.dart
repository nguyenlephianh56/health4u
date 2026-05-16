// lib/features/workout/widgets/weekly_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import '../viewmodels/workout_view_model.dart';

class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final stats       = ref.watch(weeklyStatsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
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
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: '⏱️',
                  value: '${stats['minutes']}p',
                  label: 'Tổng thời gian',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatItem(
                  icon: '🔥',
                  value: '${stats['calories']}',
                  label: 'Calo',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatItem(
                  icon: '✅',
                  value: '${stats['done']}/${stats['total']}',
                  label: 'Hoàn thành',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chọn ngày ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final workout    = weeklyWorkouts[i];
              final isSelected = i == selectedDay;
              final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
              final isToday    = i == todayIndex;

              return GestureDetector(
                onTap: () =>
                ref.read(selectedDayProvider.notifier).state = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        workout.dayShort,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
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
        ],
      ),
    );
  }
}

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
        crossAxisAlignment: CrossAxisAlignment.center,
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