import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import '../viewmodels/workout_view_model.dart';
import '../widgets/weekly_stats_card.dart';
import '../widgets/workout_card.dart';
import '../widgets/exercises_preview.dart';

class WorkoutScheduleScreen extends ConsumerStatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  ConsumerState<WorkoutScheduleScreen> createState() =>
      _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState
    extends ConsumerState<WorkoutScheduleScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialDay = ref.read(selectedDayProvider);
    _pageController = PageController(initialPage: initialDay);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);

    // Khi bấm ngày trên WeeklyStatsCard → cuộn PageView
    ref.listen(selectedDayProvider, (prev, next) {
      if (_pageController.hasClients && next != _pageController.page?.round()) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header cố định (không scroll theo) ──────────────────────
            const WeeklyStatsCard(),
            const SizedBox(height: 16),

            // ── PageView cho 7 ngày ──────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: 7,
                onPageChanged: (index) {
                  // Khi swipe tay → cập nhật provider
                  ref.read(selectedDayProvider.notifier).state = index;
                },
                itemBuilder: (context, index) {
                  return _DayPage(dayIndex: index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nội dung 1 ngày — scroll độc lập trong mỗi page
class _DayPage extends StatelessWidget {
  final int dayIndex;
  const _DayPage({required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkoutCard(dayIndex: dayIndex),
          const SizedBox(height: 24),
          ExercisesPreview(dayIndex: dayIndex),
        ],
      ),
    );
  }
}