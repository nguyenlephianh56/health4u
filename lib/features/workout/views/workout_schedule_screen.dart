import 'package:flutter/material.dart';
import 'package:health4u/core/constants/app_colors.dart';
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
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WorkoutCard(),                     // Đã có sẵn thanh ngày bên trong
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: ExercisesPreview(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}