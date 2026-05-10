import 'package:flutter_riverpod/flutter_riverpod.dart';

// Trạng thái: đã bắt đầu buổi tập chưa?
final workoutStartedProvider = StateProvider<bool>((ref) => false);

// Chỉ số bài tập đang được chọn (nếu cần highlight hoặc chuyển màn hình)
final selectedExerciseIndexProvider = StateProvider<int?>((ref) => null);