// lib/features/auth/viewmodels/auth_state.dart
//
// Mô tả: Định nghĩa tất cả các trạng thái (State) có thể xảy ra
// trong luồng Auth (đăng nhập, đăng ký). AuthViewModel sẽ emit
// các state này để View lắng nghe và cập nhật UI tương ứng.

enum AuthStatus {
  initial,    // Trạng thái ban đầu, chưa làm gì
  loading,    // Đang gọi Firebase, hiện loading spinner
  success,    // Thành công, điều hướng sang màn hình tiếp theo
  error,      // Có lỗi xảy ra, hiện thông báo lỗi
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage; // Chỉ có giá trị khi status == error

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  // Các factory constructor để tạo state dễ dàng hơn
  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.success() : this(status: AuthStatus.success);
  const AuthState.error(String message)
      : this(status: AuthStatus.error, errorMessage: message);

  // copyWith để tạo state mới từ state cũ (immutable pattern)
  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}