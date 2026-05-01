// lib/features/auth/viewmodels/info_setup_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/repositories/auth_repo.dart';
import 'info_setup_state.dart';

// ─── Provider ────────────────────────────────────────────────────────────────
final infoSetupViewModelProvider =
StateNotifierProvider<InfoSetupViewModel, InfoSetupState>((ref) {
  return InfoSetupViewModel(ref);
});

// ─── ViewModel ───────────────────────────────────────────────────────────────
class InfoSetupViewModel extends StateNotifier<InfoSetupState> {
  final Ref _ref;

  InfoSetupViewModel(this._ref) : super(const InfoSetupState.initial());

  /// Lưu thông tin qua AuthRepo
  /// AuthRepo.saveUserInfo() cập nhật Firestore + emit state authenticated
  /// → GoRouter tự redirect về /home
  Future<void> saveInfo({
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) async {
    state = const InfoSetupState.loading();
    try {
      // ✅ Gọi AuthRepo thay vì tự gọi Firestore
      // AuthRepo sẽ update Firestore + emit AuthStateModel.authenticated
      // → authRouterNotifier.notifyListeners() → GoRouter redirect /home
      await _ref.read(authRepoProvider.notifier).saveUserInfo(
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: activityLevel,
        goal: goal,
      );
      state = const InfoSetupState.success();
    } catch (e) {
      state = InfoSetupState.error('Không thể lưu thông tin: $e');
    }
  }

  void resetState() => state = const InfoSetupState.initial();
}