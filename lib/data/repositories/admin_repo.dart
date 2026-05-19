// lib/data/repositories/admin_repo.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_model.dart';
import '../models/workout_model.dart';
import '../models/admin_user_model.dart';

final adminRepoProvider = Provider<AdminRepo>((ref) => AdminRepo());

class AdminRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Thống kê ─────────────────────────────────────────────────────────────
  Future<int> getCount(String collection) async {
    final snap = await _db.collection(collection).count().get();
    return snap.count ?? 0;
  }

  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      getCount('recipes'),
      getCount('workouts'),
      getCount('users'),
    ]);
    return {
      'recipes':  results[0],
      'workouts': results[1],
      'users':    results[2],
    };
  }

  // ── CRUD Recipes ─────────────────────────────────────────────────────────
  Stream<List<RecipeModel>> watchRecipes() {
    return _db
        .collection('recipes')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => RecipeModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<void> addRecipe(RecipeModel recipe) async {
    await _db.collection('recipes').add(recipe.toFirestore());
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    await _db.collection('recipes').doc(recipe.id).update(recipe.toFirestore());
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _db.collection('recipes').doc(recipeId).delete();
  }

  // ── CRUD Workouts ─────────────────────────────────────────────────────────
  Stream<List<WorkoutModel>> watchWorkouts() {
    return _db
        .collection('workouts')
        .orderBy('title')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => WorkoutModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<void> addWorkout(WorkoutModel workout) async {
    await _db.collection('workouts').add(workout.toFirestore());
  }

  Future<void> updateWorkout(WorkoutModel workout) async {
    await _db.collection('workouts').doc(workout.id).update(workout.toFirestore());
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _db.collection('workouts').doc(workoutId).delete();
  }

  // Users (Admin)
  Stream<List<AdminUserModel>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => AdminUserModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<List<AdminUserModel>> getAllUsers() async {
    final snap = await _db
        .collection('users')
        .orderBy('name')
        .get();
    return snap.docs
        .map((doc) => AdminUserModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}