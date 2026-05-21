// lib/features/grocery/viewmodels/grocery_viewmodel.dart
//
// ĐÃ FIX: Dùng watchMealPlansForWeek (realtime stream) thay getMealPlansForWeek
// UserPlanEntry giờ dùng referenceId = meals.X.recipe_id (đúng với Firestore)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/recipe_model.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/grocery_repo.dart';
import 'grocery_state.dart';

DateTime _getWeekStart(DateTime date) {
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: date.weekday - 1));
}

class GroceryViewModel extends StateNotifier<GroceryState> {
  final GroceryRepo _repo;
  String _userId;

  StreamSubscription<List<UserPlanEntry>>? _plansSub;
  StreamSubscription<Map<String, bool>>?  _boughtSub;

  final Map<String, RecipeModel> _recipeCache = {};
  List<UserPlanEntry> _currentPlans = [];

  GroceryViewModel({
    required GroceryRepo repo,
    required String userId,
  })  : _repo   = repo,
        _userId = userId,
        super(GroceryState(weekStart: _getWeekStart(DateTime.now()))) {
    if (_userId.isNotEmpty) {
      _subscribeToWeek(state.weekStart);
    }
  }

  // ── Cập nhật userId khi auth sẵn sàng ────────────────────────────────────

  void updateUserId(String newUserId) {
    if (newUserId == _userId || newUserId.isEmpty) return;
    _userId = newUserId;
    _subscribeToWeek(state.weekStart);
  }

  // ── Subscribe realtime ────────────────────────────────────────────────────

  void _subscribeToWeek(DateTime weekStart) {
    if (_userId.isEmpty) return;

    _plansSub?.cancel();
    _boughtSub?.cancel();
    _currentPlans = [];
    _recipeCache.clear();

    state = state.copyWith(
      status:    GroceryStatus.loading,
      weekStart: weekStart,
      items:     [],
    );

    _plansSub = _repo
        .watchMealPlansForWeek(userId: _userId, weekStart: weekStart)
        .listen(_onPlansChanged, onError: (e, st) {
      debugPrint('[GroceryVM] watchMealPlans error: $e\n$st');
      state = state.copyWith(
        status:       GroceryStatus.error,
        errorMessage: 'Không thể tải danh sách. Vui lòng thử lại.',
      );
    });
  }

  // ── Xử lý khi plans thay đổi ─────────────────────────────────────────────

  Future<void> _onPlansChanged(List<UserPlanEntry> newPlans) async {
    final hasChanged = _hasPlansChanged(_currentPlans, newPlans);
    if (!hasChanged && state.status == GroceryStatus.success) return;

    _currentPlans = newPlans;

    if (newPlans.isEmpty) {
      _boughtSub?.cancel();
      _boughtSub = null;
      state = state.copyWith(status: GroceryStatus.success, items: []);
      return;
    }

    // Fetch recipes chưa có trong cache
    final neededIds = newPlans
        .map((p) => p.referenceId)
        .toSet()
        .where((id) => id.isNotEmpty && !_recipeCache.containsKey(id))
        .toList();

    if (neededIds.isNotEmpty) {
      try {
        final fetched = await _repo.getRecipesByIds(neededIds);
        for (final r in fetched) {
          _recipeCache[r.id] = r;
        }
      } catch (e, st) {
        debugPrint('[GroceryVM] getRecipesByIds error: $e\n$st');
        state = state.copyWith(
          status:       GroceryStatus.error,
          errorMessage: 'Không thể tải công thức. Vui lòng thử lại.',
        );
        return;
      }
    }

    // Aggregate
    final aggregated = _aggregateIngredients(newPlans, _recipeCache);

    // Giữ isBought cho item cũ còn tồn tại
    final existingBought = {
      for (final i in state.items) '${i.name}__${i.unit}': i.isBought,
    };
    final mergedItems = aggregated.map((item) {
      final key = '${item.name}__${item.unit}';
      return item.copyWith(isBought: existingBought[key] ?? false);
    }).toList();

    state = state.copyWith(status: GroceryStatus.success, items: mergedItems);

    // Subscribe isBought nếu chưa có
    _boughtSub ??= _repo
        .watchBoughtStatus(userId: _userId, weekStart: state.weekStart)
        .listen(_mergeBoughtStatus, onError: (e) {
      debugPrint('[GroceryVM] watchBoughtStatus error: $e');
    });
  }

