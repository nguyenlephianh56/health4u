import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/features/workout/viewmodels/workout_date_provider.dart';
import 'package:health4u/features/workout/viewmodels/workout_provider.dart';

class ExercisesPreview extends ConsumerWidget {
  const ExercisesPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesForSelectedDayProvider);
    final selectedDate = ref.watch(selectedWorkoutDateProvider);
    final buttonLabel = ref.watch(workoutButtonLabelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercises Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero)
                    .animate(animation),
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey(selectedDate),
            children: exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return _buildExerciseItem(
                name: exercise['name']!,
                detail: exercise['detail']!,
                cal: exercise['cal']!,
                time: exercise['time']!,
                index: index,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // 1. Đánh dấu đã bắt đầu tập
              ref.read(workoutStartedProvider.notifier).state = true;
              // 2. Điều hướng sang màn hình chi tiết tập luyện
              GoRouter.of(context).push('/exercise-detail');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C7ABF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }

  // Hàm tạo từng item bài tập (giữ nguyên code trước đó)
  Widget _buildExerciseItem({
    required String name,
    required String detail,
    required String cal,
    required String time,
    required int index,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedIndex = ref.watch(selectedExerciseIndexProvider);
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () {
            ref.read(selectedExerciseIndexProvider.notifier).state =
            isSelected ? null : index;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0C7ABF).withOpacity(0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFF0C7ABF), width: 1.5) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text)),
                      const SizedBox(height: 4),
                      Text(detail, style: TextStyle(color: AppColors.text.withOpacity(0.6), fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(cal, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.text.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(time, style: TextStyle(color: AppColors.text.withOpacity(0.6), fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}