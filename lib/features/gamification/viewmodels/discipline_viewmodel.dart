// lib/features/gamification/viewmodels/discipline_viewmodel.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/services/gamification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class DisciplineState {
  final int totalPoints;
  final int currentStreak;
  final int bestStreak;
  final bool isLoading;
  final int? lastPointsDelta;
  final int pointsDeltaId;

  const DisciplineState({
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isLoading = true,
    this.lastPointsDelta,
    this.pointsDeltaId = 0,
  });

  DisciplineState copyWith({
    int? totalPoints,
    int? currentStreak,
    int? bestStreak,
    bool? isLoading,
    int? lastPointsDelta,
    int? pointsDeltaId,
  }) =>
      DisciplineState(
        totalPoints:     totalPoints     ?? this.totalPoints,
        currentStreak:   currentStreak   ?? this.currentStreak,
        bestStreak:      bestStreak      ?? this.bestStreak,
        isLoading:       isLoading       ?? this.isLoading,
        lastPointsDelta: lastPointsDelta,
        pointsDeltaId:   pointsDeltaId   ?? this.pointsDeltaId,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class DisciplineViewModel extends StateNotifier<DisciplineState> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _gamificationService = GamificationService();

  StreamSubscription<DocumentSnapshot>? _userSub;

  DisciplineViewModel() : super(const DisciplineState()) {
    _listenToUser();
  }

  // ── Lắng nghe Firestore realtime ─────────────────────────────────────────

  void _listenToUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = const DisciplineState(isLoading: false);
      return;
    }

    // FIX STALE SUBSCRIPTION: Cancel sub cũ + reset state về loading TRƯỚC
    // khi subscribe mới — tránh sub của acc cũ emit đè lên acc mới
    _userSub?.cancel();
    _userSub = null;
    state = const DisciplineState(isLoading: true);

    // Gọi checkStreakReset() sau khi đã reset state
    // Chạy async độc lập — không block việc lắng nghe realtime
    _gamificationService.checkStreakReset().then((_) {
      debugPrint('[DisciplineVM] checkStreakReset done');
    }).catchError((e) {
      debugPrint('[DisciplineVM] checkStreakReset error: $e');
    });

    _userSub = _db.collection('users').doc(uid).snapshots().listen(
          (snap) {
        if (!snap.exists) {
          state = const DisciplineState(isLoading: false);
          return;
        }
        final data = snap.data() ?? {};
        state = state.copyWith(
          totalPoints:   (data['total_points']   as num?)?.toInt() ?? 0,
          currentStreak: (data['current_streak'] as num?)?.toInt() ?? 0,
          bestStreak:    (data['best_streak']    as num?)?.toInt() ?? 0,
          isLoading:     false,
        );
        debugPrint(
          '[DisciplineVM] realtime update: '
              'pts=${state.totalPoints} streak=${state.currentStreak} best=${state.bestStreak}',
        );
      },
      onError: (e) {
        debugPrint('[DisciplineVM] stream error: $e');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  // ── Gọi lại khi user đăng nhập lại ──────────────────────────────────────

  void refresh() {
    _listenToUser();
  }

  // ── Hiển thị animation điểm ──────────────────────────────────────────────

  void showPointsDelta(int delta) {
    state = state.copyWith(
      lastPointsDelta: delta,
      pointsDeltaId:   state.pointsDeltaId + 1,
    );
  }

  void clearPointsDelta() {
    state = state.copyWith(lastPointsDelta: null);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final disciplineViewModelProvider =
StateNotifierProvider<DisciplineViewModel, DisciplineState>((ref) {
  return DisciplineViewModel();
});

final totalPointsProvider = Provider<int>(
      (ref) => ref.watch(disciplineViewModelProvider).totalPoints,
);

final currentStreakProvider = Provider<int>(
      (ref) => ref.watch(disciplineViewModelProvider).currentStreak,
);

final bestStreakProvider = Provider<int>(
      (ref) => ref.watch(disciplineViewModelProvider).bestStreak,
);

final gamificationServiceProvider = Provider<GamificationService>(
      (_) => GamificationService(),
);