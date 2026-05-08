import 'package:flutter/material.dart';
import 'package:health4u/core/constants/app_colors.dart';

class ExercisesPreview extends StatelessWidget {
  const ExercisesPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercises Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        _buildExerciseTile(
            title: 'Jumping Jacks Warm-Up', reps: '50 reps', cal: '15 cal', time: '2:00', iconColor: Colors.orangeAccent),
        _buildExerciseTile(
            title: 'Burpees', reps: '10 reps • 4 sets', cal: '80 cal', time: '5:00', iconColor: Colors.redAccent),
        _buildExerciseTile(
            title: 'Mountain Climbers', reps: '30 secs • 4 sets', cal: '60 cal', time: '3:40', iconColor: Colors.blueAccent),
      ],
    );
  }

  Widget _buildExerciseTile({required String title, required String reps, required String cal, required String time, required Color iconColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.accessibility_new, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text)),
                const SizedBox(height: 4),
                Text(reps, style: TextStyle(color: AppColors.text.withOpacity(0.6), fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(cal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: AppColors.text.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(time, style: TextStyle(color: AppColors.text.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}