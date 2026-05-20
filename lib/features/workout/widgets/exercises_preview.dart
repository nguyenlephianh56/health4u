// lib/features/workout/widgets/exercises_preview.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/data/repositories/health_repo.dart';
import '../viewmodels/workout_view_model.dart';

class ExercisesPreview extends ConsumerWidget {
  final int dayIndex;
  const ExercisesPreview({super.key, required this.dayIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlan = ref.watch(userPlanDaysProvider);

    return asyncPlan.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (days) {
        if (dayIndex >= days.length) return const SizedBox.shrink();

        final day = days[dayIndex];
        if (!day.hasWorkout) return const SizedBox.shrink();

        final w = day.workout!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin bài tập',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            _WorkoutInfoTile(workout: w),
          ],
        );
      },
    );
  }
}

/// Tile hiển thị thông tin workout từ plan (category, difficulty, muscle group,
/// duration, calories) — vì Firebase plan không lưu danh sách exercises riêng lẻ
class _WorkoutInfoTile extends StatelessWidget {
  final PlanWorkout workout;
  const _WorkoutInfoTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRow('💪', 'Nhóm cơ',      workout.muscleGroup),
      _InfoRow('🏷️', 'Thể loại',     workout.category),
      _InfoRow('📊', 'Độ khó',        workout.difficultyVi),
      _InfoRow('⏱️', 'Thời gian',    '${workout.durationMin} phút'),
      _InfoRow('🔥', 'Calo đốt cháy','${workout.caloriesBurned} cal'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          return Column(
            children: [
              _buildRow(entry.value),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.text.withOpacity(0.07),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(row.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            row.label,
            style: TextStyle(
              color: AppColors.text.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            row.value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}