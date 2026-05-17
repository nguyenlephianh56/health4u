// lib/features/gamification/widgets/streak_shield_tab.dart
//
// Tab "Bảo vệ chuỗi" trong Reward Shop:
//   - Danh sách các gói streak shield
//   - Hiển thị số thẻ đang có, nút mua thêm

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reward_model.dart';
import '../viewmodels/reward_shop_viewmodel.dart';
import '../viewmodels/reward_shop_state.dart';

class StreakShieldTab extends ConsumerWidget {
  final String uid;

  const StreakShieldTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rewardShopViewModelProvider);
    final vm    = ref.read(rewardShopViewModelProvider.notifier);

    if (state.shieldItems.isEmpty) {
      return const Center(
        child: Text('Chưa có phần thưởng nào.',
            style: TextStyle(color: AppColors.text)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.shieldItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = state.shieldItems[i];
        final qty  = state.shieldQuantity(item.id);
        return _ShieldCard(
          item:       item,
          quantity:   qty,
          canAfford:  state.canAfford(item.costPts),
          isPurchasing: state.isPurchasing,
          onBuy: () => vm.purchase(uid: uid, item: item),
        );
      },
    );
  }
}

class _ShieldCard extends StatelessWidget {
  final RewardItem item;
  final int        quantity;
  final bool       canAfford;
  final bool       isPurchasing;
  final VoidCallback onBuy;

  const _ShieldCard({
    required this.item,
    required this.quantity,
    required this.canAfford,
    required this.isPurchasing,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford
              ? AppColors.primary.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(item.iconEmoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),

          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (quantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'x$quantity còn lại',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${item.costPts} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const Spacer(),
                    _BuyButton(
                      canAfford:   canAfford,
                      isPurchasing: isPurchasing,
                      onTap:       onBuy,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final bool         canAfford;
  final bool         isPurchasing;
  final VoidCallback onTap;

  const _BuyButton({
    required this.canAfford,
    required this.isPurchasing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPurchasing) {
      return const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: canAfford
              ? AppColors.primary
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          canAfford ? 'Mua ngay' : 'Không đủ pts',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: canAfford ? Colors.white : Colors.black38,
          ),
        ),
      ),
    );
  }
}