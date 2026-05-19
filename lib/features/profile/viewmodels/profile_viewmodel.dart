// lib/features/profile/viewmodels/profile_viewmodel.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../data/repositories/auth_repo.dart';
import 'profile_state.dart';

final profileViewModelProvider =
StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final vm = ProfileViewModel(ref);

  ref.listen(authRepoProvider, (previous, next) {
    if (previous?.userId != next.userId && next.userId != null) {
      vm.loadProfile();
    }
    if (next.isUnauthenticated || next.isOnboarding) {
      vm.resetState();
    }
  });

  return vm;
});

class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ProfileViewModel(this._ref) : super(const ProfileState()) {
    loadProfile();
  }

  void resetState() => state = const ProfileState();

  // ── Load / Refresh ──────────────────────────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final user = UserModel.fromFirestore(
          uid, userDoc.data() as Map<String, dynamic>? ?? {});

      state = state.copyWith(user: user);
    } catch (_) {
      // Silent fail — không làm gián đoạn UI
    }
  }

  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Chưa đăng nhập');

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        _db.collection('users').doc(uid).get(),
        _db.collection('daily_tracking').doc('${uid}_$today').get(),
      ]);

      final userDoc  = results[0];
      final trackDoc = results[1];

      final user = UserModel.fromFirestore(
          uid, userDoc.data() as Map<String, dynamic>? ?? {});

      DailyTrackingData tracking = const DailyTrackingData();
      if (trackDoc.exists && trackDoc.data() != null) {
        final d      = trackDoc.data()!;
        final macros = (d['macros'] as Map<String, dynamic>?) ?? {};
        final water  = (d['water']  as Map<String, dynamic>?) ?? {};
        tracking = DailyTrackingData(
          targetKcal:      (d['target_kcal']   as num?)?.toDouble() ?? 2000,
          consumedKcal:    (d['consumed_kcal'] as num?)?.toDouble() ?? 0,
          protein:         (macros['protein']  as num?)?.toDouble() ?? 0,
          carbs:           (macros['carbs']    as num?)?.toDouble() ?? 0,
          fat:             (macros['fat']      as num?)?.toDouble() ?? 0,
          targetWaterMl:   (water['target_ml']   as num?)?.toInt() ?? 2000,
          consumedWaterMl: (water['consumed_ml'] as num?)?.toInt() ?? 0,
        );
      }

      state = state.copyWith(
        status:   ProfileStatus.success,
        user:     user,
        tracking: tracking,
      );
    } catch (e) {
      state = state.copyWith(
        status:       ProfileStatus.error,
        errorMessage: 'Không thể tải hồ sơ: $e',
      );
    }
  }

  // ── Cập nhật tên ──────────────────────────────────────────────────────────
  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    state = state.copyWith(isSavingName: true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({'name': newName.trim()});
      await _auth.currentUser!.updateDisplayName(newName.trim());
      state = state.copyWith(
        isSavingName: false,
        user: state.user?.copyWith(name: newName.trim()),
      );
    } catch (e) {
      state = state.copyWith(
        isSavingName: false,
        errorMessage: 'Không thể cập nhật tên: $e',
      );
    }
  }

  // ── Cập nhật mục tiêu ─────────────────────────────────────────────────────
  Future<void> updateGoal(String newGoal) async {
    if (newGoal.trim().isEmpty) return;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({'goal': newGoal.trim()});
      state = state.copyWith(
        user: state.user?.copyWith(goal: newGoal.trim()),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Không thể cập nhật mục tiêu: $e',
      );
    }
  }

  // ── Cập nhật mức độ hoạt động ─────────────────────────────────────────────
  Future<void> updateActivityLevel(String newLevel) async {
    if (newLevel.trim().isEmpty) return;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _db
          .collection('users')
          .doc(uid)
          .update({'activity_level': newLevel.trim()});
      state = state.copyWith(
        user: state.user?.copyWith(activityLevel: newLevel.trim()),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Không thể cập nhật mức hoạt động: $e',
      );
    }
  }

  // ── Upload avatar ──────────────────────────────────────────────────────────
  Future<void> uploadAvatar(File imageFile) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final url = await CloudinaryService.uploadImage(imageFile);
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({'avatar_url': url});
      state = state.copyWith(
        isUploadingAvatar: false,
        user: state.user?.copyWith(avatarUrl: url),
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: 'Tải ảnh thất bại: $e',
      );
    }
  }

  // ── Đăng xuất ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _ref.read(authRepoProvider.notifier).signOut();
  }
}