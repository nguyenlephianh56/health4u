// lib/data/services/nutrition_calculator.dart
//
// Pure Dart — không phụ thuộc Flutter/Firebase
// Dễ unit test độc lập

class NutritionCalculator {
  // ── BMR (Mifflin-St Jeor) ─────────────────────────────────────────────────
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int    age,
    required String gender, // "Nam" | "Nữ"
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == 'Nam' ? base + 5 : base - 161;
  }

  // ── TDEE = BMR × Hệ số vận động ─────────────────────────────────────────
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    final factor = _activityFactor(activityLevel);
    return bmr * factor;
  }

  static double _activityFactor(String level) {
    switch (level) {
      case 'Ít vận động':    return 1.2;
      case 'Vận động vừa':   return 1.5;
      case 'Vận động mạnh':  return 1.75;
      default:               return 1.2;
    }
  }

  // ── Target Calories theo Goal ─────────────────────────────────────────────
  static double calculateTargetKcal({
    required double tdee,
    required String goal,
  }) {
    switch (goal) {
      case 'Giảm cân': return tdee - 500;
      case 'Tăng cân': return tdee + 500;
      default:          return tdee; // Giữ cân
    }
  }

  // ── Phân bổ calo cho 4 bữa ───────────────────────────────────────────────
  // Sáng 25% | Trưa 35% | Xế 15% | Tối 25%
  static Map<String, double> splitMealCalories(double targetKcal) {
    return {
      'Breakfast': targetKcal * 0.25,
      'Lunch':     targetKcal * 0.35,
      'Snack':     targetKcal * 0.15,
      'Dinner':    targetKcal * 0.25,
    };
  }

  // ── Macro targets (protein/carbs/fat) ────────────────────────────────────
  // Tỷ lệ chuẩn: P 25% / C 50% / F 25%
  static Map<String, double> calculateMacros(double targetKcal) {
    return {
      'protein': (targetKcal * 0.25 / 4).roundToDouble(), // 4 kcal/g
      'carbs':   (targetKcal * 0.50 / 4).roundToDouble(),
      'fat':     (targetKcal * 0.25 / 9).roundToDouble(), // 9 kcal/g
    };
  }

  // ── Tính tuổi từ dob string "YYYY-MM-DD" ─────────────────────────────────
  static int calculateAge(String dob) {
    if (dob.isEmpty) return 0;
    try {
      final birth = DateTime.parse(dob);
      final now   = DateTime.now();
      int age     = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  // ── BMI ───────────────────────────────────────────────────────────────────
  static double? calculateBMI(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final hm = heightCm / 100;
    return weightKg / (hm * hm);
  }

  // ── Difficulty phù hợp theo BMI ──────────────────────────────────────────
  // BMI cao → ưu tiên bài nhẹ để bảo vệ xương khớp
  static String recommendedDifficulty(double? bmi) {
    if (bmi == null) return 'Beginner';
    if (bmi >= 30)   return 'Beginner';
    if (bmi >= 25)   return 'Intermediate';
    return 'Advanced';
  }
}