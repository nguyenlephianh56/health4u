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

  // Reload khi user thay đổi (đổi account)
  ref.listen(authRepoProvider, (previous, next) {
    if (previous?.userId != next.userId && next.userId != null) {
      vm.loadHome();
    }
    if (next.isUnauthenticated) vm.resetState();
  });

  return vm;
});

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref             _ref;
  final FirebaseAuth    _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  HomeViewModel(this._ref) : super(const HomeState()) {
    loadHome();
  }

  Future<void> loadHome() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(status: HomeStatus.loading);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Load song song user + daily_tracking
      final results = await Future.wait([
        _db.collection('users').doc(uid).get(),
        _db.collection('daily_tracking').doc('${uid}_$today').get(),
      ]);

      final userDoc  = results[0];
      final trackDoc = results[1];

      final user = UserModel.fromFirestore(
          uid, userDoc.data() as Map<String, dynamic>? ?? {});

      double targetKcal   = 2000;
      double consumedKcal = 0;
      double protein      = 0;
      double carbs        = 0;
      double fat          = 0;
      int    meals        = 0;

      if (trackDoc.exists && trackDoc.data() != null) {
        final d      = trackDoc.data()!;
        final macros = (d['macros'] as Map<String, dynamic>?) ?? {};
        targetKcal   = (d['target_kcal']   as num?)?.toDouble() ?? 2000;
        consumedKcal = (d['consumed_kcal'] as num?)?.toDouble() ?? 0;
        protein      = (macros['protein']  as num?)?.toDouble() ?? 0;
        carbs        = (macros['carbs']    as num?)?.toDouble() ?? 0;
        fat          = (macros['fat']      as num?)?.toDouble() ?? 0;
        meals        = (d['meals_completed'] as num?)?.toInt() ?? 0;
      }

      state = state.copyWith(
        status:         HomeStatus.success,
        user:           user,
        targetKcal:     targetKcal,
        consumedKcal:   consumedKcal,
        protein:        protein,
        carbs:          carbs,
        fat:            fat,
        mealsCompleted: meals,
      );
    } catch (e) {
      state = state.copyWith(
        status:       HomeStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      );
    }
  }

  void resetState() => state = const HomeState();
}