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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Workout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your personalized training schedule',
                style: TextStyle(color: AppColors.text.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),
              const WeeklyStatsCard(),
              const SizedBox(height: 24),
              const WorkoutCard(),
              const SizedBox(height: 24),
              const ExercisesPreview(),
            ],
          ),
        ),
      ),
    );
  }
}