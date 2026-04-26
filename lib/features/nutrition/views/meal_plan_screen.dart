import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/nutrition_viewmodel.dart';
import '../widgets/meal_card.dart';

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(dailyMealsProvider);
    final stats = ref.watch(dailyNutritionStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kế hoạch bữa ăn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Tuần của 19 tháng 4", style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lịch chọn ngày
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.only(bottom: 20),
            child: const _DateSelector(),
          ),
          // Thống kê dinh dưỡng 4 bữa/ngày
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Protein", stats['protein']!),
                _buildStatItem("Carbs", stats['carbs']!),
                _buildStatItem("Fat", stats['fat']!),
                Container(width: 1, height: 40, color: Colors.grey[300]), // Divider
                Column(
                  children: [
                    Text(stats['totalKcal']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text("Tổng kcal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          // Danh sách MealCard
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                return MealCard(recipe: meals[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
// Lịch chọn ngày (Internal Widget)
class _DateSelector extends ConsumerWidget {
  const _DateSelector();

  final List<String> days = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<String> dates = const ['19', '20', '21', '22', '23', '24', '25'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedDayIndexProvider);
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => ref.read(selectedDayIndexProvider.notifier).state = index,
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(days[index], style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(dates[index], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}