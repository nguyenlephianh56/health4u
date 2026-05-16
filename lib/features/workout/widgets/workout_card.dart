// lib/features/workout/widgets/workout_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import '../viewmodels/workout_view_model.dart';
import '../views/exercise_detail_screen.dart';

class WorkoutCard extends ConsumerWidget {
  const WorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(currentWorkoutProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ─────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: workout.isRest
                      ? [const Color(0xFF5B8DEF), const Color(0xFF3A6FD8)]
                      : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
                ),
              ),
              child: Stack(
                children: [
                  // Emoji lớn làm nền
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Text(
                      workout.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                  // Tag loại buổi tập
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: workout.isRest
                            ? Colors.white.withOpacity(0.25)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            workout.isRest ? '😴' : '🔥',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workout.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Nội dung ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  workout.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),

                // Thông số
                Row(
                  children: [
                    _InfoChip('⏱', '${workout.minutes} phút'),
                    const SizedBox(width: 12),
                    _InfoChip('🔥', '${workout.calories} cal'),
                    const SizedBox(width: 12),
                    _InfoChip('💪', '${workout.exercises.length} bài'),
                  ],
                ),
                const SizedBox(height: 12),

                // Mô tả
                Text(
                  workout.description,
                  style: TextStyle(
                    color: AppColors.text.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Nút bắt đầu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(workout: workout),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      workout.isRest
                          ? 'Xem bài phục hồi →'
                          : 'Bắt đầu ${workout.title} →',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.text.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}