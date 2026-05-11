// lib/features/home/widgets/weight_progress_widget.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bmi_viewmodel.dart';

class WeightProgressWidget extends StatelessWidget {
  final BmiState state;
  const WeightProgressWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final current = state.currentWeight ?? 0;
    final initial = state.initialWeight ?? current;
    final change  = state.weightChange ?? 0;
    final isGain  = change >= 0;

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
          const Text(
            'Tiến trình cân nặng',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),

          // Số thay đổi lớn
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Icon xu hướng
              Icon(
                isGain
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isGain
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF16A34A),
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '${isGain ? '+' : ''}${change.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: isGain
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'So với cân nặng ban đầu (${initial.toStringAsFixed(1)} kg)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 20),

          // 3 thẻ thông tin
          Row(
            children: [
              _StatChip(
                label: 'Cân nặng ban đầu',
                value: '${initial.toStringAsFixed(1)} kg',
                color: const Color(0xFFE0F2FE),
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Hiện tại',
                value: '${current.toStringAsFixed(1)} kg',
                color: const Color(0xFFD1FAE5),
              ),
              const SizedBox(width: 10),
              _GoalChip(bmi: state.bmi),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final double? bmi;
  const _GoalChip({this.bmi});

  @override
  Widget build(BuildContext context) {
    final bmiStr = bmi != null ? bmi!.toStringAsFixed(1) : '—';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$bmiStr BMI',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hiện tại',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}