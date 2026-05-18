// lib/features/grocery/viewmodels/grocery_state.dart

import '../../../data/models/recipe_model.dart';

// ─── Model nội bộ ─────────────────────────────────────────────────────────────

/// Nguyên liệu đã được gom:
/// cùng tên + cùng unit + cùng category → cộng dồn amount, đếm mealCount
class AggregatedItem {
  final String name;
  final double totalAmount;
  final String unit;
  final int mealCount;
  final IngredientCategory category;
  final bool isBought;

  const AggregatedItem({
    required this.name,
    required this.totalAmount,
    required this.unit,
    required this.mealCount,
    required this.category,
    this.isBought = false,
  });

  AggregatedItem copyWith({
    double? totalAmount,
    int? mealCount,
    bool? isBought,
  }) {
    return AggregatedItem(
      name:        name,
      totalAmount: totalAmount ?? this.totalAmount,
      unit:        unit,
      mealCount:   mealCount   ?? this.mealCount,
      category:    category,
      isBought:    isBought    ?? this.isBought,
    );
  }
}

// ─── Enum trạng thái ──────────────────────────────────────────────────────────

enum GroceryStatus {
  initial,  // Chưa làm gì
  loading,  // Đang fetch user_plans + recipes từ Firestore
  success,  // Đã có data
  error,    // Lỗi Firestore
}

// ─── State ────────────────────────────────────────────────────────────────────

class GroceryState {
  final GroceryStatus status;
  final String? errorMessage;

  /// Danh sách nguyên liệu đã gom + sắp xếp
  final List<AggregatedItem> items;

  /// null = "All" (hiển thị tất cả)
  final IngredientCategory? selectedCategory;

  /// Tuần đang xem — luôn là ngày Thứ 2 (Monday) của tuần
  final DateTime weekStart;

  const GroceryState({
    this.status           = GroceryStatus.initial,
    this.errorMessage,
    this.items            = const [],
    this.selectedCategory,
    required this.weekStart,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isLoading => status == GroceryStatus.loading;

  List<AggregatedItem> get filteredItems {
    if (selectedCategory == null) return items;
    return items.where((i) => i.category == selectedCategory).toList();
  }

  int get totalItems  => items.length;
  int get boughtItems => items.where((i) => i.isBought).length;

  // ── copyWith ───────────────────────────────────────────────────────────────

  GroceryState copyWith({
    GroceryStatus?        status,
    String?               errorMessage,
    List<AggregatedItem>? items,
    Object?               selectedCategory = _sentinel,
    DateTime?             weekStart,
  }) {
    return GroceryState(
      status:           status           ?? this.status,
      errorMessage:     errorMessage     ?? this.errorMessage,
      items:            items            ?? this.items,
      selectedCategory: selectedCategory == _sentinel
          ? this.selectedCategory
          : selectedCategory as IngredientCategory?,
      weekStart:        weekStart        ?? this.weekStart,
    );
  }
}

// Sentinel để phân biệt "set null có chủ đích" vs "không truyền"
const Object _sentinel = Object();