// lib/features/workout/viewmodels/workout_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health4u/data/repositories/health_repo.dart';

import '../../../data/services/gamification_service.dart';
import '../../gamification/viewmodels/discipline_viewmodel.dart';

export 'package:health4u/data/repositories/health_repo.dart'
    show UserPlanDay, PlanWorkout;

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

extension UserPlanDayDisplay on UserPlanDay {
  String get dayShortLabel =>
      _dayLabels[dayOfWeek] ?? dayOfWeek.substring(0, 2);
  bool get hasWorkout => workout != null;
}

extension PlanWorkoutDisplay on PlanWorkout {
  String get difficultyVi => _difficultyLabel[difficulty] ?? difficulty;
  String get emoji        => _categoryEmoji[category] ?? '🏋️';
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutCompletionNotifier
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutCompletionNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final String _docId; // Firestore doc ID của UserPlanDay
  final DateTime _date;

  WorkoutCompletionNotifier(this._ref, this._docId, this._date, bool initial)
      : super(initial);

  /// Đánh dấu hoàn thành bài tập.
  /// Dùng đúng health_repo.markDayCompleted → ghi is_completed: true vào
  /// user_plans/{docId} — nhất quán với UserPlanDay.isCompleted
  Future<void> markCompleted() async {
    if (state) return; // Đã hoàn thành rồi, không làm gì

    // 1. Optimistic update
    state = true;

    try {
      // 2. Ghi Firestore qua health_repo (field: is_completed)
      await _ref.read(healthRepoProvider).markDayCompleted(_docId);

      // 3. Gọi GamificationService SAU KHI Firestore đã ghi xong
      //    Service sẽ tự đọc lại doc để kiểm tra dayFullyDone
      final gamification = _ref.read(gamificationServiceProvider);
      final result = await gamification.onWorkoutToggled(
        isCompleting: true,
        date: _date,
      );

      // 4. Trigger animation điểm
      if (result != null && result.pointsDelta != 0) {
        _ref
            .read(disciplineViewModelProvider.notifier)
            .showPointsDelta(result.pointsDelta);
      }

      debugPrint(
        '[WorkoutVM] ✅ markCompleted | '
            'delta=${result?.pointsDelta} | '
            'pts=${result?.newTotalPoints} | '
            'streak=${result?.newStreak} | '
            'streakUp=${result?.streakIncreased}',
      );
    } catch (e) {
      debugPrint('[WorkoutVM] ❌ markCompleted error: $e');
      state = false; // rollback
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Mặc định 0 — tự động nhảy về ngày hôm nay sau khi data load xong
/// (xử lý bởi ref.listen trong WorkoutScheduleScreen)
final selectedDayIndexProvider = StateProvider<int>((ref) => 0);

final selectedPlanDayProvider = Provider<AsyncValue<UserPlanDay?>>((ref) {
  return ref.watch(userPlanDaysProvider).whenData((days) {
    if (days.isEmpty) return null;
    final idx = ref.watch(selectedDayIndexProvider);
    return days[idx.clamp(0, days.length - 1)];
  });
});

final planWeeklyStatsProvider =
Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final selectedIdx = ref.watch(selectedDayIndexProvider);
  return ref.watch(userPlanDaysProvider).whenData((days) {
    if (days.isEmpty) {
      return {'minutes': 0, 'calories': 0, 'streak': 0, 'total': 0};
    }
    final selected = days[selectedIdx.clamp(0, days.length - 1)];
    final minutes  = selected.workout?.durationMin    ?? 0;
    final calories = selected.workout?.caloriesBurned ?? 0;
    final streak    = days.where((d) => d.isCompleted).length;
    final totalDays = days.where((d) => d.workout != null).length;
    return {
      'minutes':  minutes,
      'calories': calories,
      'done':     streak,
      'streak':   streak,
      'total':    totalDays,
    };
  });
});

/// Provider cho WorkoutCompletionNotifier — family theo docId + date
/// Cách dùng trong widget:
/// ```dart
/// // Lấy UserPlanDay từ selectedPlanDayProvider
/// final day = ref.watch(selectedPlanDayProvider).value;
/// if (day != null) {
///   final date = DateTime.parse(day.date);
///   final isCompleted = ref.watch(workoutCompletionProvider((docId: day.docId, date: date)));
///   final notifier    = ref.read(workoutCompletionProvider((docId: day.docId, date: date)).notifier);
///   ElevatedButton(onPressed: notifier.markCompleted, ...);
/// }
/// ```
typedef WorkoutCompletionArgs = ({String docId, DateTime date});

final workoutCompletionProvider = StateNotifierProvider.family<
    WorkoutCompletionNotifier, bool, WorkoutCompletionArgs>(
      (ref, args) {
    // Lấy trạng thái ban đầu từ userPlanDaysProvider
    final days = ref.read(userPlanDaysProvider).asData?.value ?? [];
    final dateStr =
        '${args.date.year}-${args.date.month.toString().padLeft(2, '0')}-${args.date.day.toString().padLeft(2, '0')}';
    final day = days.where((d) => d.date == dateStr).firstOrNull;
    final initialCompleted = day?.isCompleted ?? false;

    return WorkoutCompletionNotifier(ref, args.docId, args.date, initialCompleted);
  },
);