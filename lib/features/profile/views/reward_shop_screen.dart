// lib/features/profile/views/reward_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/reward_shop_viewmodel.dart';
import '../widgets/points_banner_widget.dart';
import '../widgets/streak_shield_tab.dart';
import '../widgets/title_tag_tab.dart';

class RewardShopScreen extends ConsumerStatefulWidget {
  final String uid;
  final int totalPoints;

  const RewardShopScreen({
    super.key,
    required this.uid,
    required this.totalPoints,
  });

  @override
  ConsumerState<RewardShopScreen> createState() => _RewardShopScreenState();
}

class _RewardShopScreenState extends ConsumerState<RewardShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardShopViewModelProvider.notifier).init(
        uid:         widget.uid,
        totalPoints: widget.totalPoints,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rewardShopViewModelProvider);

    ref.listen(rewardShopViewModelProvider, (prev, next) {
      // ── Mua thành công → patch ngay profileViewModelProvider ────────────
      // Điểm mới và tag mới sẽ hiển thị ngay khi user quay lại ProfileScreen
      // mà không cần đợi refreshProfile() từ .then()
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        // Cập nhật điểm mới nhất vào profile state ngay lập tức
        ref.read(profileViewModelProvider.notifier).refreshProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(rewardShopViewModelProvider.notifier).clearMessages();
      }

      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(rewardShopViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
            ),
          ),
        ),
        title: const Text(
          'Reward shop',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.55),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Bảo vệ chuỗi'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Danh hiệu'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: PointsBannerWidget(totalPoints: state.totalPoints),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StreakShieldTab(uid: widget.uid),
                TitleTagTab(uid: widget.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}