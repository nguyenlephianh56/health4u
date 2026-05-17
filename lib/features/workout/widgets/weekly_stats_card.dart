// lib/features/workout/widgets/weekly_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import '../viewmodels/workout_view_model.dart';

// ── Real-time clock provider (tick mỗi phút để cập nhật ngày nếu qua nửa đêm)
final _nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(
    const Duration(minutes: 1),
        (_) => DateTime.now(),
  );
});

// ── Tính ngày thứ 2 của tuần hiện tại ────────────────────────────────────────
/// Trả về DateTime của thứ 2 đầu tuần (tuần chứa [now])
DateTime _mondayOf(DateTime now) {
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
}

/// Danh sách 7 ngày trong tuần (T2 → CN)
List<DateTime> _weekDays(DateTime now) {
  final monday = _mondayOf(now);
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final stats       = ref.watch(weeklyStatsProvider);
    final nowAsync    = ref.watch(_nowProvider);

    final now   = nowAsync.value ?? DateTime.now();
    final days  = _weekDays(now);
    // index 0=T2...6=CN, weekday: 1=T2...7=CN
    final todayIndex = (now.weekday - 1).clamp(0, 6);

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

          // ── Chọn ngày (real-time) ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final workout    = weeklyWorkouts[i];
              final day        = days[i];
              final isSelected = i == selectedDay;
              final isToday    = i == todayIndex;

              // Tên thứ viết tắt
              const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

              return GestureDetector(
                onTap: () =>
                ref.read(selectedDayProvider.notifier).state = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 7),
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
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Số ngày thật
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Emoji icon bài tập
                      Text(
                        workout.emoji,
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
        ],
      ),
    );
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