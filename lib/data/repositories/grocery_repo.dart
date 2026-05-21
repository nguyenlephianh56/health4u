// lib/data/repositories/grocery_repo.dart
//
// ĐÃ FIX: Match đúng Firestore structure thực tế của user_plans:
//
// user_plans/{docId}
//   ├── date: "2026-05-18"          ← YYYY-MM-DD
//   ├── day_of_week: "Monday"
//   ├── user_id: "abc123"
//   ├── is_completed: true
//   └── meals: {                    ← sub-map, KHÔNG phải array
//        Breakfast: { recipe_id, name, calories, ... }
//        Lunch:     { recipe_id, name, ... }
//        Dinner:    { recipe_id, name, ... }
//        Snack:     { recipe_id, name, ... }
//       }
//
// Khác hoàn toàn với giả định cũ:
//   ✗ KHÔNG có field "type: meal"
//   ✗ KHÔNG có field "reference_id"
//   ✓ recipe_id nằm trong meals.Breakfast.recipe_id v.v.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/recipe_model.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final groceryRepoProvider = Provider<GroceryRepo>((ref) => GroceryRepo());

// ─── Model: 1 bữa ăn đã parse từ meals map ───────────────────────────────────

/// Đại diện cho 1 bữa ăn (Breakfast/Lunch/Dinner/Snack) trong 1 ngày
class UserPlanEntry {
  final String docId;       // ID của document user_plans
  final String userId;
  final String date;        // YYYY-MM-DD
  final String mealType;    // "Breakfast" | "Lunch" | "Dinner" | "Snack"
  final String referenceId; // recipe_id — dùng để fetch recipe
  final bool isCompleted;

  const UserPlanEntry({
    required this.docId,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.referenceId,
    required this.isCompleted,
  });
}

// ─── Model: 1 item trong grocery_list ────────────────────────────────────────

class GroceryFirestoreItem {
  final String name;
  final double amount;
  final String unit;
  final String category;
  final bool isBought;

  const GroceryFirestoreItem({
    required this.name,
    required this.amount,
    required this.unit,
    required this.category,
    required this.isBought,
  });

  factory GroceryFirestoreItem.fromMap(Map<String, dynamic> map) {
    return GroceryFirestoreItem(
      name:     map['name']?.toString() ?? '',
      amount:   (map['amount'] as num?)?.toDouble() ?? 0,
      unit:     map['unit']?.toString() ?? '',
      category: map['category']?.toString() ?? 'other',
      isBought: map['is_bought'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':      name,
    'amount':    amount,
    'unit':      unit,
    'category':  category,
    'is_bought': isBought,
  };
}

// ─── Repo ─────────────────────────────────────────────────────────────────────

class GroceryRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tên các bữa trong Firestore (đúng case)
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  // ── 1. Stream realtime user_plans 7 ngày ─────────────────────────────────

  /// Lắng nghe realtime — mỗi khi user đổi món ăn ở màn hình Bữa ăn,
  /// Firestore sẽ emit snapshot mới → Grocery tự cập nhật.
  ///
  /// Parse đúng structure:
  ///   doc.data()['meals']['Breakfast']['recipe_id'] → referenceId
  Stream<List<UserPlanEntry>> watchMealPlansForWeek({
    required String userId,
    required DateTime weekStart,
  }) {
    final dates = _buildDateList(weekStart);

    return _db
        .collection('user_plans')
        .where('user_id', isEqualTo: userId)
        .where('date', whereIn: dates)
        .snapshots()
        .map((snap) => _parsePlanDocs(snap.docs));
  }

  /// Parse danh sách documents → flat list UserPlanEntry
  /// Mỗi document có thể chứa 4 bữa (Breakfast/Lunch/Dinner/Snack)
  List<UserPlanEntry> _parsePlanDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final entries = <UserPlanEntry>[];

    for (final doc in docs) {
      final data   = doc.data();
      final date   = data['date']?.toString() ?? '';
      final userId = data['user_id']?.toString() ?? '';

      // Lấy sub-map meals
      final mealsRaw = data['meals'];
      if (mealsRaw == null || mealsRaw is! Map) continue;

      final meals = Map<String, dynamic>.from(mealsRaw);

      // Duyệt từng bữa: Breakfast, Lunch, Dinner, Snack
      for (final mealType in _mealTypes) {
        final mealData = meals[mealType];
        if (mealData == null || mealData is! Map) continue;

        final meal      = Map<String, dynamic>.from(mealData);
        final recipeId  = meal['recipe_id']?.toString() ?? '';

        if (recipeId.isEmpty) continue;

        entries.add(UserPlanEntry(
          docId:       doc.id,
          userId:      userId,
          date:        date,
          mealType:    mealType,
          referenceId: recipeId,
          isCompleted: meal['is_completed'] == true,
        ));
      }
    }

    return entries;
  }

  /// Sinh danh sách 7 ngày YYYY-MM-DD từ weekStart
  List<String> _buildDateList(DateTime weekStart) {
    return List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(d);
    });
  }

  // ── 2. Batch-fetch recipes theo ID ───────────────────────────────────────

  Future<List<RecipeModel>> getRecipesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final results   = <RecipeModel>[];
    const batchSize = 30; // Giới hạn Firestore whereIn

    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      final snap  = await _db
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      results.addAll(
        snap.docs.map((doc) => RecipeModel.fromFirestore(doc.id, doc.data())),
      );
    }

    return results;
  }

  // ── 3. Stream isBought từ grocery_list ───────────────────────────────────

  String _groceryDocId(String userId, DateTime weekStart) {
    final weekId = DateFormat('yyyyMMdd').format(weekStart);
    return '${userId}_$weekId';
  }

  Stream<Map<String, bool>> watchBoughtStatus({
    required String userId,
    required DateTime weekStart,
  }) {
    return _db
        .collection('grocery_list')
        .doc(_groceryDocId(userId, weekStart))
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return <String, bool>{};

      final rawItems  = snap.data()!['items'] as List<dynamic>? ?? [];
      final statusMap = <String, bool>{};

      for (final raw in rawItems) {
        final item = GroceryFirestoreItem.fromMap(
            Map<String, dynamic>.from(raw as Map));
        statusMap['${item.name}__${item.unit}'] = item.isBought;
      }

      return statusMap;
    });
  }

  // ── 4. Lưu toàn bộ grocery list ──────────────────────────────────────────

  Future<void> saveGroceryList({
    required String userId,
    required DateTime weekStart,
    required List<GroceryFirestoreItem> items,
  }) async {
    final docId = _groceryDocId(userId, weekStart);
    await _db.collection('grocery_list').doc(docId).set({
      'user_id':    userId,
      'week_start': DateFormat('yyyy-MM-dd').format(weekStart),
      'items':      items.map((i) => i.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── 5. Toggle 1 item isBought ────────────────────────────────────────────

  Future<void> toggleItemBought({
    required String userId,
    required DateTime weekStart,
    required String itemName,
    required String itemUnit,
    required bool isBought,
  }) async {
    final docRef = _db
        .collection('grocery_list')
        .doc(_groceryDocId(userId, weekStart));

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists || snap.data() == null) return;

      final rawItems = List<Map<String, dynamic>>.from(
        (snap.data()!['items'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final updated = rawItems.map((raw) {
        if (raw['name'] == itemName && raw['unit'] == itemUnit) {
          return {...raw, 'is_bought': isBought};
        }
        return raw;
      }).toList();

      tx.update(docRef, {'items': updated});
    });
  }
}