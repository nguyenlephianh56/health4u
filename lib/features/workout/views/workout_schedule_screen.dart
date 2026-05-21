// lib/features/workout/views/workout_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/core/constants/app_colors.dart';
import 'package:health4u/data/repositories/health_repo.dart';
import '../viewmodels/workout_view_model.dart';
import 'exercise_detail_screen.dart';

class WorkoutScheduleScreen extends ConsumerStatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  ConsumerState<WorkoutScheduleScreen> createState() =>
      _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState
    extends ConsumerState<WorkoutScheduleScreen> {
  bool _autoSelectedToday = false;

  @override
  Widget build(BuildContext context) {
    final asyncPlan = ref.watch(userPlanDaysProvider);
    final selectedIdx = ref.watch(selectedDayIndexProvider);

    // Tự động chọn ngày hôm nay 1 lần duy nhất khi data load xong
    ref.listen<AsyncValue<List<UserPlanDay>>>(userPlanDaysProvider, (_, next) {
      if (_autoSelectedToday) return;
      next.whenData((days) {
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
        final idx = days.indexWhere((d) => d.date == todayStr);
        if (idx >= 0) {
          ref.read(selectedDayIndexProvider.notifier).state = idx;
        }
        _autoSelectedToday = true;
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncPlan.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Không thể tải kế hoạch\n$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userPlanDaysProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có kế hoạch tập luyện.\nHãy tạo kế hoạch mới!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final day = days[selectedIdx.clamp(0, days.length - 1)];

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _WeeklyHeader(days: days),
              ),
              if (day.hasWorkout)
                _WorkoutDaySliver(day: day, workout: day.workout!)
              else
                _RestDaySliver(day: day),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header xanh: tiêu đề + 3 stat + hàng chọn ngày (compact, scroll cùng trang)
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklyHeader extends ConsumerWidget {
  final List<UserPlanDay> days;
  const _WeeklyHeader({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = ref.watch(selectedDayIndexProvider);
    final statsAsync  = ref.watch(planWeeklyStatsProvider);
    final selectedDay = days[selectedIdx.clamp(0, days.length - 1)];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tiêu đề + ngày hôm nay real-time ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch Tập Tuần',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Lịch tập luyện cá nhân của bạn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Badge ngày đang chọn — cập nhật theo lịch
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedDayLabel(selectedDay.date, selectedDay.dayShortLabel),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 3 ô thống kê (compact) ────────────────────────────────
              statsAsync.when(
                loading: () => const SizedBox(height: 52),
                error:   (_, __) => const SizedBox(height: 52),
                data: (stats) => Row(
                  children: [
                    _StatBox(icon: '⏱️', value: '${stats['minutes']}p',
                        label: 'Thời gian'),
                    const SizedBox(width: 8),
                    _StatBox(icon: '🔥', value: '${stats['calories']}',
                        label: 'Calo'),
                    const SizedBox(width: 8),
                    _StatBox(
                        icon: '📅',
                        value: '${stats['streak']}/${stats['total']}',
                        label: 'Ngày/tuần'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Hàng chọn ngày: container nền tối nổi lên ─────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: List.generate(days.length, (i) {
                    final day        = days[i];
                    final isSelected = i == selectedIdx;
                    final isToday    = _isToday(day.date);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                        ref.read(selectedDayIndexProvider.notifier).state = i,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isToday && !isSelected
                                ? Border.all(
                                color: Colors.white,
                                width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Thứ (T2, T3, … CN)
                              Text(
                                day.dayShortLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Số ngày trong tháng
                              Text(
                                _dayNum(day.date),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              ),
                              // Dot hôm nay
                              if (isToday) ...[
                                const SizedBox(height: 3),
                                CircleAvatar(
                                  radius: 2.5,
                                  backgroundColor: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ), // Container
            ],
          ),
        ),
      ),
    );
  }

  /// "Thứ Tư, 20/05" — theo ngày đang chọn trên lịch
  String _selectedDayLabel(String date, String shortLabel) {
    const fullDay = {
      'T2': 'Thứ Hai', 'T3': 'Thứ Ba',  'T4': 'Thứ Tư',
      'T5': 'Thứ Năm', 'T6': 'Thứ Sáu', 'T7': 'Thứ Bảy', 'CN': 'Chủ Nhật',
    };
    try {
      final p  = date.split('-');
      final wd = fullDay[shortLabel] ?? shortLabel;
      return '$wd, ${p[2]}/${p[1]}';
    } catch (_) {
      return shortLabel;
    }
  }

  String _dayNum(String date) {
    try { return date.split('-')[2]; } catch (_) { return ''; }
  }

  bool _isToday(String date) {
    try {
      final now = DateTime.now();
      final s = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      return date == s;
    } catch (_) { return false; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ô thống kê nhỏ
// ─────────────────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatBox({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ngày nghỉ
// ─────────────────────────────────────────────────────────────────────────────
class _RestDaySliver extends StatelessWidget {
  final UserPlanDay day;
  const _RestDaySliver({required this.day});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😴', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Ngày nghỉ ngơi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thư giãn và phục hồi sức lực!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ngày có workout: card ảnh + exercises list + nút bắt đầu (ảnh 1 + 2)
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutDaySliver extends ConsumerWidget {
  final UserPlanDay day;
  final PlanWorkout workout;
  const _WorkoutDaySliver({required this.day, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch workout đầy đủ kèm exercises
    final asyncDetail = ref.watch(workoutDetailProvider(workout.workoutId));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Card banner (ảnh 1 - phần dưới) ──────────────────────────
          _WorkoutBannerCard(workout: workout),
          const SizedBox(height: 20),

          // ── Exercises Preview (ảnh 2) ─────────────────────────────────
          asyncDetail.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (detail) {
              if (detail == null || detail.exercises.isEmpty) {
                return const SizedBox.shrink();
              }
              return _ExercisesSection(
                workout: workout,
                exercises: detail.exercises,
                day: day,
              );
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card banner workout (ảnh 1 - phần thẻ dưới header)
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutBannerCard extends StatelessWidget {
  final PlanWorkout workout;
  const _WorkoutBannerCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Nền gradient tối
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
              ),
            ),
            // Emoji lớn mờ
            Positioned(
              right: 20,
              bottom: 16,
              child: Opacity(
                opacity: 0.25,
                child: Text(
                  workout.emoji,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            ),
            // Gradient che phía dưới
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                    stops: [0.0, 0.55],
                  ),
                ),
              ),
            ),
            // Nội dung chữ
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Row(
                children: [
                  _Tag(label: workout.category, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  _Tag(
                    label: workout.difficultyVi,
                    color: _difficultyColor(workout.difficulty),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Advanced':     return const Color(0xFFE74C3C);
      case 'Intermediate': return const Color(0xFFF39C12);
      default:             return const Color(0xFF2ECC71);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section exercises preview (ảnh 2): tiêu đề + list + nút bắt đầu
// ─────────────────────────────────────────────────────────────────────────────
class _ExercisesSection extends StatelessWidget {
  final PlanWorkout workout;
  final List<dynamic> exercises; // List<ExerciseItem>
  final UserPlanDay day;

  const _ExercisesSection({
    required this.workout,
    required this.exercises,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xem trước bài tập',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),

        // List bài tập nhỏ
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: exercises.asMap().entries.map((entry) {
              final isLast = entry.key == exercises.length - 1;
              return _ExercisePreviewRow(
                exercise: entry.value,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Nút bắt đầu (ảnh 2 - dưới cùng)
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(
                    workout:   workout,
                    date:      day.date,
                    dayOfWeek: day.dayOfWeek,
                    docId:     day.docId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              '🏅 Bắt đầu ${workout.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hàng bài tập nhỏ trong preview (ảnh 2)
// ─────────────────────────────────────────────────────────────────────────────
class _ExercisePreviewRow extends StatelessWidget {
  final dynamic exercise; // ExerciseItem
  final bool isLast;
  const _ExercisePreviewRow({required this.exercise, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final ex = exercise;

    // Icon avatar nền hồng nhạt
    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _exerciseEmoji(ex.name as String),
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subLabel(ex),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Calo + thời gian nghỉ
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Text(
                        '${(ex.reps as int) * (ex.sets as int)} cal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        _formatRest(ex.restSec as int),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 14,
            color: AppColors.text.withOpacity(0.07),
          ),
      ],
    );
  }

  String _subLabel(dynamic ex) {
    final reps = ex.reps as int;
    final sets = ex.sets as int;
    if (sets > 1) return '$reps reps × $sets hiệp';
    return '$reps reps';
  }

  String _formatRest(int sec) {
    if (sec >= 60) return '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
    return '0:${sec.toString().padLeft(2, '0')}';
  }

  String _exerciseEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('squat'))   return '🦵';
    if (n.contains('push'))    return '💪';
    if (n.contains('pull'))    return '🏋️';
    if (n.contains('run') || n.contains('cardio')) return '🏃';
    if (n.contains('plank'))   return '🧘';
    if (n.contains('jump'))    return '⚡';
    if (n.contains('stretch') || n.contains('cool')) return '🧘';
    if (n.contains('lưng') || n.contains('back'))    return '🔙';
    if (n.contains('ngực') || n.contains('chest'))   return '💪';
    return '🏅';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag nhỏ
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

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