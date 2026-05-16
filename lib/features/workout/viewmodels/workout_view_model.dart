// lib/features/workout/viewmodels/workout_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ── Models ────────────────────────────────────────────────────────────────────
class ExerciseItem {
  final String name;
  final String detail;
  final int calories;
  final String duration;
  final String emoji;

  const ExerciseItem({
    required this.name,
    required this.detail,
    required this.calories,
    required this.duration,
    required this.emoji,
  });
}

class DayWorkout {
  final String dayShort;
  final String emoji;
  final String type;
  final String title;
  final String description;
  final int minutes;
  final int calories;
  final List<ExerciseItem> exercises;
  final bool isRest;

  const DayWorkout({
    required this.dayShort,
    required this.emoji,
    required this.type,
    required this.title,
    required this.description,
    required this.minutes,
    required this.calories,
    required this.exercises,
    this.isRest = false,
  });
}

// ── Dữ liệu mẫu cho 7 ngày ───────────────────────────────────────────────────
final List<DayWorkout> weeklyWorkouts = [
  DayWorkout(
    dayShort: 'T2', emoji: '⚡', type: 'HIIT',
    title: 'Bùng nổ thứ Hai',
    description: 'Bài tập cường độ cao xen kẽ nghỉ ngắn, đốt calo nhanh và tăng sức bền tim mạch.',
    minutes: 30, calories: 310,
    exercises: [
      ExerciseItem(name: 'Nhảy Jumping Jacks', detail: '50 lần khởi động', calories: 15, duration: '2:00', emoji: '🤸'),
      ExerciseItem(name: 'Burpees', detail: '10 lần • 4 hiệp', calories: 80, duration: '5:00', emoji: '🔥'),
      ExerciseItem(name: 'Leo núi tại chỗ', detail: '30 giây • 4 hiệp', calories: 60, duration: '3:40', emoji: '🏔️'),
      ExerciseItem(name: 'Squat nhảy', detail: '15 lần • 3 hiệp', calories: 70, duration: '4:00', emoji: '💪'),
      ExerciseItem(name: 'Plank', detail: '45 giây • 3 hiệp', calories: 30, duration: '3:00', emoji: '🧘'),
      ExerciseItem(name: 'Chạy tại chỗ', detail: '1 phút • 3 hiệp', calories: 55, duration: '5:00', emoji: '🏃'),
    ],
  ),
  DayWorkout(
    dayShort: 'T3', emoji: '🧘', type: 'Yoga',
    title: 'Yoga phục hồi',
    description: 'Bài yoga nhẹ nhàng giúp kéo giãn cơ, cải thiện linh hoạt và giảm căng thẳng.',
    minutes: 40, calories: 180,
    exercises: [
      ExerciseItem(name: 'Tư thế mèo bò', detail: '10 lần • 2 hiệp', calories: 15, duration: '3:00', emoji: '🐱'),
      ExerciseItem(name: 'Chó úp mặt', detail: 'Giữ 30 giây • 3 lần', calories: 20, duration: '4:00', emoji: '🐕'),
      ExerciseItem(name: 'Tư thế chiến binh', detail: 'Giữ 45 giây mỗi bên', calories: 25, duration: '5:00', emoji: '⚔️'),
      ExerciseItem(name: 'Tư thế trẻ em', detail: 'Giữ 1 phút • 2 lần', calories: 10, duration: '3:00', emoji: '🧸'),
    ],
  ),
  DayWorkout(
    dayShort: 'T4', emoji: '🧗', type: 'Sức mạnh',
    title: 'Luyện sức mạnh',
    description: 'Tập trung vào các nhóm cơ lớn với tạ, xây dựng sức mạnh và tăng khối cơ.',
    minutes: 45, calories: 350,
    exercises: [
      ExerciseItem(name: 'Squat tạ', detail: '12 lần • 4 hiệp', calories: 80, duration: '6:00', emoji: '🏋️'),
      ExerciseItem(name: 'Đẩy ngực', detail: '10 lần • 4 hiệp', calories: 70, duration: '5:00', emoji: '💪'),
      ExerciseItem(name: 'Kéo lưng', detail: '10 lần • 3 hiệp', calories: 60, duration: '4:30', emoji: '🏗️'),
      ExerciseItem(name: 'Deadlift', detail: '8 lần • 3 hiệp', calories: 90, duration: '5:30', emoji: '⛏️'),
      ExerciseItem(name: 'Curl tay', detail: '12 lần • 3 hiệp', calories: 50, duration: '4:00', emoji: '💪'),
    ],
  ),
  DayWorkout(
    dayShort: 'T5', emoji: '🏃', type: 'Cardio',
    title: 'Cardio bền bỉ',
    description: 'Chạy bộ và bài cardio nhịp độ vừa, cải thiện sức bền tim mạch và đốt mỡ.',
    minutes: 35, calories: 280,
    exercises: [
      ExerciseItem(name: 'Khởi động chạy bộ', detail: '5 phút nhịp chậm', calories: 40, duration: '5:00', emoji: '🚶'),
      ExerciseItem(name: 'Chạy bộ vừa', detail: '15 phút nhịp vừa', calories: 150, duration: '15:00', emoji: '🏃'),
      ExerciseItem(name: 'Tăng tốc ngắn', detail: '30 giây x 5 lần', calories: 60, duration: '5:00', emoji: '⚡'),
      ExerciseItem(name: 'Thả lỏng', detail: '5 phút đi bộ', calories: 30, duration: '5:00', emoji: '🌿'),
    ],
  ),
  DayWorkout(
    dayShort: 'T6', emoji: '🤸', type: 'Toàn thân',
    title: 'Toàn thân thứ Sáu',
    description: 'Bài tập kết hợp toàn thân, tổng hợp sức mạnh và cardio để kết thúc tuần mạnh mẽ.',
    minutes: 40, calories: 320,
    exercises: [
      ExerciseItem(name: 'Chống đẩy', detail: '15 lần • 3 hiệp', calories: 50, duration: '4:00', emoji: '💪'),
      ExerciseItem(name: 'Squat tự do', detail: '20 lần • 3 hiệp', calories: 60, duration: '4:00', emoji: '🏋️'),
      ExerciseItem(name: 'Lunge', detail: '12 lần mỗi chân • 3 hiệp', calories: 55, duration: '5:00', emoji: '🚶'),
      ExerciseItem(name: 'Burpees nhẹ', detail: '8 lần • 3 hiệp', calories: 70, duration: '4:30', emoji: '🔥'),
      ExerciseItem(name: 'Plank bên', detail: '30 giây mỗi bên • 2 hiệp', calories: 25, duration: '3:00', emoji: '🧘'),
    ],
  ),
  DayWorkout(
    dayShort: 'T7', emoji: '🌅', type: 'Kéo giãn',
    title: 'Kéo giãn buổi sáng',
    description: 'Bài kéo giãn toàn thân nhẹ nhàng, chuẩn bị cơ thể cho một ngày năng động.',
    minutes: 20, calories: 80,
    exercises: [
      ExerciseItem(name: 'Kéo cổ vai', detail: 'Giữ 30 giây mỗi bên', calories: 10, duration: '3:00', emoji: '🌿'),
      ExerciseItem(name: 'Kéo lưng dưới', detail: 'Giữ 45 giây x 2', calories: 15, duration: '3:00', emoji: '🧘'),
      ExerciseItem(name: 'Kéo đùi trước', detail: 'Giữ 30 giây mỗi chân', calories: 10, duration: '2:00', emoji: '🦵'),
      ExerciseItem(name: 'Hít thở sâu', detail: '10 nhịp thở bụng', calories: 5, duration: '3:00', emoji: '🌬️'),
    ],
  ),
  DayWorkout(
    dayShort: 'CN', emoji: '😴', type: 'Nghỉ ngơi',
    title: 'Phục hồi Chủ Nhật',
    description: 'Nghỉ ngơi là lúc cơ thể bạn mạnh hơn. Vận động nhẹ và kéo giãn để hỗ trợ phục hồi và chuẩn bị cho tuần mới.',
    minutes: 20, calories: 80,
    isRest: true,
    exercises: [
      ExerciseItem(name: 'Kéo giãn toàn thân', detail: '30 giây mỗi động tác', calories: 20, duration: '5:00', emoji: '🧘'),
      ExerciseItem(name: 'Lăn cơ bằng foam', detail: '10 lần chậm mỗi vùng', calories: 20, duration: '5:00', emoji: '🔵'),
      ExerciseItem(name: 'Đi bộ chánh niệm', detail: '10 phút thư giãn', calories: 40, duration: '10:00', emoji: '🌿'),
    ],
  ),
];

// ── Providers ─────────────────────────────────────────────────────────────────
// Ngày đang chọn (0 = T2 ... 6 = CN)
final selectedDayProvider = StateProvider<int>((ref) {
  // Mặc định chọn ngày hôm nay
  final weekday = DateTime.now().weekday - 1; // 0=T2...6=CN
  return weekday.clamp(0, 6);
});

// Buổi tập của ngày đang chọn
final currentWorkoutProvider = Provider<DayWorkout>((ref) {
  final index = ref.watch(selectedDayProvider);
  return weeklyWorkouts[index];
});

// Tổng thống kê tuần
final weeklyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final totalMinutes = weeklyWorkouts
      .where((d) => !d.isRest)
      .fold(0, (sum, d) => sum + d.minutes);
  final totalCalories = weeklyWorkouts
      .where((d) => !d.isRest)
      .fold(0, (sum, d) => sum + d.calories);
  return {
    'minutes': totalMinutes,
    'calories': totalCalories,
    'done': 0,
    'total': 7,
  };
});