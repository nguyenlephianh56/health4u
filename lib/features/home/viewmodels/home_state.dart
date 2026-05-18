// lib/features/home/viewmodels/home_state.dart

import '../../../data/models/user_model.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState {
  final HomeStatus status;
  final String?    errorMessage;
  final UserModel? user;

  // Calo hôm nay
  final double targetKcal;
  final double consumedKcal;

  // Target macro — snapshot từ daily_tracking Firestore (tính lúc tạo plan)
  final double protein;
  final double carbs;
  final double fat;

  // Consumed macro — cộng dồn khi user hoàn thành từng bữa
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;

  // Số bữa đã hoàn thành hôm nay (0-4)
  final int mealsCompleted;

  const HomeState({
    this.status           = HomeStatus.initial,
    this.errorMessage,
    this.user,
    this.targetKcal       = 2000,
    this.consumedKcal     = 0,
    this.protein          = 0,
    this.carbs            = 0,
    this.fat              = 0,
    this.consumedProtein  = 0,
    this.consumedCarbs    = 0,
    this.consumedFat      = 0,
    this.mealsCompleted   = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    String?     errorMessage,
    UserModel?  user,
    double?     targetKcal,
    double?     consumedKcal,
    double?     protein,
    double?     carbs,
    double?     fat,
    double?     consumedProtein,
    double?     consumedCarbs,
    double?     consumedFat,
    int?        mealsCompleted,
  }) {
    return HomeState(
      status:          status          ?? this.status,
      errorMessage:    errorMessage    ?? this.errorMessage,
      user:            user            ?? this.user,
      targetKcal:      targetKcal      ?? this.targetKcal,
      consumedKcal:    consumedKcal    ?? this.consumedKcal,
      protein:         protein         ?? this.protein,
      carbs:           carbs           ?? this.carbs,
      fat:             fat             ?? this.fat,
      consumedProtein: consumedProtein ?? this.consumedProtein,
      consumedCarbs:   consumedCarbs   ?? this.consumedCarbs,
      consumedFat:     consumedFat     ?? this.consumedFat,
      mealsCompleted:  mealsCompleted  ?? this.mealsCompleted,
    );
  }

  // Calo còn lại
  double get remainingKcal =>
      (targetKcal - consumedKcal).clamp(0, targetKcal);

  // % đã nạp (0.0 → 1.0)
  double get calorieProgress =>
      targetKcal > 0 ? (consumedKcal / targetKcal).clamp(0.0, 1.0) : 0.0;

  // BMI tính từ user data
  double? get bmi {
    final h = user?.heightCm;
    final w = user?.weightKg;
    if (h == null || w == null || h == 0) return null;
    final hm = h / 100;
    return w / (hm * hm);
  }

  // Label trạng thái BMI — đồng bộ với BmiViewModel
  String get bmiLabel {
    final b = bmi;
    if (b == null) return '—';
    if (b < 18.5) return 'Thiếu cân';
    if (b < 25.0) return 'Bình thường';
    if (b < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  bool get hasBmi => bmi != null;
}