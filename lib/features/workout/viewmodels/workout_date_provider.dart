import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider ngày được chọn
final selectedWorkoutDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Dữ liệu bài tập cho từng thứ (1 = Mon, 7 = Sun)
final Map<int, List<Map<String, String>>> weeklyWorkoutMock = {
  DateTime.monday: [
    {'name': 'Jumping Jacks Warm-Up', 'detail': '50 reps', 'cal': '15 cal', 'time': '2:00'},
    {'name': 'Burpees', 'detail': '10 reps × 4 sets', 'cal': '80 cal', 'time': '1:00'},
    {'name': 'Mountain Climbers', 'detail': '30 secs × 4 sets', 'cal': '60 cal', 'time': '0:40'},
    {'name': 'Jump Squats', 'detail': '15 reps × 3 sets', 'cal': '70 cal', 'time': '0:45'},
    {'name': 'High Knees', 'detail': '30 secs × 4 sets', 'cal': '50 cal', 'time': '0:30'},
    {'name': 'Cool-Down Stretch', 'detail': '5 mins', 'cal': '15 cal', 'time': '5:00'},
  ],
  DateTime.tuesday: [
    {'name': 'Push-Ups', 'detail': '15 reps × 4 sets', 'cal': '60 cal', 'time': '1:00'},
    {'name': 'Dumbbell Rows', 'detail': '12 reps each side × 3 sets', 'cal': '50 cal', 'time': '1:00'},
    {'name': 'Overhead Press', 'detail': '12 reps × 3 sets', 'cal': '50 cal', 'time': '1:00'},
    {'name': 'Tricep Dips', 'detail': '15 reps × 3 sets', 'cal': '40 cal', 'time': '0:45'},
    {'name': 'Bicep Curls', 'detail': '14 reps × 3 sets', 'cal': '35 cal', 'time': '0:45'},
  ],
  DateTime.wednesday: [
    {'name': 'Sun Salutation A', 'detail': '5 rounds', 'cal': '40 cal', 'time': '5:00'},
    {'name': 'Warrior I & II Flow', 'detail': '5 breaths each side × 2 sets', 'cal': '30 cal', 'time': '3:00'},
    {'name': 'Triangle Pose', 'detail': '5 breaths each side × 2 sets', 'cal': '20 cal', 'time': '2:00'},
    {'name': 'Tree Pose', 'detail': '30 secs each side × 2 sets', 'cal': '15 cal', 'time': '2:00'},
    {'name': 'Seated Forward Fold', 'detail': '10 breaths × 2 sets', 'cal': '10 cal', 'time': '3:00'},
    {'name': 'Savasana', 'detail': '5 mins', 'cal': '5 cal', 'time': '5:00'},
  ],
  DateTime.thursday: [
    {'name': 'Brisk Walk Warm-Up', 'detail': '5 mins', 'cal': '30 cal', 'time': '5:00'},
    {'name': 'Steady Jog', 'detail': '20 mins', 'cal': '180 cal', 'time': '20:00'},
    {'name': 'Sprint Intervals', 'detail': '30s sprint / 30s walk × 5', 'cal': '60 cal', 'time': '5:00'},
    {'name': 'Cool Down Walk', 'detail': '5 mins', 'cal': '20 cal', 'time': '5:00'},
  ],
  DateTime.friday: [
    {'name': 'Bodyweight Squats', 'detail': '20 reps × 4 sets', 'cal': '70 cal', 'time': '1:00'},
    {'name': 'Reverse Lunges', 'detail': '12 reps each leg × 3 sets', 'cal': '60 cal', 'time': '1:00'},
    {'name': 'Glute Bridges', 'detail': '20 reps × 3 sets', 'cal': '40 cal', 'time': '1:00'},
    {'name': 'Calf Raises', 'detail': '25 reps × 3 sets', 'cal': '25 cal', 'time': '0:45'},
    {'name': 'Wall Sit', 'detail': '60 seconds × 3 sets', 'cal': '35 cal', 'time': '1:00'},
  ],
  DateTime.saturday: [
    {'name': 'The Hundred', 'detail': '100 pumps', 'cal': '30 cal', 'time': '2:00'},
    {'name': 'Roll-Up', 'detail': '10 reps × 2 sets', 'cal': '20 cal', 'time': '1:30'},
    {'name': 'Single Leg Circles', 'detail': '5 circles each direction, each leg', 'cal': '20 cal', 'time': '1:30'},
    {'name': 'Plank Variations', 'detail': '30s each: front, left, right × 2 sets', 'cal': '40 cal', 'time': '2:00'},
    {'name': 'Swimming', 'detail': '5 breath cycles × 2 sets', 'cal': '25 cal', 'time': '1:00'},
  ],
  DateTime.sunday: [
    {'name': 'Full Body Stretch', 'detail': '30s each stretch', 'cal': '20 cal', 'time': '5:00'},
    {'name': 'Foam Rolling', 'detail': '10 slow rolls per area', 'cal': '20 cal', 'time': '5:00'},
    {'name': 'Mindful Walking', 'detail': '10 mins', 'cal': '40 cal', 'time': '10:00'},
  ],
};

// Provider trả về danh sách bài tập cho ngày đang chọn
final exercisesForSelectedDayProvider = Provider<List<Map<String, String>>>((ref) {
  final selectedDate = ref.watch(selectedWorkoutDateProvider);
  final weekday = selectedDate.weekday;
  return weeklyWorkoutMock[weekday] ?? [
    {'name': 'Rest Day', 'detail': 'No exercises scheduled', 'cal': '0 cal', 'time': '0:00'},
  ];
});

// Provider nhãn nút Start
final workoutButtonLabelProvider = Provider<String>((ref) {
  final selectedDate = ref.watch(selectedWorkoutDateProvider);
  const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const workoutNames = ['HIIT Blast', 'Upper Power', 'Yoga Flow', 'Cardio Run', 'Leg Day', 'Core Pilates', 'Recovery'];
  final idx = selectedDate.weekday - 1;
  return 'Start ${dayNames[idx]} ${workoutNames[idx]}';
});