// lib/data/models/workout_model.dart

class ExerciseItem {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final int restSec;
  final String instruction; // Hướng dẫn chi tiết thực hiện
  final String imageUrl;    // Ảnh minh họa riêng cho bài tập này

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSec,
    this.instruction = '',
    this.imageUrl    = '',
  });

  factory ExerciseItem.fromMap(Map<String, dynamic> map) {
    return ExerciseItem(
      id:          map['id']?.toString() ?? '',
      name:        map['name']?.toString() ?? '',
      sets:        (map['sets'] as num?)?.toInt() ?? 0,
      reps:        (map['reps'] as num?)?.toInt() ?? 0,
      restSec:     (map['rest_sec'] as num?)?.toInt() ?? 0,
      instruction: map['instruction']?.toString() ?? '',
      imageUrl:    map['image_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id':          id,
    'name':        name,
    'sets':        sets,
    'reps':        reps,
    'rest_sec':    restSec,
    'instruction': instruction,
    'image_url':   imageUrl,
  };
}

class WorkoutModel {
  final String id;          // Firestore document ID
  final String title;
  final String category;      // "Cardio" | "Strength" | "Yoga"
  final String difficulty;    // "Beginner" | "Intermediate" | "Advanced"
  final int    durationMin;
  final String muscleGroup;   // "Ngực" | "Lưng" | "Chân" | ...
  final int    caloriesBurned;
  final List<ExerciseItem> exercises;
  final String imageUrl;

  const WorkoutModel({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.durationMin,
    required this.muscleGroup,
    required this.caloriesBurned,
    required this.exercises,
    required this.imageUrl,
  });

  factory WorkoutModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return WorkoutModel(
      id:          docId,
      title:       data['title']?.toString() ?? '',
      category:       data['category']?.toString() ?? 'Cardio',
      difficulty:     data['difficulty']?.toString() ?? 'Beginner',
      durationMin:    (data['duration_min']     as num?)?.toInt() ?? 0,
      muscleGroup:    data['muscle_group']?.toString() ?? 'Toàn thân',
      caloriesBurned: (data['calories_burned']  as num?)?.toInt() ?? 0,
      exercises:      ((data['exercises'] as List?) ?? [])
          .map((e) => ExerciseItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      imageUrl:    data['image_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':        title,
    'category':        category,
    'difficulty':      difficulty,
    'duration_min':    durationMin,
    'muscle_group':    muscleGroup,
    'calories_burned': caloriesBurned,
    'exercises':       exercises.map((e) => e.toMap()).toList(),
    'image_url':    imageUrl,
  };
}