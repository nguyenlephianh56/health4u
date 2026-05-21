// lib/features/profile/views/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/profile_state.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/goals_widget.dart';
import '../widgets/reward_shop_preview_widget.dart';
import '../widgets/streak_widget.dart';
import '../widgets/how_to_earn_widget.dart';
import '../widgets/settings_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody(context, ref, state)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProfileState state) {
    if (state.status == ProfileStatus.loading && state.user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.status == ProfileStatus.error && state.user == null) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Không thể tải hồ sơ',
          style: const TextStyle(color: Colors.black45),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                const ProfileHeaderWidget(),
                const SizedBox(height: 16),
                if (state.user != null) ...[
                  GoalsWidget(user: state.user!, tracking: state.tracking),
                  const SizedBox(height: 16),

                  // ✅ Fix: bỏ truyền user — StreakWidget tự đọc realtime
                  const StreakWidget(),
                  const SizedBox(height: 16),

                  RewardShopPreviewWidget(
                    uid: state.user!.id,
                    onReturn: () {
                      ref
                          .read(profileViewModelProvider.notifier)
                          .refreshProfile();
                    },
                  ),
                  const SizedBox(height: 16),
                  const HowToEarnWidget(),
                  const SizedBox(height: 16),
                  const SettingsWidget(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}