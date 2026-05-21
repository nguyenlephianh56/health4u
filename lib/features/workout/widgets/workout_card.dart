// lib/features/workout/widgets/workout_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/data/repositories/health_repo.dart';
import '../viewmodels/workout_view_model.dart';
import '../views/exercise_detail_screen.dart';

class WorkoutCard extends ConsumerWidget {
  final int dayIndex;
  const WorkoutCard({super.key, required this.dayIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlan = ref.watch(userPlanDaysProvider);

    return asyncPlan.when(
      loading: () => _buildSkeleton(),
      error:   (e, _) => _buildError(e),
      data: (days) {
        if (dayIndex >= days.length) return _buildEmpty();
        final day = days[dayIndex];
        if (!day.hasWorkout) return _buildRestDay(day);
        return _buildWorkoutCard(context, day, day.workout!);
      },
    );
  }

  // ── Card chính ──────────────────────────────────────────────────────────────
  Widget _buildWorkoutCard(
      BuildContext context, UserPlanDay day, PlanWorkout w) {
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
          // ── Banner ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Text(w.emoji,
                        style: const TextStyle(fontSize: 80)),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _Tag(
                        label: w.category,
                        color: AppColors.secondary),
                  ),
                  Positioned(
                    top: 16,
                    left: 110,
                    child: _Tag(
                        label: w.difficultyVi,
                        color: _difficultyColor(w.difficulty)),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.dayShortLabel}  •  ${_formatDate(day.date)}',
                  style: TextStyle(
                    color: AppColors.text.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip('⏱', '${w.durationMin} phút'),
                    const SizedBox(width: 12),
                    _InfoChip('🔥', '${w.caloriesBurned} cal'),
                    const SizedBox(width: 12),
                    _InfoChip('💪', w.muscleGroup),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Nút bắt đầu → ExerciseDetailScreen ───────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(
                            workout:   w,
                            date:      day.date,
                            dayOfWeek: day.dayOfWeek,
                            docId:     day.docId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Bắt đầu ${w.title} →',
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

  // ── Ngày nghỉ ───────────────────────────────────────────────────────────────
  Widget _buildRestDay(UserPlanDay day) {
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
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B8DEF), Color(0xFF3A6FD8)],
                ),
              ),
              child: const Center(
                child: Text('😴', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Ngày nghỉ ngơi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${day.dayShortLabel}  •  ${_formatDate(day.date)}',
                  style: TextStyle(
                    color: AppColors.text.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(Object e) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'Không thể tải dữ liệu\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          'Không có kế hoạch cho ngày này',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Advanced':     return const Color(0xFFE74C3C);
      case 'Intermediate': return const Color(0xFFF39C12);
      default:             return const Color(0xFF2ECC71);
    }
  }

  String _formatDate(String date) {
    try {
      final p = date.split('-');
      return '${p[2]}/${p[1]}/${p[0]}';
    } catch (_) {
      return date;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
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