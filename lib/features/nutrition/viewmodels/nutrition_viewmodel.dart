import 'package:flutter_riverpod/flutter_riverpod.dart';

// State chứa dữ liệu của màn hình
class NutritionState {
  final int totalKcal;
  final List<Map<String, dynamic>> meals;

  NutritionState({required this.totalKcal, required this.meals});

  NutritionState copyWith({int? totalKcal, List<Map<String, dynamic>>? meals}) {
    return NutritionState(
      totalKcal: totalKcal ?? this.totalKcal,
      meals: meals ?? this.meals,
    );
  }
}

// ViewModel xử lý logic
class NutritionViewModel extends StateNotifier<NutritionState> {
  NutritionViewModel() : super(NutritionState(totalKcal: 0, meals: [])) {
    _loadDailyMeals();
  }

  void _loadDailyMeals() {
    // Mock data 4 bữa/ngày theo giao diện
    final initialMeals = [
      {'type': 'BREAKFAST', 'name': 'Berry Oatmeal Bowl', 'cal': 290, 'time': '10m', 'macros': 'P: 10g  C: 52g  F: 6g'},
      {'type': 'LUNCH', 'name': 'Turkey & Avocado Wrap', 'cal': 410, 'time': '15m', 'macros': 'P: 28g  C: 45g  F: 15g'},
      {'type': 'SNACK', 'name': 'Mixed Nuts', 'cal': 190, 'time': '0m', 'macros': 'P: 5g  C: 8g  F: 15g'},
      {'type': 'DINNER', 'name': 'Teriyaki Salmon Rice Bowl', 'cal': 530, 'time': '25m', 'macros': 'P: 42g  C: 55g  F: 18g'},
    ];

    _updateState(initialMeals);
  }

  // Logic đổi món (Swap Dish)
  void swapMeal(int index, Map<String, dynamic> newMeal) {
    final updatedMeals = List<Map<String, dynamic>>.from(state.meals);
    updatedMeals[index] = newMeal;
    _updateState(updatedMeals);
  }

  // Logic tính lại tổng calo
  void _updateState(List<Map<String, dynamic>> meals) {
    int total = meals.fold(0, (sum, item) => sum + (item['cal'] as int));
    state = state.copyWith(meals: meals, totalKcal: total);
  }
}

// Providers
final nutritionViewModelProvider = StateNotifierProvider<NutritionViewModel, NutritionState>((ref) {
  return NutritionViewModel();
});

final selectedDayIndexProvider = StateProvider<int>((ref) => 2);