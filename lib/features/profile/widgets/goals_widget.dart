// lib/features/profile/widgets/goals_widget.dart
//
// Widget mục tiêu: goal, calo, dinh dưỡng, nước

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_state.dart';
import '../../../data/models/user_model.dart';

class GoalsWidget extends StatelessWidget {
  final UserModel user;
  final DailyTrackingData tracking;

  const GoalsWidget({
    super.key,
    required this.user,
    required this.tracking,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Mục tiêu',
      child: Column(
        children: [
          _GoalRow(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF0284C7),
            label: 'Mục tiêu',
            value: user.goalLabel,
          ),
          _divider(),
          _GoalRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFEA580C),
            label: 'Calo',
            value: '${tracking.consumedKcal.toInt()} / '
                '${tracking.targetKcal.toInt()} kcal',
          ),
          _divider(),
          _GoalRow(
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFF16A34A),
            label: 'Dinh dưỡng',
            value:
            '${tracking.protein.toInt()}g / '
                '${tracking.carbs.toInt()}g / '
                '${tracking.fat.toInt()}g',
            subtitle: 'Protein / Carbs / Fat',
          ),
          _divider(),
          _GoalRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Nước',
            value: '${tracking.targetWaterMl} ml / ngày',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 0.5,
    color: Colors.black.withOpacity(0.07),
  );
}

// ── Widget 1 dòng mục tiêu ────────────────────────────────────────────────────
class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final String?  subtitle;

  const _GoalRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Value + chevron
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card dùng chung ───────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}