import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/workout_view_model.dart';
import '../widgets/workout_card.dart';

class WorkoutScheduleScreen extends ConsumerWidget {
  const WorkoutScheduleScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch Tập Tuần', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 24)),
            Text('Lộ trình tập luyện dành riêng cho bạn', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thống kê nhanh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(Icons.timer, '250', 'Phút', AppColors.primary),
              _buildStat(Icons.local_fire_department, '1650', 'Calo', AppColors.secondary),
              _buildStat(Icons.check_circle, '0/7', 'Hoàn thành', Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          // 2. Chọn ngày trong tuần
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(days.length, (index) {
                bool isSelected = selectedDay == index;
                return GestureDetector(
                  onTap: () => ref.read(selectedDayProvider.notifier).state = index,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: isSelected ? AppColors.surface : AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          // 3. Thẻ bài tập chính
          WorkoutCard(workout: workout),
          const SizedBox(height: 16),
          // 4. Mô tả bài tập
          Text(workout.description, style: TextStyle(color: Colors.grey.shade800, height: 1.5)),
          const SizedBox(height: 24),
          // 5.Danh sách bài tập
          const Text('Danh sách bài tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...workout.exercises.map((ex) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16)
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.background, child: Icon(Icons.fitness_center, color: AppColors.primary)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(ex.durationOrReps, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Text('${ex.calories} cal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ],
            ),
          )).toList(),
        ],
      ),
      // Nút bắt đầu bài tập cố định ở dưới
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Bắt đầu bài tập', style: TextStyle(fontSize: 18, color: AppColors.surface, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}