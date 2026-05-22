// lib/features/profile/widgets/how_to_earn_widget.dart
//
// Widget tĩnh hiển thị cách user có thể nhận điểm thưởng

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class _EarnItem {
  final String emoji;
  final String label;
  final String points;
  final Color  pointColor;

  const _EarnItem({
    required this.emoji,
    required this.label,
    required this.points,
    required this.pointColor,
  });
}

const _earnItems = [
  _EarnItem(
    emoji: '🥗',
    label: 'Hoàn thành bữa ăn',
    points: '+10 pts',
    pointColor: Color(0xFF16A34A),
  ),
  _EarnItem(
    emoji: '💪',
    label: 'Hoàn thành bài tập',
    points: '+20 pts',
    pointColor: Color(0xFF0284C7),
  ),
  _EarnItem(
    emoji: '🔥',
    label: 'Duy trì chuỗi 7 ngày',
    points: '+50 pts bonus',
    pointColor: Color(0xFFEA580C),
  ),
];

class HowToEarnWidget extends StatelessWidget {
  const HowToEarnWidget({super.key});

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
          // Header
          const Row(
            children: [
              Icon(Icons.expand_more_rounded,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text(
                'Cách nhận điểm thưởng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh sách cách earn
          ..._earnItems.map((item) => _EarnRow(item: item)),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final _EarnItem item;
  const _EarnRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Emoji
          Text(item.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Điểm
          Text(
            item.points,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: item.pointColor,
            ),
          ),
        ],
      ),
    );
  }
}