// lib/features/gamification/viewmodels/reward_shop_state.dart

import '../../../data/models/reward_model.dart';

class RewardShopState {
  final List<RewardItem>  allItems;
  final List<UserReward>  userRewards;
  final int               totalPoints;
  final bool              isLoading;
  final bool              isPurchasing;
  final String?           errorMessage;
  final String?           successMessage;

  const RewardShopState({
    this.allItems       = const [],
    this.userRewards    = const [],
    this.totalPoints    = 0,
    this.isLoading      = false,
    this.isPurchasing   = false,
    this.errorMessage,
    this.successMessage,
  });

  // ── Helper queries ─────────────────────────────────────────────────────────

  List<RewardItem> get shieldItems =>
      allItems.where((i) => i.type == RewardType.streakShield).toList();

  List<RewardItem> get tagItems =>
      allItems.where((i) => i.type == RewardType.titleTag).toList();

  /// Số thẻ shield còn lại của một item cụ thể
  int shieldQuantity(String rewardId) {
    final found = userRewards.where((r) => r.rewardId == rewardId).toList();
    if (found.isEmpty) return 0;
    return found.first.quantity;
  }

  /// Tag đang active
  UserReward? get activeTag =>
      userRewards.where((r) => r.isActive).firstOrNull;

  /// User đã sở hữu item chưa (quantity > 0)
  bool owns(String rewardId) {
    final found = userRewards.where((r) => r.rewardId == rewardId).toList();
    if (found.isEmpty) return false;
    return found.first.quantity > 0;
  }

  bool canAfford(int cost) => totalPoints >= cost;

  RewardShopState copyWith({
    List<RewardItem>?  allItems,
    List<UserReward>?  userRewards,
    int?               totalPoints,
    bool?              isLoading,
    bool?              isPurchasing,
    String?            errorMessage,
    String?            successMessage,
    bool               clearMessages = false,
  }) {
    return RewardShopState(
      allItems:       allItems      ?? this.allItems,
      userRewards:    userRewards   ?? this.userRewards,
      totalPoints:    totalPoints   ?? this.totalPoints,
      isLoading:      isLoading     ?? this.isLoading,
      isPurchasing:   isPurchasing  ?? this.isPurchasing,
      errorMessage:   clearMessages ? null : errorMessage   ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }
}