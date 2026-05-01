// lib/features/admin/viewmodels/admin_viewmodel.dart
//
// Mô tả: ViewModel quản lý toàn bộ logic Admin.
// View KHÔNG gọi Firestore trực tiếp — chỉ gọi hàm trong file này.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/recipe_model.dart';
import '../../../data/repositories/admin_repo.dart';
import 'admin_state.dart';

// ─── Provider ────────────────────────────────────────────────────────────────
final adminViewModelProvider =
StateNotifierProvider<AdminViewModel, AdminState>((ref) {
  final repo = ref.watch(adminRepoProvider);
  return AdminViewModel(repo);
});

// ─── ViewModel ───────────────────────────────────────────────────────────────
class AdminViewModel extends StateNotifier<AdminState> {
  final AdminRepo _repo;
  StreamSubscription<List<RecipeModel>>? _recipesSub;

  AdminViewModel(this._repo) : super(const AdminState()) {
    // Load ngay khi khởi tạo
    loadDashboard();
    _listenRecipes();
  }

  // ── Tải thống kê dashboard ───────────────────────────────────────────────
  Future<void> loadDashboard() async {
    state = state.copyWith(status: AdminStatus.loading);
    try {
      final stats = await _repo.getDashboardStats();
      state = state.copyWith(
        status:        AdminStatus.success,
        recipeCount:   stats['recipes']  ?? 0,
        workoutCount:  stats['workouts'] ?? 0,
        userCount:     stats['users']    ?? 0,
      );
    } catch (e) {
      state = state.copyWith(
        status:       AdminStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      );
    }
  }

  // ── Lắng nghe recipes realtime ───────────────────────────────────────────
  void _listenRecipes() {
    _recipesSub = _repo.watchRecipes().listen(
          (recipes) => state = state.copyWith(recipes: recipes),
      onError: (_) {},
    );
  }

  // ── Chuyển tab ───────────────────────────────────────────────────────────
  void setAdminTab(AdminTab tab) =>
      state = state.copyWith(activeTab: tab);

  void setContentTab(ContentTab tab) =>
      state = state.copyWith(activeContentTab: tab);

  // ── CRUD Recipes ─────────────────────────────────────────────────────────

  Future<void> addRecipe(RecipeModel recipe) async {
    state = state.copyWith(status: AdminStatus.loading);
    try {
      await _repo.addRecipe(recipe);
      state = state.copyWith(status: AdminStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Thêm thất bại: $e',
      );
    }
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    state = state.copyWith(status: AdminStatus.loading);
    try {
      await _repo.updateRecipe(recipe);
      state = state.copyWith(status: AdminStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Cập nhật thất bại: $e',
      );
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _repo.deleteRecipe(recipeId);
    } catch (e) {
      state = state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Xóa thất bại: $e',
      );
    }
  }

  @override
  void dispose() {
    _recipesSub?.cancel();
    super.dispose();
  }
}