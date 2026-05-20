// lib/features/workout/viewmodels/workout_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health4u/data/repositories/health_repo.dart';

// ── Re-export để các widget khác dùng tiếp ────────────────────────────────────
export 'package:health4u/data/repositories/health_repo.dart'
    show UserPlanDay, PlanWorkout;

// ── Map tiếng Anh → hiển thị tiếng Việt ──────────────────────────────────────
const _dayLabels = {
  'Monday':    'T2',
  'Tuesday':   'T3',
  'Wednesday': 'T4',
  'Thursday':  'T5',
  'Friday':    'T6',
  'Saturday':  'T7',
  'Sunday':    'CN',
};

const _difficultyLabel = {
  'Beginner':     'Dễ',
  'Intermediate': 'Trung bình',
  'Advanced':     'Khó',
};

const _categoryEmoji = {
  'Strength': '💪',
  'Cardio':   '🏃',
  'Yoga':     '🧘',
  'HIIT':     '⚡',
};

// ── Extension tiện ích trên UserPlanDay ───────────────────────────────────────
extension UserPlanDayDisplay on UserPlanDay {
  /// "T2", "T3", … "CN"
  String get dayShortLabel =>
      _dayLabels[dayOfWeek] ?? dayOfWeek.substring(0, 2);

  bool get hasWorkout => workout != null;
}

extension PlanWorkoutDisplay on PlanWorkout {
  String get difficultyVi => _difficultyLabel[difficulty] ?? difficulty;
  String get emoji        => _categoryEmoji[category] ?? '🏋️';
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Index ngày đang chọn trong danh sách plan (0 = ngày đầu tiên)
final selectedDayIndexProvider = StateProvider<int>((ref) {
  // Thử chọn ngày hôm nay nếu có trong plan
  final asyncPlan = ref.read(userPlanDaysProvider);
  return asyncPlan.maybeWhen(
    data: (days) {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final idx = days.indexWhere((d) => d.date == todayStr);
      return idx >= 0 ? idx : 0;
    },
    orElse: () => 0,
  );
});

/// UserPlanDay đang được chọn
final selectedPlanDayProvider = Provider<AsyncValue<UserPlanDay?>>((ref) {
  return ref.watch(userPlanDaysProvider).whenData((days) {
    if (days.isEmpty) return null;
    final idx = ref.watch(selectedDayIndexProvider);
    return days[idx.clamp(0, days.length - 1)];
  });
});

/// Thống kê header — cập nhật theo ngày đang chọn:
/// - minutes/calories: của ngày đang chọn
/// - streak: số ngày đã hoàn thành (is_completed=true) / tổng ngày có workout
final planWeeklyStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final selectedIdx = ref.watch(selectedDayIndexProvider);
  return ref.watch(userPlanDaysProvider).whenData((days) {
    if (days.isEmpty) {
      return {'minutes': 0, 'calories': 0, 'streak': 0, 'total': 0};
    }

    // Ngày đang chọn
    final selected = days[selectedIdx.clamp(0, days.length - 1)];
    final minutes  = selected.workout?.durationMin    ?? 0;
    final calories = selected.workout?.caloriesBurned ?? 0;

    // Số ngày đã hoàn thành / tổng ngày có workout trong tuần
    final streak    = days.where((d) => d.isCompleted).length;
    final totalDays = days.where((d) => d.workout != null).length;

    return {
      'minutes':  minutes,
      'calories': calories,
      'streak':   streak,
      'total':    totalDays,
    };
  });
});