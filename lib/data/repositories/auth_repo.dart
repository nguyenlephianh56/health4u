// lib/data/repositories/auth_repo.dart
//
// Mô tả: Repository xử lý toàn bộ logic Firebase Auth + Firestore
//        liên quan đến xác thực và phân quyền.
//
// Đây là tầng DATA — không import Widget nào của Flutter UI.
//
// Các lớp khác dùng auth_repo:
//   → features/auth/viewmodels/auth_viewmodel.dart   : gọi login(), register()
//   → features/auth/viewmodels/info_setup_viewmodel  : gọi saveUserInfo()
//   → router/app_router.dart                         : lắng nghe authStateStream
//
// Vị trí đúng theo kiến trúc:
//   lib/data/repositories/auth_repo.dart

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:convert';

import 'auth_state_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// CLASS 1: AuthRepo — StateNotifier<AuthStateModel>
// Quản lý trạng thái auth cho toàn app (Riverpod state).
// Được dùng bởi: GoRouter redirect, ShellScaffold, các ViewModel.
// ════════════════════════════════════════════════════════════════════════════

class AuthRepo extends StateNotifier<AuthStateModel> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepo({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        super(const AuthStateModel.unknown()) {
    // Lắng nghe Firebase Auth stream ngay từ đầu
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  // ── Xử lý khi auth state Firebase thay đổi ──────────────────────────────
  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = const AuthStateModel.unauthenticated();
    } else {
      await _loadUserState(user.uid);
    }
  }

  // ── Đọc role + trạng thái setup từ Firestore ────────────────────────────
  Future<void> _loadUserState(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        state = AuthStateModel.authenticatedNoSetup(
          userId: uid,
          role: 'user',
        );
        return;
      }

      final data = doc.data()!;
      final role = (data['role'] as String?) ?? 'user';
      final heightCm = data['height_cm'];

      state = heightCm != null
          ? AuthStateModel.authenticated(userId: uid, role: role)
          : AuthStateModel.authenticatedNoSetup(userId: uid, role: role);
    } catch (_) {
      state = const AuthStateModel.unauthenticated();
    }
  }

  // ── Public methods — được gọi từ ViewModel ───────────────────────────────

  /// Đăng nhập — gọi từ AuthViewModel.login()
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Đăng ký — gọi từ AuthViewModel.register()
  /// ✅ Set role = "user" mặc định khi tạo tài khoản
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dob,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'email': email.trim(),
      'name': name.trim(),
      'gender': gender,
      'dob': dob,
      'password_hash': _hashPassword(password),
      'role': 'user',                           // ✅ mặc định "user"
      'height_cm': null,
      'weight_kg': null,
      'activity_level': null,
      'goal': null,
      'current_streak': 0,
      'total_points': 0,
      'avatar_url': null,
      'created_at': FieldValue.serverTimestamp(),
    });

    await credential.user!.updateDisplayName(name.trim());
  }

  /// Lưu thông tin bổ sung — gọi từ InfoSetupViewModel.saveInfo()
  Future<void> saveUserInfo({
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Chưa đăng nhập');

    await _db.collection('users').doc(uid).update({
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
      'goal': goal,
    });

    // Reload lại state để router biết setup đã xong → redirect /home
    await _loadUserState(uid);
  }

  /// Đăng xuất — gọi từ ProfileViewModel
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helpers
  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  String? get currentUserId => _auth.currentUser?.uid;
}

// ════════════════════════════════════════════════════════════════════════════
// CLASS 2: AuthRouterNotifier — ChangeNotifier thuần
// Chỉ có 1 nhiệm vụ: gọi notifyListeners() khi auth state thay đổi
// để GoRouter tự re-evaluate redirect.
//
// KHÔNG quản lý state, KHÔNG gọi Firestore.
// Chỉ lắng nghe Firebase Auth stream và thông báo cho GoRouter.
// ════════════════════════════════════════════════════════════════════════════

class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AuthRouterNotifier(this._ref) {
    // Lắng nghe AuthRepo state thay đổi → báo GoRouter refresh
    _ref.listen<AuthStateModel>(
      authRepoProvider,
          (_, __) => notifyListeners(), // Mỗi khi AuthRepo state đổi → GoRouter chạy lại redirect
    );
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Provider chính — dùng ở ShellScaffold, app_router redirect
final authRepoProvider =
StateNotifierProvider<AuthRepo, AuthStateModel>((ref) {
  return AuthRepo();
});

/// Provider cho GoRouter refreshListenable
/// GoRouter cần Listenable → dùng AuthRouterNotifier (ChangeNotifier)
final authRouterNotifierProvider =
ChangeNotifierProvider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});