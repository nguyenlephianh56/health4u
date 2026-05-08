import 'package:flutter/material.dart';
import 'package:health4u/core/constants/app_colors.dart';

class ExerciseTimer extends StatelessWidget {
  const ExerciseTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercise 1/6',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.accessibility_new, color: AppColors.secondary, size: 16),
                    SizedBox(width: 4),
                    Text('Jumping Jacks', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Đồng hồ
          const Text(
            '02:00',
            style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: AppColors.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            '50 reps',
            style: TextStyle(fontSize: 18, color: AppColors.text.withOpacity(0.6)),
          ),
          const Spacer(),

          // Nút Điều khiển
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.skip_previous, size: 36, color: Colors.grey),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.1),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, size: 48, color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.skip_next, size: 36, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),

          // Chỗ trống để chèn ảnh GIF bài tập
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Exercise GIF placeholder', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}