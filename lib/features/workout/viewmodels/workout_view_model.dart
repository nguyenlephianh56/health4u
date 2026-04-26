import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- Cấu trúc dữ liệu ---
class Exercise {
  final String name;
  final String durationOrReps;
  final int calories;
  Exercise(this.name, this.durationOrReps, this.calories);
}

class WorkoutInfo {
  final String title;
  final String tag;
  final int totalTime;
  final int totalCalories;
  final String description;
  final List<Exercise> exercises;

  WorkoutInfo({
    required this.title,
    required this.tag,
    required this.totalTime,
    required this.totalCalories,
    required this.description,
    required this.exercises,
  });
}
// --- Riverpod Providers ---
// Lưu trạng thái ngày đang chọn (0 = T2, 1 = T3, ...)
final selectedDayProvider = StateProvider<int>((ref) => 0);
// Dữ liệu chi tiết bài tập theo ngày (Đã dịch tiếng Việt)
final workoutProvider = Provider<WorkoutInfo>((ref) {
  return WorkoutInfo(
    title: 'Bài tập HIIT Thứ 2',
    tag: 'HIIT',
    totalTime: 30,
    totalCalories: 320,
    description: 'Bài tập cường độ cao giúp đốt cháy calo nhanh chóng. Luân phiên giữa nỗ lực tối đa và phục hồi.',
    exercises: [
      Exercise('Nhảy dang tay khởi động', '50 lần', 15),
      Exercise('Burpees', '50 lần', 80),
      Exercise('Leo núi tại chỗ', '30 giây x 4 hiệp', 60),
    ],
  );
});