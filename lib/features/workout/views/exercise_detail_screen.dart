import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';                         // import GoRouter
import 'package:health4u/features/workout/viewmodels/workout_provider.dart'; // import provider

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStarted = ref.watch(workoutStartedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isStarted ? 'Workout in progress' : 'Not started'),
            ElevatedButton(
              onPressed: () => context.pop(),     // pop từ GoRouter
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}