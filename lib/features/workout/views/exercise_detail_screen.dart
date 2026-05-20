// lib/features/workout/views/exercise_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/data/repositories/health_repo.dart';
import '../viewmodels/workout_view_model.dart';

// ── Providers ──────────────────────────────────────────────────────────────────
final _workoutDoneProvider =
StateProvider.family<bool, String>((ref, id) => false);

// ── Timer ──────────────────────────────────────────────────────────────────────
class TimerState {
  final int remaining;
  final int total;
  final bool isRunning;

  const TimerState({
    required this.remaining,
    required this.total,
    required this.isRunning,
  });

  TimerState copyWith({int? remaining, int? total, bool? isRunning}) =>
      TimerState(
        remaining: remaining ?? this.remaining,
        total: total ?? this.total,
        isRunning: isRunning ?? this.isRunning,
      );

  String get formatted {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get progress => total > 0 ? 1 - (remaining / total) : 0;
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;

  TimerNotifier(int totalSeconds)
      : super(TimerState(
    remaining: totalSeconds,
    total: totalSeconds,
    isRunning: false,
  ));

  void toggle() {
    if (state.isRunning) {
      _ticker?.cancel();
      state = state.copyWith(isRunning: false);
    } else {
      state = state.copyWith(isRunning: true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.remaining <= 0) {
          _ticker?.cancel();
          state = state.copyWith(isRunning: false);
        } else {
          state = state.copyWith(remaining: state.remaining - 1);
        }
      });
    }
  }

  void reset(int totalSeconds) {
    _ticker?.cancel();
    state = TimerState(
        remaining: totalSeconds, total: totalSeconds, isRunning: false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final _timerProvider =
StateNotifierProvider.family<TimerNotifier, TimerState, int>(
      (ref, seconds) => TimerNotifier(seconds),
);

// ── Main Screen ────────────────────────────────────────────────────────────────
class ExerciseDetailScreen extends ConsumerWidget {
  final PlanWorkout workout;
  final String date;
  final String dayOfWeek;
  final String docId;       // Firestore doc ID để mark completed

  const ExerciseDetailScreen({
    super.key,
    required this.workout,
    required this.date,
    required this.dayOfWeek,
    required this.docId,
  });

  int get _totalSeconds => workout.durationMin * 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = ref.watch(_workoutDoneProvider(workout.workoutId));
    final timer  = ref.watch(_timerProvider(_totalSeconds));

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Banner(workout: workout, dayOfWeek: dayOfWeek, date: date),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimerCard(
                    workout: workout,
                    timer: timer,
                    totalSeconds: _totalSeconds,
                  ),
                  const SizedBox(height: 16),
                  _CompleteButton(
                    workout: workout,
                    isDone: isDone,
                    docId: docId,
                  ),
                  const SizedBox(height: 16),
                  _WorkoutInfoCard(workout: workout),
                  const SizedBox(height: 20),
                  _ExerciseListSection(workoutId: workout.workoutId),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section danh sách bài tập nhỏ ────────────────────────────────────────────
class _ExerciseListSection extends ConsumerWidget {
  final String workoutId;
  const _ExerciseListSection({required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWorkout = ref.watch(workoutDetailProvider(workoutId));

    return asyncWorkout.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (workoutDetail) {
        if (workoutDetail == null || workoutDetail.exercises.isEmpty) {
          return const SizedBox.shrink();
        }

        final exercises = workoutDetail.exercises;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tiêu đề section ──────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Các bài tập',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${exercises.length} bài',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Danh sách card bài tập nhỏ ───────────────────────────────────
            ...exercises.asMap().entries.map((entry) {
              final index   = entry.key;
              final exercise = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(exercise: exercise, index: index + 1),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Card bài tập nhỏ ─────────────────────────────────────────────────────────
class _ExerciseCard extends StatefulWidget {
  final dynamic exercise; // ExerciseItem
  final int index;
  const _ExerciseCard({required this.exercise, required this.index});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // ── Header (luôn hiển thị) ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Số thứ tự
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tên bài tập
                  Expanded(
                    child: Text(
                      ex.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),

                  // Thông số nhanh: sets x reps
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${ex.sets} x ${ex.reps}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mũi tên expand
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Chi tiết (chỉ hiển thị khi expanded) ─────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ExerciseDetail(exercise: ex),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ── Chi tiết bài tập nhỏ (khi mở rộng) ──────────────────────────────────────
class _ExerciseDetail extends StatelessWidget {
  final dynamic exercise; // ExerciseItem
  const _ExerciseDetail({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final ex = exercise;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: AppColors.text.withOpacity(0.07),
          ),
          const SizedBox(height: 14),

          // Ảnh minh họa (nếu có)
          if (ex.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ex.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Thông số: sets / reps / nghỉ
          Row(
            children: [
              _StatChip(label: 'Hiệp', value: '${ex.sets}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Reps', value: '${ex.reps}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Nghỉ', value: '${ex.restSec}s'),
            ],
          ),

          // Hướng dẫn (nếu có)
          if (ex.instruction.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Hướng dẫn',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ex.instruction,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text.withOpacity(0.75),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Chip thống số nhỏ (Hiệp / Reps / Nghỉ) ───────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner ─────────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final PlanWorkout workout;
  final String dayOfWeek;
  final String date;
  const _Banner({
    required this.workout,
    required this.dayOfWeek,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 36,
            child: Opacity(
              opacity: 0.2,
              child: Text(
                workout.emoji,
                style: const TextStyle(fontSize: 120),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xDD000000), Colors.transparent],
                stops: [0.0, 0.6],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _BannerTag(
                        label: workout.category,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _BannerTag(
                        label: workout.difficultyVi,
                        color: _difficultyColor(workout.difficulty),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workout.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text('${workout.durationMin} phút',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 14),
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('${workout.caloriesBurned} cal',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 14),
                      const Text('💪', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(workout.muscleGroup,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Advanced':
        return const Color(0xFFE74C3C);
      case 'Intermediate':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF2ECC71);
    }
  }
}

class _BannerTag extends StatelessWidget {
  final String label;
  final Color color;
  const _BannerTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Timer Card ─────────────────────────────────────────────────────────────────
class _TimerCard extends ConsumerWidget {
  final PlanWorkout workout;
  final TimerState timer;
  final int totalSeconds;

  const _TimerCard({
    required this.workout,
    required this.timer,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đếm giờ tập',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  workout.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: timer.progress,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              timer.formatted,
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w800,
                color: AppColors.text.withOpacity(0.85),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${workout.durationMin} phút • ${workout.muscleGroup}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(_timerProvider(totalSeconds).notifier).toggle(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    timer.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => ref
                    .read(_timerProvider(totalSeconds).notifier)
                    .reset(totalSeconds),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.replay,
                      size: 24, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nút hoàn thành ─────────────────────────────────────────────────────────────
class _CompleteButton extends ConsumerWidget {
  final PlanWorkout workout;
  final bool isDone;
  final String docId;
  const _CompleteButton({
    required this.workout,
    required this.isDone,
    required this.docId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isDone
            ? null
            : () async {
          // 1. Cập nhật local state ngay lập tức
          ref
              .read(_workoutDoneProvider(workout.workoutId).notifier)
              .state = true;

          // 2. Ghi is_completed = true lên Firestore
          await ref
              .read(healthRepoProvider)
              .markDayCompleted(docId);

          // 3. Invalidate để stats header tự rebuild
          ref.invalidate(userPlanDaysProvider);

          // 4. Cộng điểm
          if (context.mounted) {
            await _addPoints(context, points: 20);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isDone ? const Color(0xFFD4ECFF) : AppColors.primary,
          disabledBackgroundColor: const Color(0xFFD4ECFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? Icons.check_circle_outline : Icons.emoji_events,
              color: isDone ? AppColors.primary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isDone
                  ? '✓  Đã hoàn thành! (+20 điểm)'
                  : '🏆  Đánh dấu hoàn thành (+20 điểm)',
              style: TextStyle(
                color: isDone ? AppColors.primary : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPoints(BuildContext context, {required int points}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'total_points': FieldValue.increment(points)});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Bạn vừa nhận được +$points điểm!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }
}

// ── Thông tin chi tiết workout ─────────────────────────────────────────────────
class _WorkoutInfoCard extends StatelessWidget {
  final PlanWorkout workout;
  const _WorkoutInfoCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _Row('💪', 'Nhóm cơ', workout.muscleGroup),
      _Row('🏷️', 'Thể loại', workout.category),
      _Row('📊', 'Độ khó', workout.difficultyVi),
      _Row('⏱️', 'Thời gian', '${workout.durationMin} phút'),
      _Row('🔥', 'Calo đốt cháy', '${workout.caloriesBurned} cal'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Thông tin bài tập',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Text(e.value.icon,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(
                        e.value.label,
                        style: TextStyle(
                          color: AppColors.text.withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        e.value.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.text.withOpacity(0.07),
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Row {
  final String icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);
}