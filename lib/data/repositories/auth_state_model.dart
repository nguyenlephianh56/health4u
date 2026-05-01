// lib/data/repositories/auth_state_model.dart
//
// Mô tả: Model chứa thông tin auth dùng cho GoRouter guard.
// Được AuthRepo tạo ra và trả về cho router để quyết định redirect.
//
// Khác với AuthState (features/auth/viewmodels/auth_state.dart):
//   → AuthState      : chỉ dùng cho UI Login/Register (loading/success/error)
//   → AuthStateModel : dùng cho router guard (isLoggedIn/role/isSetupCompleted)
enum AppAuthStatus {
  loading,          // Đang khởi động, chờ Firebase + SharedPreferences
  onboarding,       // Lần đầu vào app, chưa xem onboarding
  unauthenticated,  // Đã xem onboarding, chưa đăng nhập
  needsSetup,       // Đã đăng nhập, chưa điền info (height, weight...)
  authenticated,    // Đã đăng nhập + đầy đủ thông tin → vào home
}

class AuthStateModel {
  final AppAuthStatus status;
  final String? role;    // "user" | "admin"
  final String? userId;

  const AuthStateModel({
    required this.status,
    this.role,
    this.userId,
  });

  // Shortcut getters cho router
  bool get isLoading        => status == AppAuthStatus.loading;
  bool get isOnboarding     => status == AppAuthStatus.onboarding;
  bool get isUnauthenticated=> status == AppAuthStatus.unauthenticated;
  bool get needsSetup       => status == AppAuthStatus.needsSetup;
  bool get isAuthenticated  => status == AppAuthStatus.authenticated;
  bool get isAdmin          => role == 'admin';
}