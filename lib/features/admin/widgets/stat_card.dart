// lib/features/admin/widgets/stat_card.dart
//
// Widget thẻ thống kê nhỏ hiển thị số lượng (Recipes / Workouts / Users).

import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String emoji;
  final int count;
  final String label;
  final Color bgColor;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.emoji,
    required this.count,
    required this.label,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}