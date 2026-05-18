// lib/features/grocery/widgets/grocery_category_config.dart
//
// Cấu hình hiển thị tập trung cho từng IngredientCategory:
// emoji, label tiếng Việt, màu accent, màu nền nhạt.
// Dùng ở: GroceryCategorySection, GroceryHeader (filter chips)

import 'package:flutter/material.dart';

import '../../../data/models/recipe_model.dart';

class GroceryCategoryInfo {
  final String emoji;
  final String label;
  final Color color;
  final Color lightColor;

  const GroceryCategoryInfo({
    required this.emoji,
    required this.label,
    required this.color,
    required this.lightColor,
  });
}

class GroceryCategoryConfig {
  GroceryCategoryConfig._();

  static const Map<IngredientCategory, GroceryCategoryInfo> _map = {
    IngredientCategory.meat: GroceryCategoryInfo(
      emoji: '🥩',
      label: 'Thịt & Hải sản',
      color: Color(0xFFEF4444),
      lightColor: Color(0xFFFEF2F2),
    ),
    IngredientCategory.vegetable: GroceryCategoryInfo(
      emoji: '🥦',
      label: 'Rau & Củ quả',
      color: Color(0xFF22C55E),
      lightColor: Color(0xFFF0FDF4),
    ),
    IngredientCategory.dairy: GroceryCategoryInfo(
      emoji: '🥛',
      label: 'Sữa & Trứng',
      color: Color(0xFF3B82F6),
      lightColor: Color(0xFFEFF6FF),
    ),
    IngredientCategory.grain: GroceryCategoryInfo(
      emoji: '🌾',
      label: 'Ngũ cốc & Tinh bột',
      color: Color(0xFFF59E0B),
      lightColor: Color(0xFFFFFBEB),
    ),
    IngredientCategory.seasoning: GroceryCategoryInfo(
      emoji: '🧂',
      label: 'Gia vị & Dầu ăn',
      color: Color(0xFF8B5CF6),
      lightColor: Color(0xFFF5F3FF),
    ),
    IngredientCategory.other: GroceryCategoryInfo(
      emoji: '📦',
      label: 'Khác',
      color: Color(0xFF6B7280),
      lightColor: Color(0xFFF9FAFB),
    ),
  };

  /// Lấy config của 1 category (không bao giờ null)
  static GroceryCategoryInfo of(IngredientCategory cat) => _map[cat]!;

  /// Danh sách tất cả category theo thứ tự enum
  static List<IngredientCategory> get all => IngredientCategory.values;
}