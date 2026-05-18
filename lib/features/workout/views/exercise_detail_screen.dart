// lib/features/workout/views/exercise_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health4u/core/constants/app_colors.dart';
import '../viewmodels/workout_view_model.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final _activeExerciseProvider =
StateProvider.family<int, String>((ref, id) => 0);

final _expandedExerciseProvider =
StateProvider.family<int?, String>((ref, id) => null);

final _workoutDoneProvider =
StateProvider.family<bool, String>((ref, id) => false);

// ── Firebase: chi tiết bài tập ────────────────────────────────────────────────
//
// Firestore structure:
//   exercises/{exerciseName}/
//     description : String   — hướng dẫn thực hiện
//     tags        : List<String> — nhóm cơ / phân loại
//     gifUrl      : String?  — link GIF (tuỳ chọn sau này)
//
// Nếu document chưa tồn tại → trả về null → UI hiển thị fallback

class ExerciseDetail {
  final String description;
  final List<String> tags;
  final String? gifUrl;

  const ExerciseDetail({
    required this.description,
    required this.tags,
    this.gifUrl,
  });

  factory ExerciseDetail.fromFirestore(Map<String, dynamic> data) =>
      ExerciseDetail(
        description: data['description'] as String? ?? '',
        tags: List<String>.from(data['tags'] as List? ?? []),
        gifUrl: data['gifUrl'] as String?,
      );
}

/// Key = tên bài tập (ex.name)
final exerciseDetailProvider =
FutureProvider.family<ExerciseDetail?, String>((ref, name) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('exercises')
        .doc(name)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return ExerciseDetail.fromFirestore(doc.data()!);
  } catch (_) {
    return null;
  }
});

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

  double get progress =>
      total > 0 ? 1 - (remaining / total) : 0;
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;

  TimerNotifier(int totalSeconds)
      : super(TimerState(
      remaining: totalSeconds,
      total: totalSeconds,
      isRunning: false));

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

// key = giây ban đầu của bài tập
final _timerProvider = StateNotifierProvider.family<TimerNotifier, TimerState, int>(
      (ref, seconds) => TimerNotifier(seconds),
);

// ── Helper: parse "2:00" → giây ───────────────────────────────────────────────
int _parseDuration(String dur) {
  final parts = dur.split(':');
  if (parts.length == 2) {
    final m = int.tryParse(parts[0]) ?? 0;
    final s = int.tryParse(parts[1]) ?? 0;
    return m * 60 + s;
  }
  return 60;
}

