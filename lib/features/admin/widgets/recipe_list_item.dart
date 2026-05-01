// lib/features/admin/widgets/recipe_list_item.dart
//
// Widget hiển thị 1 recipe trong danh sách — có nút sửa và xóa.

import 'package:flutter/material.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/constants/app_colors.dart';

class RecipeListItem extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecipeListItem({
    super.key,
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
  });

  // Màu + label cho từng meal_type
  Color _mealTypeColor(String type) {
    switch (type) {
      case 'Lunch':   return const Color(0xFFFFF3CD);
      case 'Dinner':  return const Color(0xFFFFE0E0);
      case 'Snack':   return const Color(0xFFE8F5E9);
      default:        return const Color(0xFFE0F2FE); // Breakfast
    }
  }

  Color _mealTypeTextColor(String type) {
    switch (type) {
      case 'Lunch':   return const Color(0xFFB45309);
      case 'Dinner':  return const Color(0xFFDC2626);
      case 'Snack':   return const Color(0xFF16A34A);
      default:        return AppColors.primary;
    }
  }

  String _mealTypeLabel(String type) {
    switch (type) {
      case 'Breakfast': return 'Sáng';
      case 'Lunch':     return 'Trưa';
      case 'Dinner':    return 'Tối';
      case 'Snack':     return 'Xế';
      default:          return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Thông tin recipe
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges: meal_type + difficulty (nếu có)
                Row(
                  children: [
                    _Badge(
                      label: _mealTypeLabel(recipe.mealType),
                      bg: _mealTypeColor(recipe.mealType),
                      textColor: _mealTypeTextColor(recipe.mealType),
                    ),
                    if (recipe.flags.isVegan) ...[
                      const SizedBox(width: 6),
                      _Badge(
                        label: 'Vegan',
                        bg: const Color(0xFFE8F5E9),
                        textColor: const Color(0xFF16A34A),
                      ),
                    ],
                    if (recipe.flags.isVegetarian && !recipe.flags.isVegan) ...[
                      const SizedBox(width: 6),
                      _Badge(
                        label: 'Chay',
                        bg: const Color(0xFFE8F5E9),
                        textColor: const Color(0xFF16A34A),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Tên món
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                // Calo
                Text(
                  '${recipe.nutrition.calories.toInt()} kcal  •  ${recipe.prepTimeMin} phút',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          // Nút sửa
          _ActionBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            bg: AppColors.primary.withOpacity(0.08),
            onTap: onEdit,
          ),
          const SizedBox(width: 8),

          // Nút xóa
          _ActionBtn(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFE53935),
            bg: const Color(0xFFFFEBEB),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Badge({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
        required this.color,
        required this.bg,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}