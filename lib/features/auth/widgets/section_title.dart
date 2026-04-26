// lib/features/auth/widgets/section_title.dart
//
// Mô tả: Widget hiển thị tiêu đề + mô tả cho từng section trong InfoSetupScreen.
// Tái sử dụng cho section "Chiều cao & Cân nặng", "Mức vận động", "Mục tiêu".
//
// Cách dùng:
//   SectionTitle(
//     step: '01',
//     title: 'Thông số cơ thể',
//     subtitle: 'Nhập chiều cao và cân nặng của bạn',
//   )

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String step;     // "01", "02", "03"
  final String title;
  final String subtitle;

  const SectionTitle({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}