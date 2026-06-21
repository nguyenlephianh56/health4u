// lib/features/profile/viewmodels/profile_state.dart

import '../../../data/models/user_model.dart';

enum ProfileStatus { initial, loading, success, error }

class DailyTrackingData {
  final double targetKcal;
  final double consumedKcal;
  final double protein;
  final double carbs;
  final double fat;
  final int    targetWaterMl;
  final int    consumedWaterMl;

  const DailyTrackingData({
    this.targetKcal      = 2000,
    this.consumedKcal    = 0,
    this.protein         = 0,
    this.carbs           = 0,
    this.fat             = 0,
    this.targetWaterMl   = 2000,
    this.consumedWaterMl = 0,
  });
}

// Sentinel để phân biệt "không truyền tham số" với "truyền null" trong copyWith.
class _Unset {
  const _Unset();
}
const _unset = _Unset();

class ProfileState {
  final ProfileStatus       status;
  final String?             errorMessage;
  final UserModel?          user;
  final DailyTrackingData   tracking;
  final bool                isUploadingAvatar;
  final bool                isSavingName;

  const ProfileState({
    this.status           = ProfileStatus.initial,
    this.errorMessage,
    this.user,
    this.tracking         = const DailyTrackingData(),
    this.isUploadingAvatar = false,
    this.isSavingName     = false,
  });

  ProfileState copyWith({
    ProfileStatus?      status,
    Object?             errorMessage = _unset,
    Object?             user         = _unset,
    DailyTrackingData?  tracking,
    bool?               isUploadingAvatar,
    bool?               isSavingName,
  }) {
    return ProfileState(
      status:            status            ?? this.status,
      errorMessage:      errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      user:              user == _unset
          ? this.user
          : user as UserModel?,
      tracking:          tracking          ?? this.tracking,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isSavingName:      isSavingName      ?? this.isSavingName,
    );
  }
}