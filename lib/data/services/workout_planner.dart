// lib/data/services/workout_planner.dart
//
// Thuật toán lựa chọn workout cho từng ngày:
//   1. Khớp difficulty theo BMI user
//   2. Xoay vòng nhóm cơ tránh quá tải
//   3. Phù hợp calories_burned với activity_level
//   4. Chống lặp bài tập trong tuần

import '../../data/models/workout_model.dart';

class WorkoutPlanner {
  // Thứ tự xoay vòng nhóm cơ 7 ngày
  // Đồng bộ với _muscleGroups trong workout_form_dialog.dart:
  // ['Ngực', 'Lưng', 'Chân', 'Vai', 'Tay', 'Cơ bụng', 'Toàn thân', 'Tim mạch']
  static const _muscleRotation = [
    'Ngực',      // Thứ 2
    'Lưng',      // Thứ 3
    'Chân',      // Thứ 4
    'Vai',       // Thứ 5
    'Tay',       // Thứ 6
    'Cơ bụng',   // Thứ 7
    'Toàn thân', // Chủ nhật — bài nhẹ, phục hồi
  ];

  // Target calories_burned theo activity_level
  static int _targetCaloriesBurned(String activityLevel) {
    switch (activityLevel) {
      case 'Vận động mạnh': return 400;
      case 'Vận động vừa':  return 280;
      default:              return 180; // Ít vận động
    }
  }

  // ── Chọn workout cho 1 ngày ───────────────────────────────────────────────
  static WorkoutModel? selectWorkout({
    required List<WorkoutModel> allWorkouts,
    required int                dayIndex,       // 0=Thứ2 ... 6=CN
    required String             activityLevel,
    required String             recommendedDiff, // từ NutritionCalculator
    required List<String>       usedThisWeek,   // ID đã dùng tuần này
  }) {
    final targetMuscle     = _muscleRotation[dayIndex % 7];
    final targetCalsBurned = _targetCaloriesBurned(activityLevel);
    final tolerance        = targetCalsBurned * 0.20; // ±20%

    // Bước 1: Lọc theo nhóm cơ + chưa dùng tuần này
    var candidates = allWorkouts.where((w) {
      if (usedThisWeek.contains(w.id)) return false;
      if (w.muscleGroup != targetMuscle) return false;
      return true;
    }).toList();

    // Fallback 1: Bỏ điều kiện chống lặp
    if (candidates.isEmpty) {
      candidates = allWorkouts
          .where((w) => w.muscleGroup == targetMuscle)
          .toList();
    }

    // Fallback 2: Bỏ điều kiện nhóm cơ (chọn bất kỳ)
    if (candidates.isEmpty) {
      candidates = allWorkouts
          .where((w) => !usedThisWeek.contains(w.id))
          .toList();
    }

    if (candidates.isEmpty) return null;

    // Bước 2: Score = khớp difficulty + khớp calories_burned
    WorkoutModel? best;
    double        bestScore = double.infinity;

    for (final w in candidates) {
      final diffScore   = _difficultyScore(w.difficulty, recommendedDiff);
      final calDiff     = (w.caloriesBurned - targetCalsBurned).abs().toDouble();
      final inTolerance = calDiff <= tolerance ? 0.0 : calDiff;

      // Tổng score: thấp hơn = tốt hơn
      final score = inTolerance + diffScore * 50;

      if (score < bestScore) {
        bestScore = score;
        best      = w;
      }
    }

    return best;
  }

  // ── Penalty theo độ lệch difficulty ──────────────────────────────────────
  // 0 = khớp chính xác, 1 = lệch 1 bậc, 2 = lệch 2 bậc
  static int _difficultyScore(String actual, String recommended) {
    const order = ['Beginner', 'Intermediate', 'Advanced'];
    final a = order.indexOf(actual);
    final r = order.indexOf(recommended);
    if (a < 0 || r < 0) return 1;
    return (a - r).abs();
  }

  // ── Lập lịch tập 7 ngày ──────────────────────────────────────────────────
  // Trả về List<WorkoutModel?> index 0=Thứ2 ... 6=CN
  static List<WorkoutModel?> planWeek({
    required List<WorkoutModel> allWorkouts,
    required String             activityLevel,
    required String             recommendedDiff,
  }) {
    final plan         = <WorkoutModel?>[];
    final usedThisWeek = <String>[];

    for (int day = 0; day < 7; day++) {
      final workout = selectWorkout(
        allWorkouts:     allWorkouts,
        dayIndex:        day,
        activityLevel:   activityLevel,
        recommendedDiff: recommendedDiff,
        usedThisWeek:    usedThisWeek,
      );

      plan.add(workout);
      if (workout != null) usedThisWeek.add(workout.id);
    }

    return plan;
  }
}