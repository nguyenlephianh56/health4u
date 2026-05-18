// lib/features/grocery/viewmodels/grocery_viewmodel.dart
//
// Flow:
//   1. Tính weekStart (ngày Thứ 2 của tuần hiện tại)
//   2. Fetch user_plans loại "meal" trong 7 ngày từ Firestore
//   3. Batch-fetch recipes theo referenceId từ các plan
//   4. Gom nguyên liệu từ các recipes → AggregatedItem
//   5. Đọc trạng thái isBought từ grocery_list (Firestore) → merge vào items
//   6. Mọi thay đổi isBought → ghi lên Firestore qua GroceryRepo

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../data/models/recipe_model.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/grocery_repo.dart';
import 'grocery_state.dart';

// ─── Helper: tính ngày Thứ 2 đầu tuần ───────────────────────────────────────

DateTime _getWeekStart(DateTime date) {
  // weekday: 1=Mon ... 7=Sun
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: date.weekday - 1));
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class GroceryViewModel extends StateNotifier<GroceryState> {
  final GroceryRepo _repo;
  final String _userId;

  StreamSubscription<Map<String, bool>>? _boughtSub;

  GroceryViewModel({
    required GroceryRepo repo,
    required String userId,
  })  : _repo   = repo,
        _userId = userId,
        super(GroceryState(weekStart: _getWeekStart(DateTime.now()))) {
    loadWeek(state.weekStart);
  }

  // ── Load tuần ─────────────────────────────────────────────────────────────

  Future<void> loadWeek(DateTime weekStart) async {
    // Huỷ subscription cũ trước khi load tuần mới
    await _boughtSub?.cancel();

    state = state.copyWith(
      status:    GroceryStatus.loading,
      weekStart: weekStart,
      items:     [],
    );

    try {
      // 1. Lấy danh sách kế hoạch bữa ăn 7 ngày
      final plans = await _repo.getMealPlansForWeek(
        userId:    _userId,
        weekStart: weekStart,
      );

      if (plans.isEmpty) {
        state = state.copyWith(status: GroceryStatus.success, items: []);
        return;
      }

      // 2. Batch-fetch recipes
      final recipeIds = plans.map((p) => p.referenceId).toSet().toList();
      final recipes   = await _repo.getRecipesByIds(recipeIds);

      // Map recipeId → RecipeModel để gom nhanh
      final recipeMap = {for (final r in recipes) r.id: r};

      // 3. Gom nguyên liệu từ tất cả recipes (bao gồm duplicate bữa)
      final aggregated = _aggregateIngredients(plans, recipeMap);

      state = state.copyWith(status: GroceryStatus.success, items: aggregated);

      // 4. Lắng nghe realtime isBought từ Firestore → merge vào state
      _boughtSub = _repo
          .watchBoughtStatus(userId: _userId, weekStart: weekStart)
          .listen(_mergeBoughtStatus, onError: (e) {
        debugPrint('[GroceryVM] watchBoughtStatus error: $e');
      });
    } catch (e, st) {
      debugPrint('[GroceryVM] loadWeek error: $e\n$st');
      state = state.copyWith(
        status:       GroceryStatus.error,
        errorMessage: 'Không thể tải danh sách. Vui lòng thử lại.',
      );
    }
  }

  // ── Gom nguyên liệu ───────────────────────────────────────────────────────

  List<AggregatedItem> _aggregateIngredients(
      List<UserPlanEntry> plans,
      Map<String, RecipeModel> recipeMap,
      ) {
    final Map<String, AggregatedItem> aggregated = {};

    for (final plan in plans) {
      final recipe = recipeMap[plan.referenceId];
      if (recipe == null) continue;

      for (final ing in recipe.ingredients) {
        final key =
            '${ing.name.toLowerCase().trim()}__${ing.unit}__${ing.category.value}';

        if (aggregated.containsKey(key)) {
          final existing = aggregated[key]!;
          aggregated[key] = existing.copyWith(
            totalAmount: existing.totalAmount + ing.amount,
            mealCount:   existing.mealCount + 1,
          );
        } else {
          aggregated[key] = AggregatedItem(
            name:        ing.name,
            totalAmount: ing.amount,
            unit:        ing.unit,
            mealCount:   1,
            category:    ing.category,
          );
        }
      }
    }

    // Sắp xếp: thứ tự category enum → tên A-Z
    return aggregated.values.toList()
      ..sort((a, b) {
        final cat = a.category.index.compareTo(b.category.index);
        if (cat != 0) return cat;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  // ── Merge isBought từ Firestore vào state ─────────────────────────────────

  void _mergeBoughtStatus(Map<String, bool> statusMap) {
    if (statusMap.isEmpty) return;

    final updated = state.items.map((item) {
      final key      = '${item.name}__${item.unit}';
      final isBought = statusMap[key] ?? item.isBought;
      return item.copyWith(isBought: isBought);
    }).toList();

    state = state.copyWith(items: updated);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Toggle isBought — cập nhật UI ngay (optimistic) rồi sync Firestore
  Future<void> toggleItem(String name, String unit) async {
    // Optimistic update
    final updated = state.items.map((item) {
      if (item.name == name && item.unit == unit) {
        return item.copyWith(isBought: !item.isBought);
      }
      return item;
    }).toList();

    final newBought = updated
        .firstWhere((i) => i.name == name && i.unit == unit)
        .isBought;

    state = state.copyWith(items: updated);

    // Sync lên Firestore (transaction)
    try {
      await _repo.toggleItemBought(
        userId:    _userId,
        weekStart: state.weekStart,
        itemName:  name,
        itemUnit:  unit,
        isBought:  newBought,
      );
    } catch (e) {
      debugPrint('[GroceryVM] toggleItem sync error: $e');
      // Rollback nếu lỗi
      final rollback = state.items.map((item) {
        if (item.name == name && item.unit == unit) {
          return item.copyWith(isBought: !newBought);
        }
        return item;
      }).toList();
      state = state.copyWith(items: rollback);
    }
  }

  /// Reset tất cả về chưa mua + lưu lên Firestore
  Future<void> resetAll() async {
    final updated =
    state.items.map((i) => i.copyWith(isBought: false)).toList();
    state = state.copyWith(items: updated);

    try {
      await _repo.saveGroceryList(
        userId:    _userId,
        weekStart: state.weekStart,
        items:     updated
            .map((i) => GroceryFirestoreItem(
          name:     i.name,
          amount:   i.totalAmount,
          unit:     i.unit,
          category: i.category.value,
          isBought: false,
        ))
            .toList(),
      );
    } catch (e) {
      debugPrint('[GroceryVM] resetAll error: $e');
    }
  }

  /// Chuyển sang tuần trước
  void previousWeek() {
    loadWeek(state.weekStart.subtract(const Duration(days: 7)));
  }

  /// Chuyển sang tuần sau
  void nextWeek() {
    loadWeek(state.weekStart.add(const Duration(days: 7)));
  }

  /// Chọn filter category (null = All)
  void setCategory(IngredientCategory? cat) {
    state = state.copyWith(selectedCategory: cat);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _boughtSub?.cancel();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final groceryViewModelProvider =
StateNotifierProvider<GroceryViewModel, GroceryState>((ref) {
  final repo   = ref.watch(groceryRepoProvider);
  final userId = ref.watch(authRepoProvider).userId ?? '';

  return GroceryViewModel(repo: repo, userId: userId);
});