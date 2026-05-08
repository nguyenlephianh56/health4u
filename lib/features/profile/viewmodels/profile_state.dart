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
    String?             errorMessage,
    UserModel?          user,
    DailyTrackingData?  tracking,
    bool?               isUploadingAvatar,
    bool?               isSavingName,
  }) {
    return ProfileState(
      status:            status            ?? this.status,
      errorMessage:      errorMessage      ?? this.errorMessage,
      user:              user              ?? this.user,
      tracking:          tracking          ?? this.tracking,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isSavingName:      isSavingName      ?? this.isSavingName,
    );
  }
}