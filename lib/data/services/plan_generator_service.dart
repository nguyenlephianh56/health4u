// lib/data/services/plan_generator_service.dart
//
// Service tổng hợp: đọc dữ liệu → tính toán → lưu user_plans + daily_tracking
//
// Được gọi từ 2 nơi:
//   1. Cloud Function (trigger 00:00 thứ Hai hàng tuần)
//   2. Thủ công từ app (admin hoặc khi user mới đăng ký xong)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/recipe_model.dart';
import '../models/workout_model.dart';
import 'nutrition_calculator.dart';
import 'meal_planner.dart';
import 'workout_planner.dart';

class PlanGeneratorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _fmt = DateFormat('yyyy-MM-dd');

  // ── Entry point: Tạo kế hoạch cho 1 user ─────────────────────────────────
  Future<void> generateWeeklyPlan({
    required String uid,
    DateTime?       weekStart, // null = thứ Hai tuần hiện tại
  }) async {
    final monday = weekStart ?? _getThisMonday();

    // 1. Load dữ liệu song song
    final results = await Future.wait([
      _db.collection('users').doc(uid).get(),
      _db.collection('recipes').get(),
      _db.collection('workouts').get(),
      _getRecentMealIds(uid),  // ID món ăn 3 ngày gần nhất
    ]);

    final userDoc     = results[0] as DocumentSnapshot;
    final recipesSnap = results[1] as QuerySnapshot;
    final workoutsSnap= results[2] as QuerySnapshot;
    final recentMealIds = results[3] as List<String>;

    if (!userDoc.exists) return;
    final userData = userDoc.data() as Map<String, dynamic>;

    // 2. Tính target calories
    final weightKg      = (userData['weight_kg']    as num?)?.toDouble() ?? 70;
    final heightCm      = (userData['height_cm']    as num?)?.toDouble() ?? 170;
    final dob           = userData['dob']?.toString() ?? '';
    final gender        = userData['gender']?.toString() ?? 'Nam';
    final goal          = userData['goal']?.toString() ?? 'Giữ cân';
    final activityLevel = userData['activity_level']?.toString() ?? 'Ít vận động';
    final age           = NutritionCalculator.calculateAge(dob);
    final bmi           = NutritionCalculator.calculateBMI(weightKg, heightCm);

    final bmr        = NutritionCalculator.calculateBMR(
        weightKg: weightKg, heightCm: heightCm, age: age, gender: gender);
    final tdee       = NutritionCalculator.calculateTDEE(
        bmr: bmr, activityLevel: activityLevel);
    final targetKcal = NutritionCalculator.calculateTargetKcal(
        tdee: tdee, goal: goal);
    final mealCals   = NutritionCalculator.splitMealCalories(targetKcal);
    final macros     = NutritionCalculator.calculateMacros(targetKcal);
    final recDiff    = NutritionCalculator.recommendedDifficulty(bmi);

    // 3. Parse recipes + workouts
    final allRecipes  = recipesSnap.docs
        .map((d) => RecipeModel.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();
    final allWorkouts = workoutsSnap.docs
        .map((d) => WorkoutModel.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();

    // 4. Lập kế hoạch 7 ngày
    final workoutWeekPlan = WorkoutPlanner.planWeek(
      allWorkouts:     allWorkouts,
      activityLevel:   activityLevel,
      recommendedDiff: recDiff,
    );

    // 5. Xóa kế hoạch tuần tới cũ (nếu có) + tạo mới
    final batch = _db.batch();
    await _deleteOldWeekPlan(uid, monday, batch);

    for (int day = 0; day < 7; day++) {
      final date    = monday.add(Duration(days: day));
      final dateStr = _fmt.format(date);
      final docId   = '${uid}_$dateStr';

      // Lập thực đơn ngày đó (recentIds cộng dồn để tránh lặp trong tuần)
      final dayMeals = MealPlanner.planDay(
        allRecipes:   allRecipes,
        mealCalories: mealCals,
        recentIds:    recentMealIds,
      );

      // Thêm ID món hôm nay vào recentIds để ngày sau không lặp
      dayMeals.values.whereType<RecipeModel>().forEach((r) {
        if (!recentMealIds.contains(r.id)) recentMealIds.add(r.id);
      });

      final workout = workoutWeekPlan[day];

      // ── Lưu vào user_plans ────────────────────────────────────────
      final planRef = _db.collection('user_plans').doc(docId);
      batch.set(planRef, {
        'user_id':    uid,
        'date':       dateStr,
        'day_of_week': _dayName(day),
        'meals': {
          'Breakfast': _recipeRef(dayMeals['Breakfast']),
          'Lunch':     _recipeRef(dayMeals['Lunch']),
          'Snack':     _recipeRef(dayMeals['Snack']),
          'Dinner':    _recipeRef(dayMeals['Dinner']),
        },
        'workout':    workout != null ? {
          'workout_id':   workout.id,
          'title':        workout.title,
          'category':     workout.category,
          'difficulty':   workout.difficulty,
          'duration_min': workout.durationMin,
          'calories_burned': workout.caloriesBurned,
          'muscle_group': workout.muscleGroup,
        } : null,
        'created_at': FieldValue.serverTimestamp(),
      });

      // ── Lưu snapshot target_kcal vào daily_tracking ──────────────
      // Lưu snapshot để lịch sử không bị thay đổi khi user cập nhật cân nặng
      final trackRef = _db.collection('daily_tracking').doc(docId);
      batch.set(trackRef, {
        'user_id':       uid,
        'date':          dateStr,
        'target_kcal':   targetKcal,   // ← snapshot tại thời điểm tạo kế hoạch
        'consumed_kcal': 0,
        'meals_completed': 0,
        'macros': {
          'protein': macros['protein'],
          'carbs':   macros['carbs'],
          'fat':     macros['fat'],
        },
        'water': {
          'target_ml':   2000,
          'consumed_ml': 0,
        },
      }, SetOptions(merge: true)); // merge để không ghi đè nếu đã có data
    }

    await batch.commit();
  }

  // ── Tạo kế hoạch cho TẤT CẢ users (dùng cho weekly reset) ───────────────
  Future<void> generateForAllUsers({DateTime? weekStart}) async {
    final monday = weekStart ?? _getThisMonday();
    final snap   = await _db.collection('users').get();

    // Chạy tuần tự để tránh Firestore rate limit
    for (final doc in snap.docs) {
      try {
        await generateWeeklyPlan(uid: doc.id, weekStart: monday);
      } catch (e) {
        // Log lỗi nhưng tiếp tục với user tiếp theo
        print('[PlanGenerator] Error for ${doc.id}: $e');
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  // Lấy ID món ăn đã dùng trong 3 ngày gần nhất
  Future<List<String>> _getRecentMealIds(String uid) async {
    final recentIds = <String>[];
    final now       = DateTime.now();

    for (int i = 1; i <= 3; i++) {
      final date   = now.subtract(Duration(days: i));
      final docId  = '${uid}_${_fmt.format(date)}';
      final doc    = await _db.collection('user_plans').doc(docId).get();
      if (!doc.exists) continue;

      final meals = (doc.data()?['meals'] as Map<String, dynamic>?) ?? {};
      for (final meal in meals.values) {
        if (meal is Map && meal['recipe_id'] != null) {
          recentIds.add(meal['recipe_id'] as String);
        }
      }
    }

    return recentIds;
  }

  // Xóa kế hoạch tuần cũ trước khi tạo mới
  Future<void> _deleteOldWeekPlan(
      String uid, DateTime monday, WriteBatch batch) async {
    for (int day = 0; day < 7; day++) {
      final date  = monday.add(Duration(days: day));
      final docId = '${uid}_${_fmt.format(date)}';
      batch.delete(_db.collection('user_plans').doc(docId));
    }
  }

  // Convert RecipeModel → Map lưu Firestore
  Map<String, dynamic>? _recipeRef(RecipeModel? r) {
    if (r == null) return null;
    return {
      'recipe_id':   r.id,
      'name':        r.name,
      'calories':    r.nutrition.calories,
      'protein':     r.nutrition.protein,
      'carbs':       r.nutrition.carbs,
      'fat':         r.nutrition.fat,
      'image_url':   r.imageUrl,
      'is_completed': false, // user chưa hoàn thành bữa
    };
  }

  // Thứ Hai của tuần hiện tại
  DateTime _getThisMonday() {
    final now     = DateTime.now();
    final weekday = now.weekday; // 1=Mon ... 7=Sun
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
  }

  String _dayName(int index) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return names[index];
  }
}