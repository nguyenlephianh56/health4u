// lib/features/profile/widgets/theme_store_widget.dart
//
// Widget Theme Store — hiện tại là tĩnh, chức năng mở khóa sẽ bổ sung sau

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class _ThemeItem {
  final String emoji;
  final String name;
  final String description;
  final int    cost;
  final bool   isActive;
  final Color  previewColor;

  const _ThemeItem({
    required this.emoji,
    required this.name,
    required this.description,
    required this.cost,
    required this.isActive,
    required this.previewColor,
  });
}

const _themes = [
  _ThemeItem(
    emoji: '☁️',
    name: 'Sky Blue',
    description: 'Crisp sky blue background with white cards.',
    cost: 0,
    isActive: true,
    previewColor: Color(0xFF0284C7),
  ),
  _ThemeItem(
    emoji: '🌙',
    name: 'Midnight Dark',
    description: 'Sleek dark mode for night owls.',
    cost: 100,
    isActive: false,
    previewColor: Color(0xFF1E293B),
  ),
  _ThemeItem(
    emoji: '🌸',
    name: 'Soft Pastel',
    description: 'Gentle lavender and pink hues.',
    cost: 200,
    isActive: false,
    previewColor: Color(0xFFA78BFA),
  ),
  _ThemeItem(
    emoji: '🌊',
    name: 'Deep Ocean',
    description: 'Calming blues inspired by the sea.',
    cost: 350,
    isActive: false,
    previewColor: Color(0xFF0369A1),
  ),
  _ThemeItem(
    emoji: '🌿',
    name: 'Earthy Forest',
    description: 'Rich earth tones and deep greens.',
    cost: 500,
    isActive: false,
    previewColor: Color(0xFF16A34A),
  ),
];

class ThemeStoreWidget extends StatelessWidget {
  final int totalPoints;

  const ThemeStoreWidget({super.key, required this.totalPoints});

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
          Row(
            children: [
              const Text(
                '🎨  Theme Store',
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalPoints pts available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Danh sách theme
          ..._themes.map((theme) => _ThemeRow(
            theme: theme,
            canUnlock: totalPoints >= theme.cost,
          )),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final _ThemeItem theme;
  final bool       canUnlock;

  const _ThemeRow({required this.theme, required this.canUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.isActive
            ? AppColors.primary.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isActive
              ? AppColors.primary.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          // Preview color circle + emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.previewColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(theme.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Tên + mô tả
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (theme.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  theme.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
                if (!theme.isActive) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text('⭐',
                          style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text(
                        '${theme.cost} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Nút trạng thái
          if (theme.isActive)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'On',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canUnlock
                    ? AppColors.secondary.withOpacity(0.15)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    canUnlock
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 13,
                    color: canUnlock
                        ? const Color(0xFFB45309)
                        : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    canUnlock ? 'Mở khóa' : 'Locked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: canUnlock
                          ? const Color(0xFFB45309)
                          : Colors.black38,
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