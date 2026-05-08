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
    // 1. Lấy index ngày đang được chọn
    final selectedIndex = ref.watch(selectedDayIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 25),
                    // 2. Truyền selectedIndex vào Calendar
                    _buildCalendar(ref, selectedIndex),
                  ],
                ),
              ),

              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  // 3. Truyền state và selectedIndex để Summary thay đổi theo ngày
                  _buildDailySummary(nutritionState, selectedIndex),
                  const SizedBox(height: 20),
                  ...nutritionState.meals.map(
                        (meal) => MealCard(
                      meal: meal,
                      onSwapTap: () {
                        // Logic đổi món
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Meal Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Week of May 3',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            color: AppColors.primary,
          ),
        )
      ],
    );
  }

  // --- CẬP NHẬT TRUYỀN INDEX VÀ ĐỔI LOGIC DẤU CHẤM ---
  Widget _buildCalendar(WidgetRef ref, int selectedIndex) {
    final days = [
      {'day': 'MON', 'date': '3'},
      {'day': 'TUE', 'date': '4'},
      {'day': 'WED', 'date': '5'},
      {'day': 'THU', 'date': '6'},
      {'day': 'FRI', 'date': '7'},
      {'day': 'SAT', 'date': '8'},
      {'day': 'SUN', 'date': '9'},
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0273B0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;

          // Mặc định THU (index 3) là hôm nay. Bạn có thể thay đổi sau nếu làm lịch thực tế.
          final isToday = index == 3;

          return GestureDetector(
            onTap: () => ref.read(selectedDayIndexProvider.notifier).state = index,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index]['day']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index]['date']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                  // Dấu chấm CHỈ hiện ở ngày "Hôm nay"
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    CircleAvatar(
                      radius: 2.5,
                      // Đổi màu tương phản với nền (nếu ô đang chọn nền trắng -> chấm xanh, ngược lại chấm trắng)
                      backgroundColor: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- CẬP NHẬT HIỂN THỊ DỮ LIỆU ĐỘNG ---
  Widget _buildDailySummary(dynamic nutritionState, int selectedIndex) {
    // List ánh xạ index với Thứ và Ngày để giao diện tự đổi
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dates = ['May 3', 'May 4', 'May 5', 'May 6', 'May 7', 'May 8', 'May 9'];

    String currentDayName = daysOfWeek[selectedIndex];
    String currentDateText = dates[selectedIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentDayName, // Thay "Sunday"
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentDateText, // Thay "May 9"
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nutritionState.totalKcal.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'total kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sử dụng trực tiếp dữ liệu từ nutritionState thay cho số cứng
              _buildMacroCard('${nutritionState.protein}g', 'Protein', const Color(0xFF4285F4)),
              const SizedBox(width: 10),
              _buildMacroCard('${nutritionState.carbs}g', 'Carbs', const Color(0xFFF9A825)),
              const SizedBox(width: 10),
              _buildMacroCard('${nutritionState.fat}g', 'Fat', const Color(0xFFEA4335)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacroCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}