// ── Nhóm cơ theo loại ─────────────────────────────────────────────────────────
List<String> _muscleGroups(DayWorkout w) {
  switch (w.type) {
    case 'HIIT':       return ['Toàn thân', 'Tim mạch', 'Cơ đùi', 'Cơ lõi'];
    case 'Yoga':       return ['Linh hoạt', 'Cơ lõi', 'Cân bằng', 'Thư giãn'];
    case 'Sức mạnh':  return ['Cơ ngực', 'Cơ lưng', 'Cơ đùi', 'Cơ tay'];
    case 'Cardio':     return ['Tim mạch', 'Cơ chân', 'Sức bền'];
    case 'Toàn thân': return ['Toàn thân', 'Sức mạnh', 'Tim mạch'];
    case 'Kéo giãn':  return ['Linh hoạt', 'Phục hồi', 'Cơ lưng'];
    case 'Nghỉ ngơi': return ['Toàn thân', 'Linh hoạt', 'Phục hồi', 'Tinh thần'];
    default:           return ['Toàn thân'];
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────────
class ExerciseDetailScreen extends ConsumerWidget {
  final DayWorkout workout;
  const ExerciseDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone      = ref.watch(_workoutDoneProvider(workout.title));
    final activeIndex = ref.watch(_activeExerciseProvider(workout.title));
    final activeEx    = workout.exercises[activeIndex];
    final timerSecs   = _parseDuration(activeEx.duration);
    final timer       = ref.watch(_timerProvider(timerSecs));

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Banner(workout: workout),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimerCard(
                    workout: workout,
                    activeIndex: activeIndex,
                    activeEx: activeEx,
                    timer: timer,
                    timerSecs: timerSecs,
                  ),
                  const SizedBox(height: 16),
                  _CompleteButton(workout: workout, isDone: isDone),
                  const SizedBox(height: 16),
                  _MuscleGroupsCard(workout: workout),
                  const SizedBox(height: 16),
                  _ExerciseAccordion(
                      workout: workout, activeIndex: activeIndex),
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

// ── Banner ─────────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final DayWorkout workout;
  const _Banner({required this.workout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: workout.isRest
                    ? [const Color(0xFF5B8DEF), const Color(0xFF3A6FD8)]
                    : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 36,
            child: Opacity(
              opacity: 0.2,
              child: Text(workout.emoji,
                  style: const TextStyle(fontSize: 120)),
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: workout.isRest
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      workout.isRest ? 'Nghỉ ngơi' : workout.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
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
                      Text('${workout.minutes} phút',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 14),
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('${workout.calories} calo đốt',
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
}

// ── Timer Card ─────────────────────────────────────────────────────────────────
class _TimerCard extends ConsumerWidget {
  final DayWorkout workout;
  final int activeIndex;
  final ExerciseItem activeEx;
  final TimerState timer;
  final int timerSecs;

  const _TimerCard({
    required this.workout,
    required this.activeIndex,
    required this.activeEx,
    required this.timer,
    required this.timerSecs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = workout.exercises.length;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bài ${activeIndex + 1}/$total',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(activeEx.emoji,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      activeEx.name,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: timer.progress,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 22),

          // Timer
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
              activeEx.detail,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(_timerProvider(timerSecs).notifier).toggle(),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.text.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    timer.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 30,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final next = activeIndex + 1;
                  if (next < total) {
                    ref
                        .read(_activeExerciseProvider(workout.title)
                        .notifier)
                        .state = next;
                    final nextSecs = _parseDuration(
                        workout.exercises[next].duration);
                    ref
                        .read(_timerProvider(nextSecs).notifier)
                        .reset(nextSecs);
                  }
                },
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.skip_next,
                      size: 26, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // GIF placeholder
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(activeEx.emoji,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(
                  'Animation / GIF placeholder',
                  style: TextStyle(
                    color: AppColors.text.withOpacity(0.4),
                    fontSize: 12,
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

// ── Nút hoàn thành ─────────────────────────────────────────────────────────────
class _CompleteButton extends ConsumerWidget {
  final DayWorkout workout;
  final bool isDone;
  const _CompleteButton({required this.workout, required this.isDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isDone
            ? null
            : () async {
          ref
              .read(_workoutDoneProvider(workout.title).notifier)
              .state = true;
          await _addPoints(context, points: 20);
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

  Future<void> _addPoints(BuildContext context,
      {required int points}) async {
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

// ── Nhóm cơ ───────────────────────────────────────────────────────────────────
class _MuscleGroupsCard extends StatelessWidget {
  final DayWorkout workout;
  const _MuscleGroupsCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final groups = _muscleGroups(workout);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          const Text(
            'Nhóm cơ được tập',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: groups
                .map(
                  (g) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text.withOpacity(0.75),
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Accordion danh sách bài tập ────────────────────────────────────────────────
class _ExerciseAccordion extends ConsumerWidget {
  final DayWorkout workout;
  final int activeIndex;

  const _ExerciseAccordion({
    required this.workout,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex =
    ref.watch(_expandedExerciseProvider(workout.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tất cả bài tập',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        ...workout.exercises.asMap().entries.map((entry) {
          final i        = entry.key;
          final ex       = entry.value;
          final isExpanded = expandedIndex == i;
          final isActive   = i == activeIndex;

          return GestureDetector(
            onTap: () {
              ref
                  .read(_expandedExerciseProvider(workout.title)
                  .notifier)
                  .state = isExpanded ? null : i;
              ref
                  .read(_activeExerciseProvider(workout.title)
                  .notifier)
                  .state = i;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isActive
                    ? Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withOpacity(0.12)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(ex.emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${ex.detail} · 🔥 ${ex.calories} calo',
                                style: TextStyle(
                                  color: AppColors.text.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded)
                    _ExerciseExpandedContent(exercise: ex),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Expanded content với Firebase ─────────────────────────────────────────────
class _ExerciseExpandedContent extends ConsumerWidget {
  final ExerciseItem exercise;
  const _ExerciseExpandedContent({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(exerciseDetailProvider(exercise.name));

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── GIF / Animation placeholder ──────────────────────────────
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: asyncDetail.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => _GifPlaceholder(exercise: exercise),
              data: (detail) {
                // Sau này: nếu detail?.gifUrl != null → hiển thị Image.network
                return _GifPlaceholder(exercise: exercise);
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Mô tả từ Firebase ─────────────────────────────────────────
          asyncDetail.when(
            loading: () => Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            error: (_, __) => _DescriptionText(
              text: 'Đang phát triển — mô tả chi tiết sẽ được cập nhật sớm.',
              isPlaceholder: true,
            ),
            data: (detail) {
              final desc = detail?.description ?? '';
              return _DescriptionText(
                text: desc.isEmpty
                    ? 'Đang phát triển — mô tả chi tiết sẽ được cập nhật sớm.'
                    : desc,
                isPlaceholder: desc.isEmpty,
              );
            },
          ),
          const SizedBox(height: 10),

          // ── Tags: time + cal luôn có, tags Firebase nếu có ───────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ExTag('⏱ ${exercise.duration}'),
              _ExTag('🔥 ${exercise.calories} calo'),
              ...asyncDetail.when(
                loading: () => <Widget>[],
                error: (_, __) => <Widget>[],
                data: (detail) => (detail?.tags ?? [])
                    .map((t) => _ExTag(t))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GifPlaceholder extends StatelessWidget {
  final ExerciseItem exercise;
  const _GifPlaceholder({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(exercise.emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(height: 4),
        Text(
          'Animation / GIF placeholder',
          style: TextStyle(
            color: AppColors.text.withOpacity(0.35),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DescriptionText extends StatelessWidget {
  final String text;
  final bool isPlaceholder;
  const _DescriptionText({required this.text, this.isPlaceholder = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.55,
        color: isPlaceholder
            ? AppColors.text.withOpacity(0.4)
            : AppColors.text.withOpacity(0.75),
        fontStyle:
        isPlaceholder ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}

class _ExTag extends StatelessWidget {
  final String label;
  const _ExTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.text.withOpacity(0.7),
        ),
      ),
    );
  }
}