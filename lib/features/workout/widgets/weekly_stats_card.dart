import 'package:flutter/material.dart';
import 'package:health4u/core/constants/app_colors.dart';

class WeeklyStatsCard extends StatelessWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primary, // Đổi nền thành màu xanh
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // 1. Hàng Thống Kê (Thời gian, Calo, Số buổi)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.timer_outlined, '250m', 'Total Time'),
              _buildStatItem(Icons.local_fire_department_outlined, '1650', 'Calories'),
              _buildStatItem(Icons.calendar_today_outlined, '0/7', 'Done'),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Hàng Chọn Ngày Trong Tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayItem('MON', isSelected: true),
              _buildDayItem('TUE', isSelected: false),
              _buildDayItem('WED', isSelected: false),
              _buildDayItem('THU', isSelected: false),
              _buildDayItem('FRI', isSelected: false),
              _buildDayItem('SAT', isSelected: false),
              _buildDayItem('SUN', isSelected: false),
            ],
          ),
        ],
      ),
    );
  }

  // Widget con hỗ trợ tạo các mục Thống kê
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.surface), // Icon màu trắng
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.surface // Chữ số màu trắng
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: AppColors.surface.withOpacity(0.8) // Chữ phụ màu trắng mờ
          ),
        ),
      ],
    );
  }

  // Widget con hỗ trợ tạo các Ngày trong tuần
  Widget _buildDayItem(String day, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface : Colors.transparent, // Nền trắng nếu được chọn
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.surface, // Chữ xanh nếu chọn, trắng nếu không
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.secondary : AppColors.surface.withOpacity(0.5), // Chấm cam nếu chọn, chấm trắng mờ nếu không
            ),
          ),
        ],
      ),
    );
  }
}