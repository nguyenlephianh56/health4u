// lib/features/nutrition/models/nutrition_models.dart
//
// Chứa toàn bộ data models của feature Nutrition:
//   • DailyTracking  – dữ liệu từ collection daily_tracking
//   • MealEntry      – 1 bữa ăn trong ngày
//   • DayNutrition   – 1 ngày (4 bữa + tracking)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DailyTracking
// ─────────────────────────────────────────────────────────────────────────────

class DailyTracking {
  final int consumedKcal;
  final int targetKcal;
  final int mealsCompleted;
  final int consumedMl;
  final int targetMl;

  /// Macros từ daily_tracking.macros (carbs, fat, protein)
  final int macroCarbs;
  final int macroFat;
  final int macroProtein;

  const DailyTracking({
    this.consumedKcal   = 0,
    this.targetKcal     = 2000,
    this.mealsCompleted = 0,
    this.consumedMl     = 0,
    this.targetMl       = 2000,
    this.macroCarbs     = 0,
    this.macroFat       = 0,
    this.macroProtein   = 0,
  });

  /// Phần trăm tiêu thụ so với mục tiêu (0.0 – 1.0)
  double get kcalProgress =>
      targetKcal > 0 ? (consumedKcal / targetKcal).clamp(0.0, 1.0) : 0.0;

  factory DailyTracking.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) return const DailyTracking();
    final d = doc.data()! as Map<String, dynamic>;
    final macros = (d['macros'] as Map<String, dynamic>?) ?? {};
    return DailyTracking(
      consumedKcal:   (d['consumed_kcal']   as num?)?.toInt() ?? 0,
      targetKcal:     (d['target_kcal']     as num?)?.toInt() ?? 2000,
      mealsCompleted: (d['meals_completed'] as num?)?.toInt() ?? 0,
      consumedMl:     (d['water']?['consumed_ml'] as num?)?.toInt() ?? 0,
      targetMl:       (d['water']?['target_ml']   as num?)?.toInt() ?? 2000,
      macroCarbs:     (macros['carbs']   as num?)?.toInt() ?? 0,
      macroFat:       (macros['fat']     as num?)?.toInt() ?? 0,
      macroProtein:   (macros['protein'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MealEntry
// ─────────────────────────────────────────────────────────────────────────────

class MealEntry {
  final String mealKey;
  final String recipeId;
  final String name;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int prepTimeMin;
  final bool isCompleted;
  final List<String> instructions;
  final List<Map<String, dynamic>> ingredients;

  const MealEntry({
    required this.mealKey,
    required this.recipeId,
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.prepTimeMin,
    required this.isCompleted,
    required this.instructions,
    required this.ingredients,
  });

  Map<String, dynamic> toCardMap() => {
    'id': recipeId,
    'mealKey': mealKey,
    'type': mealKey.toUpperCase(),
    'name': name,
    'image': imageUrl,
    'cal': calories.round(),
    'time': '${prepTimeMin}m',
    'protein': '${protein.round()}g',
    'carb': '${carbs.round()}g',
    'fat': '${fat.round()}g',
    'is_completed': isCompleted,
    'instructions': instructions,
    'ingredients': ingredients,
  };

  MealEntry copyWith({bool? isCompleted}) => MealEntry(
    mealKey: mealKey,
    recipeId: recipeId,
    name: name,
    imageUrl: imageUrl,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    prepTimeMin: prepTimeMin,
    isCompleted: isCompleted ?? this.isCompleted,
    instructions: instructions,
    ingredients: ingredients,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DayNutrition
// ─────────────────────────────────────────────────────────────────────────────

class DayNutrition {
  final DateTime date;
  final List<MealEntry> breakfast;
  final List<MealEntry> lunch;
  final List<MealEntry> dinner;
  final List<MealEntry> snack;

  /// Dữ liệu từ daily_tracking (calo tiêu thụ thực tế, target, nước...)
  final DailyTracking tracking;

  const DayNutrition({
    required this.date,
    this.breakfast = const [],
    this.lunch     = const [],
    this.dinner    = const [],
    this.snack     = const [],
    this.tracking  = const DailyTracking(),
  });

  bool get isEmpty =>
      breakfast.isEmpty && lunch.isEmpty && dinner.isEmpty && snack.isEmpty;

  List<MealEntry> get allMeals => [...breakfast, ...lunch, ...dinner, ...snack];

  // Tổng macro tính từ user_plans (kế hoạch)
  int get totalKcal    => allMeals.fold(0, (s, e) => s + e.calories.round());
  int get totalProtein => allMeals.fold(0, (s, e) => s + e.protein.round());
  int get totalCarbs   => allMeals.fold(0, (s, e) => s + e.carbs.round());
  int get totalFat     => allMeals.fold(0, (s, e) => s + e.fat.round());

  DayNutrition copyWith({
    List<MealEntry>? breakfast,
    List<MealEntry>? lunch,
    List<MealEntry>? dinner,
    List<MealEntry>? snack,
    DailyTracking?  tracking,
  }) =>
      DayNutrition(
        date:      date,
        breakfast: breakfast ?? this.breakfast,
        lunch:     lunch     ?? this.lunch,
        dinner:    dinner    ?? this.dinner,
        snack:     snack     ?? this.snack,
        tracking:  tracking  ?? this.tracking,
      );
}