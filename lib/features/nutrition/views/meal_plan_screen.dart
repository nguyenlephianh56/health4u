import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../viewmodels/nutrition_viewmodel.dart';
import '../widgets/meal_card.dart';
import '../widgets/nutrition_label.dart';

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildCalendar(ref),
            _buildDailySummary(nutritionState.totalKcal),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: nutritionState.meals.length,
                itemBuilder: (context, index) {
                  return MealCard(
                    meal: nutritionState.meals[index],
                    onSwapTap: () {
                      // Logic đổi món
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Đã xóa bottomNavigationBar ở đây
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly Meal Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
              SizedBox(height: 4),
              Text('Week of Apr 19', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          CircleAvatar(
            backgroundColor: AppColors.surface,
            child: Icon(Icons.person, color: AppColors.primary),
          )
        ],
      ),
    );
  }

  Widget _buildCalendar(WidgetRef ref) {
    final days = [
      {'day': 'Mon', 'date': '17'}, {'day': 'Tue', 'date': '18'},
      {'day': 'Wed', 'date': '19'}, {'day': 'Thu', 'date': '20'},
      {'day': 'Fri', 'date': '21'}, {'day': 'Sat', 'date': '22'}, {'day': 'Sun', 'date': '23'},
    ];
    final selectedIndex = ref.watch(selectedDayIndexProvider);

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => ref.read(selectedDayIndexProvider.notifier).state = index,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(days[index]['day']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? AppColors.surface : Colors.grey)),
                  const SizedBox(height: 8),
                  Text(days[index]['date']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? AppColors.surface : AppColors.text)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySummary(int totalKcal) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wednesday', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('April 19', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(totalKcal.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Text('total kcal', style: TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NutritionLabel(value: '87g', label: 'Protein', dotColor: Colors.blue),
              NutritionLabel(value: '160g', label: 'Carbs', dotColor: AppColors.secondary),
              NutritionLabel(value: '54g', label: 'Fat', dotColor: Colors.purpleAccent),
            ],
          )
        ],
      ),
    );
  }
}