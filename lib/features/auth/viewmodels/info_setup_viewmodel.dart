// lib/features/auth/viewmodels/info_setup_viewmodel.dart
//
// Mô tả: ViewModel xử lý logic lưu thông tin bổ sung của user
//        (height_cm, weight_kg, activity_level, goal) lên Firestore.
//
// Vai trò MVVM:
//   → Nhận dữ liệu từ View (InfoSetupScreen)
//   → Validate + gọi Firestore để update document users/{userId}
//   → Emit InfoSetupState để View phản ứng (loading / success / error)
//
// KHÔNG import bất kỳ Widget nào của Flutter UI ở đây.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'info_setup_state.dart';

// ─── Provider ────────────────────────────────────────────────────────────────
final infoSetupViewModelProvider =
StateNotifierProvider<InfoSetupViewModel, InfoSetupState>((ref) {
  return InfoSetupViewModel();
});

// ─── ViewModel ───────────────────────────────────────────────────────────────
class InfoSetupViewModel extends StateNotifier<InfoSetupState> {
  InfoSetupViewModel() : super(const InfoSetupState.initial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lưu thông tin bổ sung vào Firestore → collection users/{userId}
  /// Được gọi từ InfoSetupScreen khi user bấm "Hoàn tất"
  Future<void> saveInfo({
    required double heightCm,      // Chiều cao (cm)
    required double weightKg,      // Cân nặng (kg)
    required String activityLevel, // "Ít vận động" | "Vận động vừa" | "Vận động mạnh"
    required String goal,          // "Tăng cân" | "Giữ cân" | "Giảm cân"
  }) async {
    state = const InfoSetupState.loading();

    try {
      final userId = _auth.currentUser?.uid;

      // Kiểm tra user đã đăng nhập chưa (không nên xảy ra nhưng phòng tránh)
      if (userId == null) {
        state = const InfoSetupState.error(
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        return;
      }

      // Update ĐÚNG các field còn thiếu trong document users/{userId}
      // (Các field khác như name, email, dob đã được lưu ở RegisterScreen)
      await _db.collection('users').doc(userId).update({
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'activity_level': activityLevel,
        'goal': goal,
      });

      state = const InfoSetupState.success();
    } on FirebaseException catch (e) {
      state = InfoSetupState.error(
          'Không thể lưu thông tin: ${e.message ?? 'Lỗi không xác định'}');
    } catch (_) {
      state = const InfoSetupState.error(
          'Đã có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  void resetState() => state = const InfoSetupState.initial();
}