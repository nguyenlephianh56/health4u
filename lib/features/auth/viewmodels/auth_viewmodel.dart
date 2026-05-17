// lib/features/auth/viewmodels/auth_viewmodel.dart
//
// Mô tả: ViewModel quản lý toàn bộ logic nghiệp vụ của màn hình Auth.
// Dùng Riverpod (StateNotifier) để quản lý state.
// View KHÔNG gọi Firebase trực tiếp — chỉ gọi các hàm trong file này.
//
// Dependency:
//   - AuthRepository (data/repositories/auth_repo.dart) để gọi Firebase
//   - AuthState (auth_state.dart) để emit trạng thái

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:convert';

import 'auth_state.dart';

// ─── Provider ───────────────────────────────────────────────────────────────
// Đây là "cổng" để View lấy ViewModel. Khai báo 1 lần, dùng ở mọi nơi.
final authViewModelProvider =
StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});

// ─── ViewModel ──────────────────────────────────────────────────────────────
class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState.initial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Đăng nhập ──────────────────────────────────────────────────────────
  // Được gọi từ: LoginScreen khi user bấm nút "Đăng nhập"
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // 1. Báo View hiện loading spinner
    state = const AuthState.loading();

    try {
      // 2. Gọi Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // 3. Thành công → View sẽ điều hướng sang /home
      state = const AuthState.success();
    } on FirebaseAuthException catch (e) {
      // 4. Thất bại → View hiện thông báo lỗi
      state = AuthState.error(_mapAuthError(e.code));
    } catch (_) {
      state = const AuthState.error('Đã có lỗi không xác định. Thử lại nhé!');
    }
  }

  // ── Đăng ký ────────────────────────────────────────────────────────────
  // Được gọi từ: RegisterScreen khi user bấm "Tạo tài khoản"
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String gender,     // "Nam" / "Nữ" / "Khác"
    required String dob,        // format "YYYY-MM-DD"
  }) async {
    state = const AuthState.loading();

    try {
      // 1. Tạo tài khoản trên Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userId = credential.user!.uid;

      // 2. Hash mật khẩu bằng SHA-256 trước khi lưu Firestore
      //    (password gốc chỉ Firebase Auth giữ, Firestore lưu bản hash)
      final passwordHash = _hashPassword(password);

      // 3. Lưu thông tin user vào Firestore — collection "users"
      //    Các field khớp hoàn toàn với thiết kế CSDL Firebase
      await _db.collection('users').doc(userId).set({
        'role' : 'user',
        'email': email.trim(),
        'name': name.trim(),
        'gender': gender,
        'dob': dob,                           // YYYY-MM-DD
        'password_hash': passwordHash,
        'height_cm': null,                    // Điền ở InfoSetupScreen
        'weight_kg': null,
        'activity_level': null,
        'goal': null,
        'current_streak': 0,
        'total_points': 0,
        'shield_count': 0,
        'active_tag_name': '',
        'avatar_url': null,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Cập nhật displayName trên Firebase Auth
      await credential.user!.updateDisplayName(name.trim());

      state = const AuthState.success();
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(_mapAuthError(e.code));
    } catch (_) {
      state = const AuthState.error('Không thể tạo tài khoản. Thử lại nhé!');
    }
  }

  // ── Reset state ─────────────────────────────────────────────────────────
  // Gọi khi cần xóa lỗi (vd: user bắt đầu gõ lại)
  void resetState() => state = const AuthState.initial();

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Hash mật khẩu bằng SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Map error code Firebase → thông báo tiếng Việt thân thiện
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'email-already-in-use':
        return 'Email này đã được dùng cho tài khoản khác.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Dùng ít nhất 8 ký tự.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet và thử lại.';
      default:
        return 'Đã có lỗi xảy ra (mã: $code). Thử lại nhé!';
    }
  }
}