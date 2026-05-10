// lib/features/admin/viewmodels/admin_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/recipe_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/admin_repo.dart';
import 'admin_state.dart';

final adminViewModelProvider =
StateNotifierProvider<AdminViewModel, AdminState>((ref) {
  final repo = ref.watch(adminRepoProvider);
  return AdminViewModel(repo);
});

class AdminViewModel extends StateNotifier<AdminState> {
  final AdminRepo _repo;
  StreamSubscription<List<RecipeModel>>?  _recipesSub;
  StreamSubscription<List<WorkoutModel>>? _workoutsSub;

  AdminViewModel(this._repo) : super(const AdminState()) {
    loadDashboard();
    _listenRecipes();
    _listenWorkouts();
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<void> loadDashboard() async {
    state = state.copyWith(status: AdminStatus.loading);
    try {
      final stats = await _repo.getDashboardStats();
      state = state.copyWith(
        status:       AdminStatus.success,
        recipeCount:  stats['recipes']  ?? 0,
        workoutCount: stats['workouts'] ?? 0,
        userCount:    stats['users']    ?? 0,
      );
    } catch (e) {
      state = state.copyWith(
        status:       AdminStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      );
    }
  }

  // ── Stream listeners ──────────────────────────────────────────────────────
  void _listenRecipes() {
    _recipesSub = _repo.watchRecipes().listen(
          (recipes) => state = state.copyWith(recipes: recipes),
      onError: (_) {},
    );
  }

  void _listenWorkouts() {
    _workoutsSub = _repo.watchWorkouts().listen(
          (workouts) => state = state.copyWith(workouts: workouts),
      onError: (_) {},
    );
  }

  // ── Tab navigation ────────────────────────────────────────────────────────
  void setAdminTab(AdminTab tab) =>
      state = state.copyWith(activeTab: tab);

  void setContentTab(ContentTab tab) =>
      state = state.copyWith(activeContentTab: tab);

  // ── CRUD Recipes ──────────────────────────────────────────────────────────
  Future<void> addRecipe(RecipeModel recipe) async {
    try {
      await _repo.addRecipe(recipe);
    } catch (e) {
      state = state.copyWith(
          status: AdminStatus.error, errorMessage: 'Thêm thất bại: $e');
    }
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    try {
      await _repo.updateRecipe(recipe);
    } catch (e) {
      state = state.copyWith(
          status: AdminStatus.error, errorMessage: 'Cập nhật thất bại: $e');
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _repo.deleteRecipe(recipeId);
    } catch (e) {
      state = state.copyWith(
          status: AdminStatus.error, errorMessage: 'Xóa thất bại: $e');
    }
  }

  // ── CRUD Workouts ─────────────────────────────────────────────────────────
  Future<void> addWorkout(WorkoutModel workout) async {
    try {
      await _repo.addWorkout(workout);
    } catch (e) {
      state = state.copyWith(
          status: AdminStatus.error, errorMessage: 'Thêm thất bại: $e');
    }
  }

  Future<void> updateWorkout(WorkoutModel workout) async {
    try {
      await _repo.updateWorkout(workout);
    } catch (e) {
      state = state.copyWith(
          status: AdminStatus.error, errorMessage: 'Cập nhật thất bại: $e');
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _repo.deleteWorkout(workoutId);
    } catch (e) {
      state = state.copyWith(
          status: AdminStatus.error, errorMessage: 'Xóa thất bại: $e');
    }
  }

  @override
  void dispose() {
    _recipesSub?.cancel();
    _workoutsSub?.cancel();
    super.dispose();
  }
}