  bool _hasPlansChanged(
      List<UserPlanEntry> oldList,
      List<UserPlanEntry> newList,
      ) {
    if (oldList.length != newList.length) return true;
    final oldSet = oldList.map((p) => '${p.date}_${p.mealType}_${p.referenceId}').toSet();
    final newSet = newList.map((p) => '${p.date}_${p.mealType}_${p.referenceId}').toSet();
    return !oldSet.containsAll(newSet) || !newSet.containsAll(oldSet);
  }

  // ── Unit conversion helpers ──────────────────────────────────────────────

  /// Nhóm đơn vị: 'mass' hoặc 'volume' hoặc 'other'
  static String _unitGroup(String unit) {
    const massUnits   = {'g', 'gram', 'kg', 'oz', 'lb'};
    const volumeUnits = {'ml', 'l', 'tsp', 'tbsp', 'cup', 'fl_oz'};
    final u = unit.toLowerCase().trim();
    if (massUnits.contains(u))   return 'mass';
    if (volumeUnits.contains(u)) return 'volume';
    return 'other';
  }

  /// Quy đổi về đơn vị cơ bản: gram (mass) hoặc ml (volume)
  static double _toBase(double amount, String unit) {
    switch (unit.toLowerCase().trim()) {
    // mass
      case 'kg':    return amount * 1000;
      case 'oz':    return amount * 28.3495;
      case 'lb':    return amount * 453.592;
      case 'g':
      case 'gram':  return amount;
    // volume
      case 'l':     return amount * 1000;
      case 'tsp':   return amount * 5;
      case 'tbsp':  return amount * 15;
      case 'cup':   return amount * 240;
      case 'fl_oz': return amount * 29.5735;
      case 'ml':    return amount;
      default:      return amount;
    }
  }

  /// Chuyển từ đơn vị cơ bản về đơn vị hiển thị đẹp nhất
  static (double, String) _fromBase(double baseAmount, String group) {
    if (group == 'mass') {
      if (baseAmount >= 1000) return (baseAmount / 1000, 'kg');
      return (baseAmount, 'g');
    } else if (group == 'volume') {
      if (baseAmount >= 1000) return (baseAmount / 1000, 'l');
      if (baseAmount >= 240)  return (double.parse((baseAmount / 240).toStringAsFixed(2)), 'cup');
      if (baseAmount >= 15)   return (double.parse((baseAmount / 15).toStringAsFixed(1)), 'tbsp');
      if (baseAmount >= 5)    return (double.parse((baseAmount / 5).toStringAsFixed(1)), 'tsp');
      return (baseAmount, 'ml');
    }
    return (baseAmount, '');
  }

