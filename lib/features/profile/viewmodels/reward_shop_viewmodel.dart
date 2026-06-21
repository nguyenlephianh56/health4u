// lib/features/profile/viewmodels/reward_shop_viewmodel.dart
//
// Quản lý toàn bộ state của màn hình Reward Shop.
// Dùng Riverpod StateNotifier + RewardRepo.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/models/reward_model.dart';
import '../../../data/repositories/reward_repo.dart';
import 'reward_shop_state.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
// autoDispose: huỷ ViewModel (và state cũ) khi không còn widget nào watch nữa,
// tránh giữ state của user cũ khi đổi tài khoản hoặc rời màn hình.
final rewardShopViewModelProvider =
StateNotifierProvider.autoDispose<RewardShopViewModel, RewardShopState>(
      (ref) => RewardShopViewModel(RewardRepo()),
);

// ── ViewModel ─────────────────────────────────────────────────────────────────
class RewardShopViewModel extends StateNotifier<RewardShopState> {
  final RewardRepo _repo;

  RewardShopViewModel(this._repo) : super(const RewardShopState());

  // ── Khởi tạo dữ liệu ──────────────────────────────────────────────────────
  Future<void> init({required String uid, required int totalPoints}) async {
    // Reset sạch state cũ trước khi load — phòng trường hợp ViewModel
    // chưa kịp bị dispose (đổi user, mở lại màn hình, v.v.) thì vẫn
    // không bị dính data của user trước.
    state = RewardShopState(isLoading: true, totalPoints: totalPoints);
    try {
      final results = await Future.wait([
        _repo.fetchAllItems(),
        _repo.fetchUserRewards(uid),
      ]);
      state = state.copyWith(
        allItems:    results[0] as List<RewardItem>,
        userRewards: results[1] as List<UserReward>,
        isLoading:   false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Không tải được dữ liệu. Vui lòng thử lại.',
      );
    }
  }

  // ── Mua phần thưởng ───────────────────────────────────────────────────────
  Future<void> purchase({
    required String     uid,
    required RewardItem item,
  }) async {
    if (state.isPurchasing) return;

    if (!state.canAfford(item.costPts)) {
      state = state.copyWith(
        errorMessage: 'Bạn không đủ điểm để mở khóa "${item.name}".',
      );
      return;
    }

    state = state.copyWith(isPurchasing: true, clearMessages: true);

    final error = await _repo.purchaseReward(uid: uid, item: item);

    if (error != null) {
      state = state.copyWith(isPurchasing: false, errorMessage: error);
      return;
    }

    // Cập nhật state local (không cần fetch lại toàn bộ)
    final docId     = '${uid}_${item.id}';
    final existing  = state.userRewards.indexWhere((r) => r.rewardId == item.id);
    List<UserReward> updated;

    if (existing >= 0) {
      // streak shield: +1 quantity
      updated = List.from(state.userRewards);
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + 1,
      );
    } else {
      updated = [
        ...state.userRewards,
        UserReward(
          id:          docId,
          userId:      uid,
          rewardId:    item.id,
          purchasedAt: DateTime.now(),
          isActive:    false,
          quantity:    1,
        ),
      ];
    }

    state = state.copyWith(
      isPurchasing:   false,
      totalPoints:    state.totalPoints - item.costPts,
      userRewards:    updated,
      successMessage: '🎉 Mở khóa "${item.name}" thành công!',
    );
  }

  // ── Kích hoạt / tháo title tag ────────────────────────────────────────────
  Future<void> activateTag({required String uid, required String rewardId}) async {
    await _repo.activateTag(uid: uid, rewardId: rewardId);

    final updated = state.userRewards.map((r) {
      if (r.rewardId == rewardId) return r.copyWith(isActive: true);
      return r.copyWith(isActive: false);
    }).toList();

    state = state.copyWith(
      userRewards:    updated,
      successMessage: 'Đã trang bị danh hiệu!',
    );
  }

  Future<void> deactivateTag(String uid) async {
    await _repo.deactivateTag(uid);

    final updated = state.userRewards
        .map((r) => r.copyWith(isActive: false))
        .toList();

    state = state.copyWith(userRewards: updated);
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
}