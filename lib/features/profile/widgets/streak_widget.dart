// lib/features/profile/widgets/streak_widget.dart
//
// Widget hiển thị: current_streak, best_streak, total_points

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

class StreakWidget extends StatelessWidget {
  final UserModel user;

  const StreakWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chuỗi & Điểm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Current streak
              Expanded(
                child: _StreakCard(
                  emoji: '🔥',
                  value: '${user.currentStreak}',
                  label: 'Chuỗi hiện tại',
                  unit: 'ngày',
                  bgColor: const Color(0xFFFFEDE0),
                  valueColor: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 10),

              // Best streak — lấy từ Firestore nếu có, fallback currentStreak
              Expanded(
                child: _StreakCard(
                  emoji: '🏆',
                  value: '${user.currentStreak}',
                  label: 'Best Streak',
                  unit: 'ngày',
                  bgColor: const Color(0xFFFFF3CD),
                  valueColor: const Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 10),

              // Total points
              Expanded(
                child: _StreakCard(
                  emoji: '⭐',
                  value: '${user.totalPoints}',
                  label: 'Điểm thưởng',
                  unit: 'pts',
                  bgColor: const Color(0xFFE0F2FE),
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final String unit;
  final Color  bgColor;
  final Color  valueColor;

  const _StreakCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.unit,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: valueColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}