  List<AggregatedItem> _aggregateIngredients(
      List<UserPlanEntry> plans,
      Map<String, RecipeModel> recipeMap,
      ) {
    // key: 'normalizedName__group__category'  (group = mass | volume | other)
    // value: { baseAmount, mealCount, displayName, category, originalUnit }
    final Map<String, _AggBuffer> buffers = {};

    for (final plan in plans) {
      final recipe = recipeMap[plan.referenceId];
      if (recipe == null) continue;

      for (final ing in recipe.ingredients) {
        final normalizedName = ing.name.toLowerCase().trim();
        final group = _unitGroup(ing.unit);

        // Nếu đơn vị là 'other' (cái, quả, ...), vẫn gộp theo tên + unit gốc
        final groupKey = group == 'other' ? ing.unit.toLowerCase().trim() : group;
        final key = '${normalizedName}__${groupKey}__${ing.category.value}';

        final base = group == 'other' ? ing.amount : _toBase(ing.amount, ing.unit);

        if (buffers.containsKey(key)) {
          buffers[key]!.baseAmount += base;
          buffers[key]!.mealCount  += 1;
        } else {
          buffers[key] = _AggBuffer(
            displayName:  ing.name,
            baseAmount:   base,
            mealCount:    1,
            group:        groupKey,
            originalUnit: ing.unit,
            category:     ing.category,
          );
        }
      }
    }

    final result = buffers.values.map((buf) {
      final (displayAmount, displayUnit) = buf.group == 'mass' || buf.group == 'volume'
          ? _fromBase(buf.baseAmount, buf.group)
          : (buf.baseAmount, buf.originalUnit);

      return AggregatedItem(
        name:        buf.displayName,
        totalAmount: double.parse(displayAmount.toStringAsFixed(2)),
        unit:        displayUnit,
        mealCount:   buf.mealCount,
        category:    buf.category,
      );
    }).toList();

    return result
      ..sort((a, b) {
        final cat = a.category.index.compareTo(b.category.index);
        if (cat != 0) return cat;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  void _mergeBoughtStatus(Map<String, bool> statusMap) {
    if (statusMap.isEmpty) return;
    final updated = state.items.map((item) {
      final key = '${item.name}__${item.unit}';
      return item.copyWith(isBought: statusMap[key] ?? item.isBought);
    }).toList();
    state = state.copyWith(items: updated);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> loadWeek(DateTime weekStart) async => _subscribeToWeek(weekStart);

  Future<void> toggleItem(String name, String unit) async {
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

    try {
      await _repo.toggleItemBought(
        userId:    _userId,
        weekStart: state.weekStart,
        itemName:  name,
        itemUnit:  unit,
        isBought:  newBought,
      );
    } catch (e) {
      debugPrint('[GroceryVM] toggleItem error: $e');
      // Rollback
      final rollback = state.items.map((item) {
        if (item.name == name && item.unit == unit) {
          return item.copyWith(isBought: !newBought);
        }
        return item;
      }).toList();
      state = state.copyWith(items: rollback);
    }
  }

  Future<void> resetAll() async {
    final updated = state.items.map((i) => i.copyWith(isBought: false)).toList();
    state = state.copyWith(items: updated);
    try {
      await _repo.saveGroceryList(
        userId:    _userId,
        weekStart: state.weekStart,
        items:     updated.map((i) => GroceryFirestoreItem(
          name:     i.name,
          amount:   i.totalAmount,
          unit:     i.unit,
          category: i.category.value,
          isBought: false,
        )).toList(),
      );
    } catch (e) {
      debugPrint('[GroceryVM] resetAll error: $e');
    }
  }

  void previousWeek() =>
      _subscribeToWeek(state.weekStart.subtract(const Duration(days: 7)));

  void nextWeek() =>
      _subscribeToWeek(state.weekStart.add(const Duration(days: 7)));

  void setCategory(IngredientCategory? cat) =>
      state = state.copyWith(selectedCategory: cat);

  @override
  void dispose() {
    _plansSub?.cancel();
    _boughtSub?.cancel();
    super.dispose();
  }
}

// ─── Internal buffer class dùng cho aggregation ───────────────────────────────

class _AggBuffer {
  final String            displayName;
  final String            group;        // 'mass' | 'volume' | unit gốc nếu 'other'
  final String            originalUnit;
  final IngredientCategory category;
  double                  baseAmount;
  int                     mealCount;

  _AggBuffer({
    required this.displayName,
    required this.baseAmount,
    required this.mealCount,
    required this.group,
    required this.originalUnit,
    required this.category,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final groceryViewModelProvider =
StateNotifierProvider<GroceryViewModel, GroceryState>((ref) {
  final repo          = ref.watch(groceryRepoProvider);
  final initialUserId = ref.read(authRepoProvider).userId ?? '';
  final vm            = GroceryViewModel(repo: repo, userId: initialUserId);

  // Watch auth — cập nhật userId khi auth hoàn tất
  ref.listen(authRepoProvider, (_, next) {
    vm.updateUserId((next as dynamic).userId as String? ?? '');
  });

  return vm;
});