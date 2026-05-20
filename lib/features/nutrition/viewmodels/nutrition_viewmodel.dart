// lib/features/nutrition/viewmodels/nutrition_viewmodel.dart
//
// State, ViewModel và Providers cho feature Nutrition.
// Models (DailyTracking, MealEntry, DayNutrition) đã tách sang:
//   → lib/features/nutrition/models/nutrition_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/auth_repo.dart';
import '../../../data/models/nutrition_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NutritionState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, DayNutrition> weekData;

  const NutritionState({
    this.isLoading    = true,
    this.errorMessage,
    this.weekData     = const {},
  });

  DayNutrition dayOf(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return weekData[key] ?? DayNutrition(date: date);
  }

  NutritionState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, DayNutrition>? weekData,
  }) =>
      NutritionState(
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
        weekData:     weekData     ?? this.weekData,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class NutritionViewModel extends StateNotifier<NutritionState> {
  final Ref _ref;
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _fmt  = DateFormat('yyyy-MM-dd');
  final _recipeCache = <String, Map<String, dynamic>>{};

  NutritionViewModel(this._ref) : super(const NutritionState());

  // ── Load 7 ngày trong tuần ─────────────────────────────────────────────────
  Future<void> loadWeek(DateTime weekStart) async {
    final uid = _auth.currentUser?.uid;

    debugPrint('═══════════════════════════════════════════════');
    debugPrint('[NutritionVM] loadWeek()');
    debugPrint('[NutritionVM] uid       = $uid');
    debugPrint('[NutritionVM] weekStart = ${_fmt.format(weekStart)}');

    if (uid == null) {
      debugPrint('[NutritionVM] ❌ uid null → abort');
      state = const NutritionState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dates = List.generate(7, (i) => weekStart.add(Duration(days: i)));

      // Fetch user_plans và daily_tracking song song cho cả 7 ngày
      final results = await Future.wait([
        Future.wait(
          dates.map((d) => _db
              .collection('user_plans')
              .doc('${uid}_${_fmt.format(d)}')
              .get()),
        ),
        Future.wait(
          dates.map((d) => _db
              .collection('daily_tracking')
              .doc('${uid}_${_fmt.format(d)}')
              .get()),
        ),
      ]);

      final planDocs     = results[0];
      final trackingDocs = results[1];

      // Log kết quả
      for (int i = 0; i < planDocs.length; i++) {
        final doc = planDocs[i];
        if (doc.exists && doc.data() != null) {
          final meals = doc.data()!['meals'] as Map<String, dynamic>?;
          debugPrint('[NutritionVM] ✅ plan ${_fmt.format(dates[i])} → meals: ${meals?.keys.toList()}');
        } else {
          debugPrint('[NutritionVM] ❌ plan ${_fmt.format(dates[i])} → không có doc');
        }

        final tDoc = trackingDocs[i];
        if (tDoc.exists) {
          debugPrint('[NutritionVM] ✅ tracking ${_fmt.format(dates[i])} → consumed: ${tDoc.data()?['consumed_kcal']} / target: ${tDoc.data()?['target_kcal']}');
        } else {
          debugPrint('[NutritionVM] ❌ tracking ${_fmt.format(dates[i])} → không có doc');
        }
      }

      // Thu thập recipe_id chưa cache
      final toFetch = <String>{};
      for (final doc in planDocs) {
        if (!doc.exists || doc.data() == null) continue;
        final mealsRaw = (doc.data()!['meals'] as Map<String, dynamic>?) ?? {};
        for (final mealData in mealsRaw.values) {
          if (mealData is! Map) continue;
          final rid = mealData['recipe_id']?.toString() ?? '';
          if (rid.isNotEmpty && !_recipeCache.containsKey(rid)) toFetch.add(rid);
        }
      }

      // Batch-fetch recipe details
      if (toFetch.isNotEmpty) {
        debugPrint('[NutritionVM] fetch recipes: $toFetch');
        final recipeDocs = await Future.wait(
          toFetch.map((rid) => _db.collection('recipes').doc(rid).get()),
        );
        for (final doc in recipeDocs) {
          if (doc.exists && doc.data() != null) _recipeCache[doc.id] = doc.data()!;
        }
      }

      // Build weekData
      final newWeekData = <String, DayNutrition>{};
      for (int i = 0; i < 7; i++) {
        final dateStr = _fmt.format(dates[i]);
        final day     = _parseDay(dates[i], planDocs[i], trackingDocs[i]);
        newWeekData[dateStr] = day;
        debugPrint('[NutritionVM] parsed $dateStr: '
            'B=${day.breakfast.length} L=${day.lunch.length} '
            'D=${day.dinner.length} S=${day.snack.length} '
            'consumed=${day.tracking.consumedKcal}/${day.tracking.targetKcal}');
      }

      debugPrint('[NutritionVM] ✅ DONE');
      debugPrint('═══════════════════════════════════════════════');

      state = NutritionState(isLoading: false, weekData: newWeekData);
    } on FirebaseException catch (e) {
      debugPrint('[NutritionVM] ❌ FirebaseException [${e.code}]: ${e.message}');
      state = NutritionState(
        isLoading: false,
        errorMessage: 'Firebase lỗi [${e.code}]: ${e.message}',
      );
    } catch (e, st) {
      debugPrint('[NutritionVM] ❌ Exception: $e\n$st');
      state = NutritionState(
        isLoading: false,
        errorMessage: 'Không thể tải kế hoạch: $e',
      );
    }
  }

  // ── Reload 1 ngày ──────────────────────────────────────────────────────────
  Future<void> reloadDay(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final dateKey = _fmt.format(date);

      // Fetch song song cả plan lẫn tracking
      final results = await Future.wait([
        _db.collection('user_plans').doc('${uid}_$dateKey').get(),
        _db.collection('daily_tracking').doc('${uid}_$dateKey').get(),
      ]);

      final planDoc     = results[0];
      final trackingDoc = results[1];

      if (planDoc.exists && planDoc.data() != null) {
        final mealsRaw = (planDoc.data()!['meals'] as Map<String, dynamic>?) ?? {};
        final toFetch  = <String>{};
        for (final mealData in mealsRaw.values) {
          if (mealData is! Map) continue;
          final rid = mealData['recipe_id']?.toString() ?? '';
          if (rid.isNotEmpty && !_recipeCache.containsKey(rid)) toFetch.add(rid);
        }
        if (toFetch.isNotEmpty) {
          final recipeDocs = await Future.wait(
            toFetch.map((rid) => _db.collection('recipes').doc(rid).get()),
          );
          for (final d in recipeDocs) {
            if (d.exists && d.data() != null) _recipeCache[d.id] = d.data()!;
          }
        }
      }

      final dayNutrition = _parseDay(date, planDoc, trackingDoc);
      final updated      = Map<String, DayNutrition>.from(state.weekData);
      updated[dateKey]   = dayNutrition;
      state = state.copyWith(isLoading: false, weekData: updated);
    } catch (e) {
      debugPrint('[NutritionVM] reloadDay error: $e');
    }
  }

  // ── Toggle hoàn thành bữa ──────────────────────────────────────────────────
  Future<void> toggleMealCompleted({
    required String mealKey,
    required DateTime date,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateStr = _fmt.format(date);
    final day     = state.weekData[dateStr];
    if (day == null) return;

    final entry = day.allMeals.where((e) => e.mealKey == mealKey).firstOrNull;
    if (entry == null) return;

    final newVal = !entry.isCompleted;
    _patchCompleted(dateStr, day, mealKey, newVal);

    try {
      await _db
          .collection('user_plans')
          .doc('${uid}_$dateStr')
          .update({'meals.$mealKey.is_completed': newVal});
    } catch (e) {
      debugPrint('[NutritionVM] toggleMealCompleted error: $e');
      _patchCompleted(dateStr, day, mealKey, !newVal);
    }
  }

  void _patchCompleted(
      String dateStr,
      DayNutrition day,
      String mealKey,
      bool val,
      ) {
    MealEntry patch(MealEntry e) =>
        e.mealKey != mealKey ? e : e.copyWith(isCompleted: val);

    final updated = Map<String, DayNutrition>.from(state.weekData);
    updated[dateStr] = day.copyWith(
      breakfast: day.breakfast.map(patch).toList(),
      lunch:     day.lunch.map(patch).toList(),
      dinner:    day.dinner.map(patch).toList(),
      snack:     day.snack.map(patch).toList(),
    );
    state = state.copyWith(weekData: updated);
  }

  // ── Parse 1 doc → DayNutrition ─────────────────────────────────────────────
  DayNutrition _parseDay(
      DateTime date,
      DocumentSnapshot planDoc,
      DocumentSnapshot trackingDoc,
      ) {
    // Parse daily_tracking
    final tracking = DailyTracking.fromDoc(trackingDoc);

    if (!planDoc.exists || planDoc.data() == null) {
      return DayNutrition(date: date, tracking: tracking);
    }

    final data     = planDoc.data()! as Map<String, dynamic>;
    final mealsRaw = data['meals'] as Map<String, dynamic>?;
    if (mealsRaw == null || mealsRaw.isEmpty) {
      return DayNutrition(date: date, tracking: tracking);
    }

    final breakfast = <MealEntry>[];
    final lunch     = <MealEntry>[];
    final dinner    = <MealEntry>[];
    final snack     = <MealEntry>[];

    for (final key in ['Breakfast', 'Lunch', 'Dinner', 'Snack']) {
      final snap = mealsRaw[key];
      if (snap == null || snap is! Map) continue;

      final recipeId    = snap['recipe_id']?.toString() ?? '';
      final detail      = _recipeCache[recipeId] ?? const {};
      final prepTimeMin = (detail['prep_time_min'] as num?)?.toInt() ?? 0;

      final rawInst = detail['instructions'];
      final instructions = switch (rawInst) {
        List list => list.map((e) => e.toString()).toList(),
        String s  => s.split('\n').where((l) => l.trim().isNotEmpty).toList(),
        _         => <String>[],
      };

      final rawIng = detail['ingredients'];
      final ingredients = rawIng is List
          ? rawIng.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final entry = MealEntry(
        mealKey:      key,
        recipeId:     recipeId,
        name:         snap['name']?.toString() ?? '',
        imageUrl:     snap['image_url']?.toString() ?? '',
        calories:     (snap['calories'] as num?)?.toDouble() ?? 0,
        protein:      (snap['protein']  as num?)?.toDouble() ?? 0,
        carbs:        (snap['carbs']    as num?)?.toDouble() ?? 0,
        fat:          (snap['fat']      as num?)?.toDouble() ?? 0,
        prepTimeMin:  prepTimeMin,
        isCompleted:  snap['is_completed'] as bool? ?? false,
        instructions: instructions,
        ingredients:  ingredients,
      );

      switch (key) {
        case 'Breakfast': breakfast.add(entry);
        case 'Lunch':     lunch.add(entry);
        case 'Dinner':    dinner.add(entry);
        case 'Snack':     snack.add(entry);
      }
    }

    return DayNutrition(
      date:      date,
      breakfast: breakfast,
      lunch:     lunch,
      dinner:    dinner,
      snack:     snack,
      tracking:  tracking,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final selectedDayIndexProvider = StateProvider<int>(
      (ref) => DateTime.now().weekday - 1,
);

final weekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
});

final selectedDateProvider = Provider<DateTime>((ref) {
  final index     = ref.watch(selectedDayIndexProvider);
  final weekStart = ref.watch(weekStartProvider);
  return weekStart.add(Duration(days: index));
});

/// ── KEY FIX ──────────────────────────────────────────────────────────────────
/// Dùng ref.listen(authRepoProvider) THAY VÌ fireImmediately: true
/// → Đảm bảo loadWeek chỉ chạy SAU KHI Firebase Auth restore session xong
/// ─────────────────────────────────────────────────────────────────────────────
final nutritionViewModelProvider =
StateNotifierProvider<NutritionViewModel, NutritionState>((ref) {
  final vm = NutritionViewModel(ref);

  // Lắng nghe auth: chỉ load khi đã có userId (authenticated)
  ref.listen(authRepoProvider, (previous, next) {
    if (next.isAuthenticated && next.userId != null) {
      vm.loadWeek(ref.read(weekStartProvider));
    }
    if (next.isUnauthenticated) {
      vm.state = const NutritionState(isLoading: false);
    }
  });

  // Lắng nghe đổi tuần (user bấm < >)
  ref.listen<DateTime>(weekStartProvider, (previous, weekStart) {
    final auth = ref.read(authRepoProvider);
    if (auth.isAuthenticated && auth.userId != null) {
      vm.loadWeek(weekStart);
    }
  });

  return vm;
});