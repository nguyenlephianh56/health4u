// lib/features/home/viewmodels/home_viewmodel.dart

import 'dart:async';
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

  // Giữ subscription để cancel khi dispose / ngày thay đổi
  StreamSubscription? _planSub;
  StreamSubscription? _trackSub;

  // Cache user + target macro để combine với stream plan
  UserModel? _cachedUser;
  double _targetKcal = 2000;
  double _protein    = 0;
  double _carbs      = 0;
  double _fat        = 0;

  HomeViewModel(this._ref) : super(const HomeState()) {
    loadHome();
  }

  @override
  void dispose() {
    _planSub?.cancel();
    _trackSub?.cancel();
    super.dispose();
  }

  // ── Load user 1 lần, rồi stream 2 doc realtime ───────────────────────────
  Future<void> loadHome() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Cancel subscription cũ (VD: ngày mới hoặc reload)
    _planSub?.cancel();
    _trackSub?.cancel();

    state = state.copyWith(status: HomeStatus.loading);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // ── 1. Load user 1 lần (không cần realtime) ──────────────────────────
      final userDoc = await _db.collection('users').doc(uid).get();
      _cachedUser   = UserModel.fromFirestore(
          uid, userDoc.data() as Map<String, dynamic>? ?? {});

      // ── 2. Stream daily_tracking → cập nhật target macro realtime ────────
      _trackSub = _db
          .collection('daily_tracking')
          .doc('${uid}_$today')
          .snapshots()
          .listen((trackDoc) {
        if (trackDoc.exists && trackDoc.data() != null) {
          final d      = trackDoc.data()!;
          final macros = (d['macros'] as Map<String, dynamic>?) ?? {};
          _targetKcal  = (d['target_kcal'] as num?)?.toDouble() ?? 2000;
          _protein     = (macros['protein'] as num?)?.toDouble() ?? 0;
          _carbs       = (macros['carbs']   as num?)?.toDouble() ?? 0;
          _fat         = (macros['fat']     as num?)?.toDouble() ?? 0;
        }
        // Sau khi có target, apply lên state hiện tại
        state = state.copyWith(
          targetKcal: _targetKcal,
          protein:    _protein,
          carbs:      _carbs,
          fat:        _fat,
        );
      }, onError: (e) {
        state = state.copyWith(errorMessage: 'Lỗi tracking: $e');
      });

      // ── 3. Stream user_plans → cộng dồn consumed realtime ────────────────
      _planSub = _db
          .collection('user_plans')
          .doc('${uid}_$today')
          .snapshots()
          .listen((planDoc) {
        double consumedKcal    = 0;
        double consumedProtein = 0;
        double consumedCarbs   = 0;
        double consumedFat     = 0;
        int    mealsCompleted  = 0;

        if (planDoc.exists && planDoc.data() != null) {
          final meals =
              (planDoc.data()!['meals'] as Map<String, dynamic>?) ?? {};

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

        // Emit state mới → CalorieRingWidget tự animate
        state = state.copyWith(
          status:          HomeStatus.success,
          user:            _cachedUser,
          targetKcal:      _targetKcal,
          protein:         _protein,
          carbs:           _carbs,
          fat:             _fat,
          consumedKcal:    consumedKcal,
          consumedProtein: consumedProtein,
          consumedCarbs:   consumedCarbs,
          consumedFat:     consumedFat,
          mealsCompleted:  mealsCompleted,
        );
      }, onError: (e) {
        state = state.copyWith(
          status:       HomeStatus.error,
          errorMessage: 'Không thể tải dữ liệu: $e',
        );
      });
    } catch (e) {
      state = state.copyWith(
        status:       HomeStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      );
    }
  }

  // ── completeMeal: chỉ cần update Firestore, stream tự cập nhật state ─────
  // Vẫn giữ optimistic update để UX nhanh hơn 1 round-trip
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

    // Optimistic update — ring animate ngay, stream sẽ confirm sau
    state = state.copyWith(
      consumedKcal:    state.consumedKcal    + calories,
      consumedProtein: state.consumedProtein + protein,
      consumedCarbs:   state.consumedCarbs   + carbs,
      consumedFat:     state.consumedFat     + fat,
      mealsCompleted:  state.mealsCompleted  + 1,
    );

    try {
      await planRef.update({'meals.$mealKey.is_completed': true});
      // Stream listener sẽ tự emit đúng giá trị từ Firestore
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

  // ── uncompleteMeal: tương tự ──────────────────────────────────────────────
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

  void resetState() {
    _planSub?.cancel();
    _trackSub?.cancel();
    state = const HomeState();
  }
}