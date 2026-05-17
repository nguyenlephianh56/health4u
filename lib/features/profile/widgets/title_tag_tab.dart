// lib/features/profile/widgets/title_tag_tab.dart
//
// Tab "Danh hiệu" trong Reward Shop:
//   - Tag đang trang bị (nếu có)
//   - Tag đã sở hữu → nút trang bị / tháo ra
//   - Tag chưa mua → nút mở khóa / khoá (không đủ điểm)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reward_model.dart';
import '../viewmodels/reward_shop_viewmodel.dart';
import '../viewmodels/reward_shop_state.dart';

class TitleTagTab extends ConsumerWidget {
  final String uid;

  const TitleTagTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rewardShopViewModelProvider);
    final vm    = ref.read(rewardShopViewModelProvider.notifier);

    final activeTag = state.activeTag;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Tag đang trang bị ──────────────────────────────────────────────
        if (activeTag != null) ...[
          _SectionHeader(label: 'Đang trang bị'),
          const SizedBox(height: 8),
          _ActiveTagBanner(
            userReward: activeTag,
            items:      state.tagItems,
            onRemove:   () => vm.deactivateTag(uid),
          ),
          const SizedBox(height: 16),
        ],

        // ── Danh sách tag ──────────────────────────────────────────────────
        _SectionHeader(label: 'Tất cả danh hiệu'),
        const SizedBox(height: 8),
        ...state.tagItems.map((item) {
          final owned    = state.owns(item.id);
          final isActive = activeTag?.rewardId == item.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TagCard(
              item:       item,
              owned:      owned,
              isActive:   isActive,
              canAfford:  state.canAfford(item.costPts),
              isPurchasing: state.isPurchasing,
              onBuy:      () => vm.purchase(uid: uid, item: item),
              onEquip:    () => vm.activateTag(uid: uid, rewardId: item.id),
              onUnequip:  () => vm.deactivateTag(uid),
            ),
          );
        }),
      ],
    );
  }
}

// ── Widgets phụ ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black.withOpacity(0.4),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ActiveTagBanner extends StatelessWidget {
  final UserReward       userReward;
  final List<RewardItem> items;
  final VoidCallback     onRemove;

  const _ActiveTagBanner({
    required this.userReward,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final item = items.where((i) => i.id == userReward.rewardId).firstOrNull;
    if (item == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(item.iconEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Đang hiển thị trên profile của bạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tháo ra',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagCard extends StatelessWidget {
  final RewardItem   item;
  final bool         owned;
  final bool         isActive;
  final bool         canAfford;
  final bool         isPurchasing;
  final VoidCallback onBuy;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;

  const _TagCard({
    required this.item,
    required this.owned,
    required this.isActive,
    required this.canAfford,
    required this.isPurchasing,
    required this.onBuy,
    required this.onEquip,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withOpacity(0.3)
              : Colors.black.withOpacity(0.06),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: owned
                  ? AppColors.secondary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.iconEmoji,
                  style: const TextStyle(fontSize: 22)),
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
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Đang dùng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (owned && !isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Đã có',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                    height: 1.4,
                  ),
                ),
                if (!owned) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text(
                        '${item.costPts} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nút hành động
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    // Đang trang bị → nút tháo
    if (isActive) {
      return GestureDetector(
        onTap: onUnequip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Tháo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    // Đã sở hữu nhưng chưa trang bị → nút trang bị
    if (owned) {
      return GestureDetector(
        onTap: onEquip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Trang bị',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // Chưa mua
    if (isPurchasing) {
      return const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: canAfford ? onBuy : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: canAfford
              ? AppColors.secondary.withOpacity(0.15)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canAfford ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 12,
              color: canAfford ? const Color(0xFFB45309) : Colors.black38,
            ),
            const SizedBox(width: 4),
            Text(
              canAfford ? 'Mở khóa' : 'Locked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: canAfford ? const Color(0xFFB45309) : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}