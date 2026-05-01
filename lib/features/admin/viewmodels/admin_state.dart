// lib/features/admin/viewmodels/admin_state.dart

import '../../../data/models/recipe_model.dart';

enum AdminStatus { initial, loading, success, error }

// Tab đang active ở màn hình Admin
enum AdminTab { content, users }

// Sub-tab trong Content
enum ContentTab { recipes, workouts }

class AdminState {
  final AdminStatus status;
  final String? errorMessage;

  // Thống kê dashboard
  final int recipeCount;
  final int workoutCount;
  final int userCount;

  // Tab đang chọn
  final AdminTab activeTab;
  final ContentTab activeContentTab;

  // Danh sách recipes (stream)
  final List<RecipeModel> recipes;

  const AdminState({
    this.status           = AdminStatus.initial,
    this.errorMessage,
    this.recipeCount      = 0,
    this.workoutCount     = 0,
    this.userCount        = 0,
    this.activeTab        = AdminTab.content,
    this.activeContentTab = ContentTab.recipes,
    this.recipes          = const [],
  });

  AdminState copyWith({
    AdminStatus?    status,
    String?         errorMessage,
    int?            recipeCount,
    int?            workoutCount,
    int?            userCount,
    AdminTab?       activeTab,
    ContentTab?     activeContentTab,
    List<RecipeModel>? recipes,
  }) {
    return AdminState(
      status:           status           ?? this.status,
      errorMessage:     errorMessage     ?? this.errorMessage,
      recipeCount:      recipeCount      ?? this.recipeCount,
      workoutCount:     workoutCount     ?? this.workoutCount,
      userCount:        userCount        ?? this.userCount,
      activeTab:        activeTab        ?? this.activeTab,
      activeContentTab: activeContentTab ?? this.activeContentTab,
      recipes:          recipes          ?? this.recipes,
    );
  }
}