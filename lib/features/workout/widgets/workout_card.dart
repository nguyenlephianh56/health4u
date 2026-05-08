import 'package:flutter/material.dart';
// ĐÃ SỬA: Đường dẫn import chính xác để không bị lỗi "getter isn't defined"
import 'package:health4u/core/constants/app_colors.dart';

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner ảnh bài tập
          Container(
            height: 160,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              color: Colors.black12, // Placeholder
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: AppColors.surface, size: 16),
                        SizedBox(width: 4),
                        Text('HIT', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold)), // ĐÃ SỬA: 'HIIT' thành 'HIT'
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monday HIT Blast', // ĐÃ SỬA: 'HIIT' thành 'HIT'
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
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
                    Text('310 cal', style: TextStyle(color: AppColors.text.withOpacity(0.6))),
                    const SizedBox(width: 16),
                    Icon(Icons.fitness_center_outlined, size: 16, color: AppColors.text.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text('6 exercises', style: TextStyle(color: AppColors.text.withOpacity(0.6))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'High-intensity intervals to ignite your metabolism and torch calories fast. Alternate between max effort and active recovery.',
                  style: TextStyle(color: AppColors.text.withOpacity(0.6), height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('View Workout', style: TextStyle(color: AppColors.surface, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}