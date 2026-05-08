// lib/features/admin/widgets/workout_list_item.dart

import 'package:flutter/material.dart';
import '../../../data/models/workout_model.dart';
import '../../../core/constants/app_colors.dart';

class WorkoutListItem extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WorkoutListItem({
    super.key,
    required this.workout,
    required this.onEdit,
    required this.onDelete,
  });

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Strength': return const Color(0xFFFFEDE0);
      case 'Yoga':     return const Color(0xFFE8F5E9);
      default:         return const Color(0xFFE0F2FE); // Cardio
    }
  }

  Color _categoryTextColor(String cat) {
    switch (cat) {
      case 'Strength': return const Color(0xFFEA580C);
      case 'Yoga':     return const Color(0xFF16A34A);
      default:         return AppColors.primary;
    }
  }

  Color _difficultyColor(String diff) {
    switch (diff) {
      case 'Advanced':     return const Color(0xFFFFE0E0);
      case 'Intermediate': return const Color(0xFFFFF3CD);
      default:             return const Color(0xFFE8F5E9); // Beginner
    }
  }

  Color _difficultyTextColor(String diff) {
    switch (diff) {
      case 'Advanced':     return const Color(0xFFDC2626);
      case 'Intermediate': return const Color(0xFFB45309);
      default:             return const Color(0xFF16A34A);
    }
  }

  String _difficultyLabel(String diff) {
    switch (diff) {
      case 'Beginner':     return 'Dễ';
      case 'Intermediate': return 'Trung bình';
      case 'Advanced':     return 'Khó';
      default:             return diff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges: category + difficulty
                Row(
                  children: [
                    _Badge(
                      label: workout.category,
                      bg: _categoryColor(workout.category),
                      textColor: _categoryTextColor(workout.category),
                    ),
                    const SizedBox(width: 6),
                    _Badge(
                      label: _difficultyLabel(workout.difficulty),
                      bg: _difficultyColor(workout.difficulty),
                      textColor: _difficultyTextColor(workout.difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Tên bài tập
                Text(
                  workout.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),

                // Thời gian + số bài tập
                Text(
                  '${workout.durationMin} phút  •  ${workout.exercises.length} bài tập',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          // Nút sửa
          _ActionBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            bg: AppColors.primary.withOpacity(0.08),
            onTap: onEdit,
          ),
          const SizedBox(width: 8),

          // Nút xóa
          _ActionBtn(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFE53935),
            bg: const Color(0xFFFFEBEB),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Badge({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
        required this.color,
        required this.bg,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}