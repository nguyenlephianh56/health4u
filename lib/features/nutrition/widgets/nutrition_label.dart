// lib/features/nutrition/widgets/nutrition_label.dart

import 'package:flutter/material.dart';

class NutritionLabel extends StatelessWidget {
  final String value;
  final String label;
  final Color dotColor;

  const NutritionLabel({
    super.key,
    required this.value,
    required this.label,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: dotColor),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }
}