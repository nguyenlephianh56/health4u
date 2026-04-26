import 'package:flutter/material.dart';

class NutritionLabel extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color iconColor;
  final IconData icon;

  const NutritionLabel({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.iconColor,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
              TextSpan(text: " $unit", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}