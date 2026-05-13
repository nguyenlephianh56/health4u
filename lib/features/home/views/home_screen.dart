// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/home_state.dart';
import '../viewmodels/bmi_viewmodel.dart';
import '../widgets/calorie_ring_widget.dart';
import '../widgets/bmi_card_widget.dart';
import '../widgets/today_roadmap_widget.dart';
import 'bmi_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.status == HomeStatus.loading && state.user == null
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(homeViewModelProvider);
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Greeting + streak
                      _buildGreeting(state),
                      const SizedBox(height: 20),

                      // 2. Calo hôm nay
                      CalorieRingWidget(
                        consumedKcal:   state.consumedKcal,
                        targetKcal:     state.targetKcal,
                        protein:        state.protein,
                        carbs:          state.carbs,
                        fat:            state.fat,
                        mealsCompleted: state.mealsCompleted,
                      ),
                      const SizedBox(height: 16),

                      // 3. BMI card (bấm được)
                      BmiCardWidget(
                        bmi:      state.bmi,
                        bmiLabel: state.bmiLabel,
                        onTap: () {
                          // Reset BmiViewModel để load fresh data
                          ref.invalidate(bmiViewModelProvider);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BmiDetailScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Lộ trình hôm nay (placeholder)
                      const TodayRoadmapWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(HomeState state) {
    final now      = DateTime.now();
    final dateStr  = DateFormat('EEEE, d MMMM', 'vi').format(now);
    final name     = state.user?.name ?? '';
    final streak   = state.user?.currentStreak ?? 0;

    // Lời chào theo thời gian
    String greeting;
    if (now.hour < 12) {
      greeting = 'Chào buổi sáng';
    } else if (now.hour < 18) {
      greeting = 'Chào buổi chiều';
    } else {
      greeting = 'Chào buổi tối';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ngày
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),

        // Greeting + tên + streak
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  children: [
                    TextSpan(text: '$greeting '),
                    TextSpan(text: name),
                    const TextSpan(text: '! 👋'),
                  ],
                ),
              ),
            ),

            // Streak badge
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDE0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak ngày',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}