// lib/data/repositories/auth_state_model.dart
//
// Mô tả: Model chứa thông tin auth dùng cho GoRouter guard.
// Được AuthRepo tạo ra và trả về cho router để quyết định redirect.
//
// Khác với AuthState (features/auth/viewmodels/auth_state.dart):
//   → AuthState      : chỉ dùng cho UI Login/Register (loading/success/error)
//   → AuthStateModel : dùng cho router guard (isLoggedIn/role/isSetupCompleted)

class AuthStateModel {
  final bool isLoggedIn;

  // true khi height_cm != null trong Firestore (đã qua InfoSetupScreen)
  final bool isSetupCompleted;

  // "user" | "admin" | null (chưa load xong)
  final String? role;

  final String? userId;

  const AuthStateModel({
    this.isLoggedIn = false,
    this.isSetupCompleted = false,
    this.role,
    this.userId,
  });

  // App vừa khởi động, chưa biết trạng thái
  const AuthStateModel.unknown() : this();

  // Chưa đăng nhập
  const AuthStateModel.unauthenticated() : this(isLoggedIn: false);

  // Đã đăng nhập nhưng chưa điền đủ thông tin (chưa qua InfoSetup)
  const AuthStateModel.authenticatedNoSetup({
    required String userId,
    required String role,
  }) : this(
    isLoggedIn: true,
    isSetupCompleted: false,
    role: role,
    userId: userId,
  );

  // Đã đăng nhập + đã setup đầy đủ
  const AuthStateModel.authenticated({
    required String userId,
    required String role,
  }) : this(
    isLoggedIn: true,
    isSetupCompleted: true,
    role: role,
    userId: userId,
  );

  bool get isAdmin => role == 'admin';
}