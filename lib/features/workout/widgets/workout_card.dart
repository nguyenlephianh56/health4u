import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/features/workout/viewmodels/workout_date_provider.dart';

class WorkoutCard extends ConsumerWidget {
  const WorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color bgColor = Color(0xFF0C7ABF);
    final Color cardColor = Colors.white.withOpacity(0.2);

    final selectedDate = ref.watch(selectedWorkoutDateProvider);
    final today = DateTime.now().toDate();

    // Tạo danh sách 7 ngày bắt đầu từ thứ 2 của tuần hiện tại
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: const BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Tiêu đề ---
          const Text(
            'Weekly Workout',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your personalized training schedule',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),

          // --- 3 Thẻ thống kê ---
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  cardColor: cardColor,
                  icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                  value: '250m',
                  label: 'Total Time',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  cardColor: cardColor,
                  icon: const Text('🔥', style: TextStyle(fontSize: 18)),
                  value: '1650',
                  label: 'Calories',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  cardColor: cardColor,
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                  value: '0/7',
                  label: 'Done',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Thanh ngày trong tuần (tích hợp bên trong card) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isSelected = day == selectedDate;
              final isToday = day == today;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedWorkoutDateProvider.notifier).state = day;
                },
                child: Container(
                  width: 46,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Thứ (T2, T3...)
                      Text(
                        _getDayOfWeek(day),
                        style: TextStyle(
                          color: isSelected ? bgColor : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Ngày trong tháng
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected ? bgColor : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Dấu chấm trắng nếu là hôm nay & không được chọn
                      if (isToday && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required Color cardColor,
    required Widget icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[date.weekday - 1];
  }
}

// Extension tiện ích (có thể đặt riêng nếu muốn)
extension DateOnly on DateTime {
  DateTime toDate() => DateTime(year, month, day);
}