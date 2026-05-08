import 'package:flutter/material.dart';
import 'package:health4u/core/constants/app_colors.dart';
// Đã thêm đường dẫn import tới file Widget vừa được tách
import 'package:health4u/features/workout/widgets/exercise_timer.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Tên bài tập & Thông tin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.surface, size: 16),
                    SizedBox(width: 4),
                    Text('HIT', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Monday HIT Blast',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: AppColors.text.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text('30 min', style: TextStyle(color: AppColors.text.withOpacity(0.6))),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department_outlined, size: 16, color: AppColors.text.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text('320 cal burned', style: TextStyle(color: AppColors.text.withOpacity(0.6))),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Thẻ Đếm ngược & Điều khiển (Đã được gọi từ file Widget riêng)
              const Expanded(
                child: ExerciseTimer(),
              ),
              const SizedBox(height: 20),

              // 3. Nút Hoàn thành
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_task, color: AppColors.surface),
                  label: const Text('Mark Workout Complete (+20 pts)', style: TextStyle(color: AppColors.surface, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}