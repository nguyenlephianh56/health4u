// lib/features/auth/viewmodels/info_setup_state.dart
//
// Mô tả: Định nghĩa trạng thái cho màn hình InfoSetup.
// InfoSetupViewModel sẽ emit các state này.

enum InfoSetupStatus {
  initial,  // Chưa làm gì
  loading,  // Đang lưu lên Firestore
  success,  // Lưu thành công → điều hướng sang /home
  error,    // Có lỗi
}

class InfoSetupState {
  final InfoSetupStatus status;
  final String? errorMessage;

  const InfoSetupState({
    this.status = InfoSetupStatus.initial,
    this.errorMessage,
  });

  const InfoSetupState.initial() : this(status: InfoSetupStatus.initial);
  const InfoSetupState.loading() : this(status: InfoSetupStatus.loading);
  const InfoSetupState.success() : this(status: InfoSetupStatus.success);
  const InfoSetupState.error(String msg)
      : this(status: InfoSetupStatus.error, errorMessage: msg);

  InfoSetupState copyWith({InfoSetupStatus? status, String? errorMessage}) {
    return InfoSetupState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}