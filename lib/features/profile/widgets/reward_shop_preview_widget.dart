// lib/features/gamification/widgets/reward_shop_preview_widget.dart
//
// Widget preview nhỏ gọn hiển thị trong ProfileScreen.
// Đọc state trực tiếp từ profileViewModelProvider → luôn hiển thị dữ liệu mới nhất.
// Bấm vào → navigate tới RewardShopScreen → khi pop về gọi onReturn() để refresh.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../views/reward_shop_screen.dart';

class RewardShopPreviewWidget extends ConsumerWidget {
  final String uid;
  // Callback gọi sau khi user quay lại từ RewardShopScreen
  final VoidCallback onReturn;

  const RewardShopPreviewWidget({
    super.key,
    required this.uid,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đọc trực tiếp từ provider — không dùng props tĩnh nữa
    final user = ref.watch(
      profileViewModelProvider.select((s) => s.user),
    );

    // Nếu user chưa load xong thì không render gì
    if (user == null) return const SizedBox.shrink();

    final totalPoints  = user.totalPoints;
    final shieldCount  = user.shieldCount;
    final activeTagName = user.activeTagName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RewardShopScreen(
              uid:         uid,
              totalPoints: totalPoints,
            ),
          ),
        ).then((_) {
          // Khi RewardShopScreen pop về → gọi refresh ngay lập tức
          onReturn();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  '🎁  Reward Shop',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                // Badge điểm — cập nhật realtime từ provider
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalPoints pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Thông tin nhanh ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    emoji: '🛡️',
                    label: 'Thẻ bảo vệ',
                    value: shieldCount > 0 ? 'x$shieldCount còn lại' : 'Chưa có',
                    hasItem: shieldCount > 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    emoji: '🏷️',
                    label: 'Danh hiệu',
                    value: activeTagName ?? 'Chưa trang bị',
                    hasItem: activeTagName != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Nút vào shop ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vào Shop đổi thưởng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool   hasItem;

  const _InfoTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.hasItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasItem
            ? AppColors.primary.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasItem
              ? AppColors.primary.withOpacity(0.15)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasItem
                        ? AppColors.primary
                        : Colors.black.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}