// lib/data/services/meal_planner.dart
//
// Thuật toán lựa chọn recipe cho từng bữa:
//   1. Lọc theo meal_type
//   2. Nearest Neighbor: chọn món có calories gần nhất với target (±10%)
//   3. Chống lặp: không chọn lại món đã dùng trong 3 ngày gần nhất
//   4. Ưu tiên macros cân bằng

import '../../data/models/recipe_model.dart';

class MealPlanner {
  // ── Chọn recipe cho 1 bữa ────────────────────────────────────────────────
  // Trả về null nếu không tìm được món phù hợp
  static RecipeModel? selectRecipe({
    required List<RecipeModel> allRecipes,
    required String            mealType,      // "Breakfast" | "Lunch" | ...
    required double            targetKcal,    // Calo mục tiêu cho bữa này
    required List<String>      recentIds,     // ID món đã dùng 3 ngày gần nhất
  }) {
    // Bước 1: Lọc theo bữa + loại trừ món đã dùng gần đây
    final candidates = allRecipes.where((r) {
      if (r.mealType != mealType)         return false;
      if (recentIds.contains(r.id))       return false;
      return true;
    }).toList();

    if (candidates.isEmpty) {
      // Fallback: bỏ qua điều kiện chống lặp nếu không có lựa chọn
      final fallback = allRecipes
          .where((r) => r.mealType == mealType)
          .toList();
      if (fallback.isEmpty) return null;
      return _nearestNeighbor(fallback, targetKcal);
    }

    // Bước 2: Nearest Neighbor trong khoảng ±10%
    return _nearestNeighbor(candidates, targetKcal);
  }

  // ── Nearest Neighbor: chọn món gần target nhất ───────────────────────────
  static RecipeModel? _nearestNeighbor(
      List<RecipeModel> candidates,
      double            targetKcal,
      ) {
    if (candidates.isEmpty) return null;

    final tolerance = targetKcal * 0.10; // ±10%
    final lower     = targetKcal - tolerance;
    final upper     = targetKcal + tolerance;

    // Ưu tiên các món trong khoảng ±10%
    final inRange = candidates
        .where((r) => r.nutrition.calories >= lower &&
        r.nutrition.calories <= upper)
        .toList();

    final pool = inRange.isNotEmpty ? inRange : candidates;

    // Score = khoảng cách calories + bonus macro cân bằng
    RecipeModel? best;
    double      bestScore = double.infinity;

    for (final r in pool) {
      final calDiff    = (r.nutrition.calories - targetKcal).abs();
      final macroScore = _macroBalanceScore(r.nutrition);
      final score      = calDiff - macroScore * 10; // macroScore làm giảm penalty

      if (score < bestScore) {
        bestScore = score;
        best      = r;
      }
    }

    return best;
  }

  // ── Macro balance score (0.0 → 1.0, cao hơn = cân bằng hơn) ────────────
  // Tỷ lệ lý tưởng: Protein 25%, Carbs 50%, Fat 25% của tổng calo
  static double _macroBalanceScore(RecipeNutrition n) {
    if (n.calories == 0) return 0;
    final totalFromMacros = n.protein * 4 + n.carbs * 4 + n.fat * 9;
    if (totalFromMacros == 0) return 0;

    final pRatio = (n.protein * 4) / totalFromMacros;
    final cRatio = (n.carbs   * 4) / totalFromMacros;
    final fRatio = (n.fat     * 9) / totalFromMacros;

    // Khoảng cách Euclidean so với tỷ lệ lý tưởng (0.25, 0.50, 0.25)
    final dist = ((pRatio - 0.25) * (pRatio - 0.25) +
        (cRatio - 0.50) * (cRatio - 0.50) +
        (fRatio - 0.25) * (fRatio - 0.25));

    // Chuyển khoảng cách → score (gần 0 = cân bằng tốt → score cao)
    return 1.0 / (1.0 + dist * 10);
  }

  // ── Lập thực đơn 1 ngày đầy đủ ──────────────────────────────────────────
  // Trả về Map<mealType, RecipeModel?>
  static Map<String, RecipeModel?> planDay({
    required List<RecipeModel>    allRecipes,
    required Map<String, double>  mealCalories, // từ NutritionCalculator.splitMealCalories
    required List<String>         recentIds,
  }) {
    final plan = <String, RecipeModel?>{};
    final usedThisDay = <String>[];

    for (final entry in mealCalories.entries) {
      final mealType   = entry.key;
      final targetKcal = entry.value;

      final recipe = selectRecipe(
        allRecipes: allRecipes,
        mealType:   mealType,
        targetKcal: targetKcal,
        recentIds:  [...recentIds, ...usedThisDay],
      );

      plan[mealType] = recipe;
      if (recipe != null) usedThisDay.add(recipe.id);
    }

    return plan;
  }
}