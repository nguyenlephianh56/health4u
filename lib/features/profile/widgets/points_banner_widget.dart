// lib/features/gamification/widgets/points_banner_widget.dart
//
// Banner hiển thị điểm hiện có ở đầu màn hình Reward Shop.
// Được đặt trong vùng nền AppColors.primary nên dùng màu trắng mờ.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PointsBannerWidget extends StatelessWidget {
  final int totalPoints;

  const PointsBannerWidget({super.key, required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Nền trắng mờ — hoà vào AppBar primary
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        children: [
          // ── Icon coin màu secondary ──────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.monetization_on_rounded,
                  size: 20, color: Color(0xFF412402)),
            ),
          ),
          const SizedBox(width: 12),

          // ── Thông tin điểm ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm hiện có',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Dùng để đổi phần thưởng bên dưới',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          // ── Badge VIP / cấp độ (tuỳ chọn) ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.secondary.withOpacity(0.45), width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    size: 12, color: AppColors.secondary),
                SizedBox(width: 3),
                Text(
                  'VIP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
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