// lib/features/home/viewmodels/home_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repo.dart';
import 'home_state.dart';

final homeViewModelProvider =
StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final vm = HomeViewModel(ref);

  ref.listen(authRepoProvider, (previous, next) {
    if (previous?.userId != next.userId && next.userId != null) {
      vm.loadHome();
    }
    if (next.isUnauthenticated) vm.resetState();
  });

  return vm;
});

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref               _ref;
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  HomeViewModel(this._ref) : super(const HomeState()) {
    loadHome();
  }

  // ── Load toàn bộ dữ liệu home ────────────────────────────────────────────
  Future<void> loadHome() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(status: HomeStatus.loading);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Load song song: user + user_plans + daily_tracking (lấy target)
      final results = await Future.wait([
        _db.collection('users').doc(uid).get(),
        _db.collection('user_plans').doc('${uid}_$today').get(),
        _db.collection('daily_tracking').doc('${uid}_$today').get(),
      ]);

      final userDoc  = results[0];
      final planDoc  = results[1];
      final trackDoc = results[2];

      final user = UserModel.fromFirestore(
          uid, userDoc.data() as Map<String, dynamic>? ?? {});

      // ── Target macro từ daily_tracking ──────────────────────────────────
      double targetKcal = 2000;
      double protein    = 0;
      double carbs      = 0;
      double fat        = 0;

      if (trackDoc.exists && trackDoc.data() != null) {
        final d      = trackDoc.data()!;
        final macros = (d['macros'] as Map<String, dynamic>?) ?? {};
        targetKcal   = (d['target_kcal'] as num?)?.toDouble() ?? 2000;
        protein      = (macros['protein'] as num?)?.toDouble() ?? 0;
        carbs        = (macros['carbs']   as num?)?.toDouble() ?? 0;
        fat          = (macros['fat']     as num?)?.toDouble() ?? 0;
      }

      // ── Consumed: cộng dồn các meal is_completed=true trong user_plans ──
      double consumedKcal    = 0;
      double consumedProtein = 0;
      double consumedCarbs   = 0;
      double consumedFat     = 0;
      int    mealsCompleted  = 0;

      if (planDoc.exists && planDoc.data() != null) {
        final meals = (planDoc.data()!['meals'] as Map<String, dynamic>?) ?? {};

        for (final meal in meals.values) {
          if (meal is! Map<String, dynamic>) continue;
          final isCompleted = meal['is_completed'] as bool? ?? false;
          if (!isCompleted) continue;

          consumedKcal    += (meal['calories'] as num?)?.toDouble() ?? 0;
          consumedProtein += (meal['protein']  as num?)?.toDouble() ?? 0;
          consumedCarbs   += (meal['carbs']    as num?)?.toDouble() ?? 0;
          consumedFat     += (meal['fat']      as num?)?.toDouble() ?? 0;
          mealsCompleted++;
        }
      }

      state = state.copyWith(
        status:          HomeStatus.success,
        user:            user,
        targetKcal:      targetKcal,
        consumedKcal:    consumedKcal,
        protein:         protein,
        carbs:           carbs,
        fat:             fat,
        consumedProtein: consumedProtein,
        consumedCarbs:   consumedCarbs,
        consumedFat:     consumedFat,
        mealsCompleted:  mealsCompleted,
      );
    } catch (e) {
      state = state.copyWith(
        status:       HomeStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      );
    }
  }

  // ── Hoàn thành 1 bữa ─────────────────────────────────────────────────────
  // Gọi từ TodayRoadmapWidget khi user bấm hoàn thành:
  //   ref.read(homeViewModelProvider.notifier).completeMeal(
  //     mealKey: 'Breakfast',
  //     calories: 480, protein: 35, carbs: 55, fat: 12,
  //   );
  Future<void> completeMeal({
    required String mealKey,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final today   = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final planRef = _db.collection('user_plans').doc('${uid}_$today');

    // Optimistic update — ring animate ngay lập tức
    state = state.copyWith(
      consumedKcal:    state.consumedKcal    + calories,
      consumedProtein: state.consumedProtein + protein,
      consumedCarbs:   state.consumedCarbs   + carbs,
      consumedFat:     state.consumedFat     + fat,
      mealsCompleted:  state.mealsCompleted  + 1,
    );

    try {
      // Dùng dot notation để update nested field
      await planRef.update({'meals.$mealKey.is_completed': true});
    } catch (e) {
      // Rollback nếu Firestore lỗi
      state = state.copyWith(
        consumedKcal:    state.consumedKcal    - calories,
        consumedProtein: state.consumedProtein - protein,
        consumedCarbs:   state.consumedCarbs   - carbs,
        consumedFat:     state.consumedFat     - fat,
        mealsCompleted:  state.mealsCompleted  - 1,
        errorMessage:    'Không thể cập nhật bữa ăn: $e',
      );
      rethrow;
    }
  }

  // ── Bỏ hoàn thành (undo) ─────────────────────────────────────────────────
  Future<void> uncompleteMeal({
    required String mealKey,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final today   = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final planRef = _db.collection('user_plans').doc('${uid}_$today');

    // Optimistic update
    state = state.copyWith(
      consumedKcal:    (state.consumedKcal    - calories).clamp(0, double.infinity),
      consumedProtein: (state.consumedProtein - protein).clamp(0, double.infinity),
      consumedCarbs:   (state.consumedCarbs   - carbs).clamp(0, double.infinity),
      consumedFat:     (state.consumedFat     - fat).clamp(0, double.infinity),
      mealsCompleted:  (state.mealsCompleted  - 1).clamp(0, 4),
    );

    try {
      await planRef.update({'meals.$mealKey.is_completed': false});
    } catch (e) {
      // Rollback
      state = state.copyWith(
        consumedKcal:    state.consumedKcal    + calories,
        consumedProtein: state.consumedProtein + protein,
        consumedCarbs:   state.consumedCarbs   + carbs,
        consumedFat:     state.consumedFat     + fat,
        mealsCompleted:  state.mealsCompleted  + 1,
        errorMessage:    'Không thể cập nhật bữa ăn: $e',
      );
      rethrow;
    }
  }

  void resetState() => state = const HomeState();
}