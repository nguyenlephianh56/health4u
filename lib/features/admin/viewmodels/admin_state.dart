// lib/features/admin/viewmodels/admin_state.dart

import '../../../data/models/recipe_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/models/admin_user_model.dart';

enum AdminStatus { initial, loading, success, error }
enum AdminTab    { content, users }
enum ContentTab  { recipes, workouts }

class AdminState {
  final AdminStatus status;
  final String? errorMessage;

  // Thống kê dashboard
  final int recipeCount;
  final int workoutCount;
  final int userCount;

  // Tab đang chọn
  final AdminTab    activeTab;
  final ContentTab  activeContentTab;

  // Dữ liệu realtime
  final List<RecipeModel>    recipes;
  final List<WorkoutModel>   workouts;
  final List<AdminUserModel> allUsers;      // Toàn bộ users từ Firestore
  final List<AdminUserModel> filteredUsers; // Kết quả sau khi search
  final String               searchQuery;

  const AdminState({
    this.status           = AdminStatus.initial,
    this.errorMessage,
    this.recipeCount      = 0,
    this.workoutCount     = 0,
    this.userCount        = 0,
    this.activeTab        = AdminTab.content,
    this.activeContentTab = ContentTab.recipes,
    this.recipes          = const [],
    this.workouts         = const [],
    this.allUsers         = const [],
    this.filteredUsers    = const [],
    this.searchQuery      = '',
  });

  AdminState copyWith({
    AdminStatus?         status,
    String?              errorMessage,
    int?                 recipeCount,
    int?                 workoutCount,
    int?                 userCount,
    AdminTab?            activeTab,
    ContentTab?          activeContentTab,
    List<RecipeModel>?   recipes,
    List<WorkoutModel>?  workouts,
    List<AdminUserModel>? allUsers,
    List<AdminUserModel>? filteredUsers,
    String?              searchQuery,
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
      workouts:         workouts         ?? this.workouts,
      allUsers:         allUsers         ?? this.allUsers,
      filteredUsers:    filteredUsers    ?? this.filteredUsers,
      searchQuery:      searchQuery      ?? this.searchQuery,
    );
  }
}