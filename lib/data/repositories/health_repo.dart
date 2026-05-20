// lib/data/repositories/health_repo.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health4u/data/models/workout_model.dart';

// ── Model cho workout trong user plan ─────────────────────────────────────────
class PlanWorkout {
  final String workoutId;
  final String title;
  final String category;
  final String difficulty;
  final int durationMin;
  final String muscleGroup;
  final int caloriesBurned;

  const PlanWorkout({
    required this.workoutId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.durationMin,
    required this.muscleGroup,
    required this.caloriesBurned,
  });

  factory PlanWorkout.fromMap(Map<String, dynamic> map) {
    return PlanWorkout(
      workoutId:      map['workout_id']?.toString() ?? '',
      title:          map['title']?.toString() ?? '',
      category:       map['category']?.toString() ?? 'Strength',
      difficulty:     map['difficulty']?.toString() ?? 'Beginner',
      durationMin:    (map['duration_min'] as num?)?.toInt() ?? 0,
      muscleGroup:    map['muscle_group']?.toString() ?? '',
      caloriesBurned: (map['calories_burned'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Model cho 1 ngày trong plan ───────────────────────────────────────────────
class UserPlanDay {
  final String docId;       // Firestore document ID — dùng để update
  final String date;
  final String dayOfWeek;
  final PlanWorkout? workout;
  final bool isCompleted;   // đã hoàn thành bài hôm đó chưa

  const UserPlanDay({
    required this.docId,
    required this.date,
    required this.dayOfWeek,
    this.workout,
    this.isCompleted = false,
  });

  factory UserPlanDay.fromFirestore(String docId, Map<String, dynamic> data) {
    PlanWorkout? workout;
    if (data['workout'] != null) {
      workout = PlanWorkout.fromMap(
        Map<String, dynamic>.from(data['workout'] as Map),
      );
    }
    return UserPlanDay(
      docId:       docId,
      date:        data['date']?.toString() ?? '',
      dayOfWeek:   data['day_of_week']?.toString() ?? '',
      workout:     workout,
      isCompleted: data['is_completed'] == true,
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────
class HealthRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  HealthRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db   = db   ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // ── Lấy danh sách ngày trong plan của user ──────────────────────────────────
  Future<List<UserPlanDay>> getUserPlanDays() async {
    final uid = _userId;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('user_plans')
        .where('user_id', isEqualTo: uid)
        .get();

    final days = snapshot.docs
        .map((doc) => UserPlanDay.fromFirestore(
      doc.id,
      Map<String, dynamic>.from(doc.data()),
    ))
        .toList();

    days.sort((a, b) => a.date.compareTo(b.date));
    return days;
  }

  Stream<List<UserPlanDay>> watchUserPlanDays() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user_plans')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final days = snap.docs
          .map((doc) => UserPlanDay.fromFirestore(
        doc.id,
        Map<String, dynamic>.from(doc.data()),
      ))
          .toList();
      days.sort((a, b) => a.date.compareTo(b.date));
      return days;
    });
  }

  // ── Đánh dấu hoàn thành ngày tập ────────────────────────────────────────────
  Future<void> markDayCompleted(String docId) async {
    if (docId.isEmpty) return;
    await _db
        .collection('user_plans')
        .doc(docId)
        .update({'is_completed': true});
  }

  // ── Lấy WorkoutModel đầy đủ (kèm exercises) theo workoutId ─────────────────
  Future<WorkoutModel?> getWorkoutDetail(String workoutId) async {
    if (workoutId.isEmpty) return null;
    final doc = await _db.collection('workouts').doc(workoutId).get();
    if (!doc.exists || doc.data() == null) return null;
    return WorkoutModel.fromFirestore(doc.id, doc.data()!);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final healthRepoProvider = Provider<HealthRepository>(
      (ref) => HealthRepository(),
);

/// Auth state provider — tự động rebuild khi user login/logout
final _authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// FutureProvider phụ thuộc vào auth state
final userPlanDaysProvider = FutureProvider<List<UserPlanDay>>((ref) async {
  final authState = ref.watch(_authStateProvider);
  final user = authState.asData?.value;
  if (user == null) return [];
  return ref.watch(healthRepoProvider).getUserPlanDays();
});

/// StreamProvider — realtime updates
final userPlanDaysStreamProvider = StreamProvider<List<UserPlanDay>>((ref) {
  final authState = ref.watch(_authStateProvider);
  final user = authState.asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(healthRepoProvider).watchUserPlanDays();
});

/// Provider fetch WorkoutModel đầy đủ kèm exercises theo workoutId
/// Dùng trong ExerciseDetailScreen để hiển thị danh sách bài tập nhỏ
final workoutDetailProvider =
FutureProvider.family<WorkoutModel?, String>((ref, workoutId) async {
  return ref.read(healthRepoProvider).getWorkoutDetail(workoutId);
});