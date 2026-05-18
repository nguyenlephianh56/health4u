// lib/features/nutrition/viewmodels/nutrition_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/recipe_model.dart';
import '../../../data/repositories/admin_repo.dart';

// ── State ────────────────────────────────────────────────────────────────────
class NutritionState {
  final bool isLoading;
  final List<RecipeModel> breakfast;
  final List<RecipeModel> lunch;
  final List<RecipeModel> dinner;
  final List<RecipeModel> snack;

  const NutritionState({
    this.isLoading = true,
    this.breakfast = const [],
    this.lunch     = const [],
    this.dinner    = const [],
    this.snack     = const [],
  });

  // Tổng kcal
  int get totalKcal =>
      _sum(breakfast) + _sum(lunch) + _sum(dinner) + _sum(snack);

  // Tổng macros
  int get protein =>
      _sumMacro(breakfast, 'protein') + _sumMacro(lunch, 'protein') +
          _sumMacro(dinner, 'protein')   + _sumMacro(snack, 'protein');

  int get carbs =>
      _sumMacro(breakfast, 'carbs') + _sumMacro(lunch, 'carbs') +
          _sumMacro(dinner, 'carbs')    + _sumMacro(snack, 'carbs');

  int get fat =>
      _sumMacro(breakfast, 'fat') + _sumMacro(lunch, 'fat') +
          _sumMacro(dinner, 'fat')    + _sumMacro(snack, 'fat');

  // Tất cả món
  List<RecipeModel> get allMeals =>
      [...breakfast, ...lunch, ...dinner, ...snack];

  int _sum(List<RecipeModel> list) =>
      list.fold(0, (s, r) => s + r.nutrition.calories.round());

  int _sumMacro(List<RecipeModel> list, String macro) {
    return list.fold(0, (s, r) {
      switch (macro) {
        case 'protein': return s + r.nutrition.protein.round();
        case 'carbs':   return s + r.nutrition.carbs.round();
        case 'fat':     return s + r.nutrition.fat.round();
        default:        return s;
      }
    });
  }

  NutritionState copyWith({
    bool? isLoading,
    List<RecipeModel>? breakfast,
    List<RecipeModel>? lunch,
    List<RecipeModel>? dinner,
    List<RecipeModel>? snack,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      breakfast: breakfast ?? this.breakfast,
      lunch:     lunch     ?? this.lunch,
      dinner:    dinner    ?? this.dinner,
      snack:     snack     ?? this.snack,
    );
  }
}

// ── ViewModel ────────────────────────────────────────────────────────────────
class NutritionViewModel extends StateNotifier<NutritionState> {
  final AdminRepo _repo;

  NutritionViewModel(this._repo) : super(const NutritionState()) {
    _listenRecipes();
  }

  void _listenRecipes() {
    _repo.watchRecipes().listen((recipes) {
      state = NutritionState(
        isLoading: false,
        breakfast: recipes
            .where((r) => r.mealType.toLowerCase() == 'breakfast')
            .toList(),
        lunch: recipes
            .where((r) => r.mealType.toLowerCase() == 'lunch')
            .toList(),
        dinner: recipes
            .where((r) => r.mealType.toLowerCase() == 'dinner')
            .toList(),
        snack: recipes
            .where((r) => r.mealType.toLowerCase() == 'snack')
            .toList(),
      );
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final selectedDayIndexProvider = StateProvider<int>((ref) => 3);

final nutritionViewModelProvider =
StateNotifierProvider<NutritionViewModel, NutritionState>((ref) {
  final repo = ref.watch(adminRepoProvider);
  return NutritionViewModel(repo);
});