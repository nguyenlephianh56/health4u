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

// lib/data/repositories/auth_repo.dart

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'auth_state_model.dart';

const _kHasSeenOnboarding = 'has_seen_onboarding';
class AuthRepo extends StateNotifier<AuthStateModel> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepo({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
  // Bắt đầu ở loading — chờ _init() xong
        super(const AuthStateModel(status: AppAuthStatus.loading)) {
    _init();
  }

  // ── Khởi tạo một lần duy nhất ───────────────────────────────────────────
  // Đọc SharedPreferences + lắng nghe Firebase cùng lúc
  Future<void> _init() async {
    // Đọc SharedPreferences trước (rất nhanh, local)
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_kHasSeenOnboarding) ?? false;

    // Lấy user hiện tại ngay lập tức (không cần chờ stream)
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Chưa đăng nhập
      state = AuthStateModel(
        status: hasSeenOnboarding
            ? AppAuthStatus.unauthenticated  // đã xem onboarding → Login
            : AppAuthStatus.onboarding,      // chưa xem → Onboarding
      );
    } else {
      // Đã đăng nhập → đọc Firestore lấy thêm info
      await _loadUserState(currentUser.uid);
    }

    // Sau khi load xong mới lắng nghe stream
    // (tránh stream emit trước khi SharedPreferences được đọc)
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  // ── Xử lý khi đăng nhập / đăng xuất ────────────────────────────────────
  Future<void> _onAuthChanged(User? user) async {
    // Bỏ qua lần emit đầu tiên vì _init() đã xử lý rồi
    // (Chỉ xử lý khi state đã không còn loading)
    if (state.isLoading) return;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_kHasSeenOnboarding) ?? false;
      state = AuthStateModel(
        status: seen
            ? AppAuthStatus.unauthenticated
            : AppAuthStatus.onboarding,
      );
    } else {
      await _loadUserState(user.uid);
    }
  }

  // ── Đọc thông tin user từ Firestore ─────────────────────────────────────
  Future<void> _loadUserState(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        state = AuthStateModel(
          status: AppAuthStatus.needsSetup,
          userId: uid,
          role: 'user',
        );
        return;
      }

      final data = doc.data()!;
      final role = (data['role'] as String?) ?? 'user';
      final heightCm = data['height_cm'];

      state = AuthStateModel(
        status: heightCm != null
            ? AppAuthStatus.authenticated
            : AppAuthStatus.needsSetup,
        userId: uid,
        role: role,
      );
    } catch (e) {
      debugPrint('[AuthRepo] Firestore error: $e');
      state = const AuthStateModel(status: AppAuthStatus.unauthenticated);
    }
  }

  // ── Public methods ───────────────────────────────────────────────────────

  /// Gọi khi user bấm "Bắt đầu" hoặc "Bỏ qua" ở OnboardingScreen
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
    state = const AuthStateModel(status: AppAuthStatus.unauthenticated);
  }

  /// Đăng nhập
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // _onAuthChanged tự gọi sau khi Firebase emit
  }

  /// Đăng ký — role mặc định "user"
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
      'email':          email.trim(),
      'name':           name.trim(),
      'gender':         gender,
      'dob':            dob,
      'password_hash':  _hashPassword(password),
      'role':           'user',
      'height_cm':      null,
      'weight_kg':      null,
      'activity_level': null,
      'goal':           null,
      'current_streak': 0,
      'total_points':   0,
      'avatar_url':     null,
      'created_at':     FieldValue.serverTimestamp(),
    });

    await credential.user!.updateDisplayName(name.trim());

    // Đăng ký xong → đánh dấu đã xem onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
  }

  /// Lưu thông tin bổ sung sau khi đăng ký (InfoSetupScreen)
  Future<void> saveUserInfo({
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Chưa đăng nhập');

    await _db.collection('users').doc(uid).update({
      'height_cm':      heightCm,
      'weight_kg':      weightKg,
      'activity_level': activityLevel,
      'goal':           goal,
    });

    await _loadUserState(uid);
  }

  /// Đăng xuất — giữ hasSeenOnboarding = true → vào Login thẳng
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _hashPassword(String p) =>
      sha256.convert(utf8.encode(p)).toString();

  String? get currentUserId => _auth.currentUser?.uid;
}

// ════════════════════════════════════════════════════════════════════════════
// AuthRouterNotifier — ChangeNotifier cho GoRouter.refreshListenable
// ════════════════════════════════════════════════════════════════════════════
class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AuthRouterNotifier(this._ref) {
    _ref.listen<AuthStateModel>(
      authRepoProvider,
          (_, __) => notifyListeners(),
    );
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────
final authRepoProvider =
StateNotifierProvider<AuthRepo, AuthStateModel>((ref) => AuthRepo());

final authRouterNotifierProvider =
ChangeNotifierProvider<AuthRouterNotifier>(
        (ref) => AuthRouterNotifier(ref));