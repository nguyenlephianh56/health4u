import 'package:flutter/material.dart';
import 'package:health4u/core/constants/app_colors.dart';
import '../widgets/weekly_stats_card.dart';
import '../widgets/workout_card.dart';
import '../widgets/exercises_preview.dart';

class WorkoutScheduleScreen extends StatelessWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WeeklyStatsCard tràn viền 2 bên, không padding ngang
              const WeeklyStatsCard(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    WorkoutCard(),
                    SizedBox(height: 24),
                    ExercisesPreview(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}