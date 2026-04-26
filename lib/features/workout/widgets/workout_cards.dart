import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/workout_view_model.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutInfo workout;
  const WorkoutCard({Key? key, required this.workout}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Nửa trên: Hình ảnh/Màu nền và Tiêu đề
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary, // Dùng màu xanh thay cho ảnh phức tạp
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workout.tag,
                    style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  workout.title,
                  style: const TextStyle(color: AppColors.surface, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Nửa dưới: Thời gian và Calo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${workout.totalTime} phút'),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department, size: 18, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text('${workout.totalCalories} calo'),
                const Spacer(),
                const Text('Xem chi tiết ➔', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}