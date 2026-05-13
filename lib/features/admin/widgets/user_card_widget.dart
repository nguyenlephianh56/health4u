// lib/features/admin/widgets/user_card_widget.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/admin_user_model.dart';

class UserCardWidget extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback   onDelete;

  const UserCardWidget({
    super.key,
    required this.user,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────────────────────────────
          _Avatar(avatarUrl: user.avatarUrl, name: user.name),
          const SizedBox(width: 12),

          // ── Thông tin chính ───────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Họ tên + Tuổi + BMI
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tuổi
                    if (user.age > 0)
                      _InfoChip(
                        label: '${user.age} tuổi',
                        bgColor: AppColors.primary.withOpacity(0.08),
                        textColor: AppColors.primary,
                      ),
                    const SizedBox(width: 6),

                    // BMI
                    if (user.bmi != null)
                      _InfoChip(
                        label: 'BMI ${user.bmi!.toStringAsFixed(1)}',
                        bgColor: _bmiBgColor(user.bmiLabel),
                        textColor: _bmiTextColor(user.bmiLabel),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Hàng 2: Gmail + Chuỗi hiện tại
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.45),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Streak
                    Row(
                      children: [
                        const Text('🔥',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Text(
                          '${user.currentStreak} ngày',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Nút xóa ───────────────────────────────────────────────────
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.person_remove_outlined,
                color: Color(0xFFE53935),
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _bmiBgColor(String label) {
    switch (label) {
      case 'Thiếu cân':   return const Color(0xFFDBEAFE);
      case 'Bình thường': return const Color(0xFFD1FAE5);
      case 'Thừa cân':    return const Color(0xFFFEF3C7);
      default:            return const Color(0xFFFFE0E0);
    }
  }

  Color _bmiTextColor(String label) {
    switch (label) {
      case 'Thiếu cân':   return const Color(0xFF1D4ED8);
      case 'Bình thường': return const Color(0xFF065F46);
      case 'Thừa cân':    return const Color(0xFFB45309);
      default:            return const Color(0xFFDC2626);
    }
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String  name;
  const _Avatar({required this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2), width: 1.5),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
          avatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(),
        )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final parts = name.trim().split(' ');
    final letters = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        letters,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Info chip nhỏ ─────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final Color  bgColor;
  final Color  textColor;
  const _InfoChip(
      {required this.label,
        required this.bgColor,
        required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor),
      ),
    );
  }
}