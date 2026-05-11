// lib/features/home/widgets/today_roadmap_widget.dart
//
// Widget lộ trình hôm nay — hiện tại là placeholder
// Sẽ hiển thị các bữa ăn + bài tập trong ngày sau khi tích hợp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TodayRoadmapWidget extends StatelessWidget {
  const TodayRoadmapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          // Header
          Row(
            children: [
              const Text('🗓️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                'Lộ trình hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🚧  Sắp ra mắt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Placeholder content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                Text(
                  'Chưa có thông tin lộ trình hôm nay.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tính năng này sẽ được bổ sung sớm!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}