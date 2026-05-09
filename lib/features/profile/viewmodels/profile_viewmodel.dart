// lib/features/profile/viewmodels/profile_viewmodel.dart
//
// Vai trò MVVM: ViewModel — xử lý logic, gọi Firestore/Cloudinary
// View KHÔNG gọi Firebase trực tiếp

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

// ─── Provider ────────────────────────────────────────────────────────────────
// ✅ FIX: Dùng StreamProvider lắng nghe Firebase Auth stream
// Mỗi khi user thay đổi (login/logout) → provider tự rebuild
// → ProfileViewModel tạo mới → loadProfile() gọi lại → hiện đúng tên
final profileViewModelProvider =
StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final vm = ProfileViewModel(ref);

  // Lắng nghe authRepoProvider — khi userId thay đổi → reload profile
  ref.listen(authRepoProvider, (previous, next) {
    // Chỉ reload khi userId thực sự thay đổi (tránh reload thừa)
    if (previous?.userId != next.userId && next.userId != null) {
      vm.loadProfile();
    }
    // User vừa logout → reset state về initial
    if (next.isUnauthenticated || next.isOnboarding) {
      vm.resetState();
    }
  });

  return vm;
});

// ─── ViewModel ───────────────────────────────────────────────────────────────
class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ProfileViewModel(this._ref) : super(const ProfileState()) {
    loadProfile();
  }

  // Reset state về initial (dùng khi logout)
  void resetState() {
    state = const ProfileState();
  }

  // ── Load dữ liệu ban đầu ─────────────────────────────────────────────────
  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Chưa đăng nhập');

      // Load song song: user + daily_tracking hôm nay
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        _db.collection('users').doc(uid).get(),
        _db.collection('daily_tracking').doc('${uid}_$today').get(),
      ]);

      final userDoc    = results[0];
      final trackDoc   = results[1];

      final user = UserModel.fromFirestore(
          uid, userDoc.data() as Map<String, dynamic>? ?? {});

      DailyTrackingData tracking = const DailyTrackingData();
      if (trackDoc.exists && trackDoc.data() != null) {
        final d = trackDoc.data()!;
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

  // ── Cập nhật tên ─────────────────────────────────────────────────────────
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
        isSavingName:  false,
        errorMessage:  'Không thể cập nhật tên: $e',
      );
    }
  }

  // ── Upload avatar: image_picker → Cloudinary → Firestore ─────────────────
  Future<void> uploadAvatar(File imageFile) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      // 1. Upload lên Cloudinary
      final url = await CloudinaryService.uploadImage(imageFile);

      // 2. Lưu URL vào Firestore
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({'avatar_url': url});

      // 3. Cập nhật state
      state = state.copyWith(
        isUploadingAvatar: false,
        user: state.user?.copyWith(avatarUrl: url),
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage:      'Tải ảnh thất bại: $e',
      );
    }
  }

  // ── Đăng xuất ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _ref.read(authRepoProvider.notifier).signOut();
    // AuthRepo tự emit unauthenticated → GoRouter redirect về /login
  }
}