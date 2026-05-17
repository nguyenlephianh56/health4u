// lib/data/repositories/grocery_repo.dart
//
// Truy xuất Firestore cho tính năng Grocery:
//   1. user_plans  → lấy 7 ngày kế hoạch bữa ăn của user
//   2. recipes     → lấy chi tiết từng recipe theo reference_id
//   3. grocery_list → lưu/đọc trạng thái isBought theo tuần

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/recipe_model.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final groceryRepoProvider = Provider<GroceryRepo>((ref) => GroceryRepo());

// ─── Model: kế hoạch 1 bữa trong user_plans ──────────────────────────────────

class UserPlanEntry {
  final String id;           // document ID
  final String userId;
  final String date;         // YYYY-MM-DD
  final String type;         // "meal" | "workout"
  final String referenceId;  // ID trong collection recipes / workouts
  final bool isCompleted;

  const UserPlanEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.referenceId,
    required this.isCompleted,
  });

  factory UserPlanEntry.fromFirestore(String docId, Map<String, dynamic> data) {
    return UserPlanEntry(
      id:          docId,
      userId:      data['user_id']?.toString() ?? '',
      date:        data['date']?.toString() ?? '',
      type:        data['type']?.toString() ?? 'meal',
      referenceId: data['reference_id']?.toString() ?? '',
      isCompleted: data['is_completed'] == true,
    );
  }
}

// ─── Model: 1 item trong grocery_list.items ──────────────────────────────────

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

  // ── 1. Lấy kế hoạch 7 ngày của user (user_plans) ─────────────────────────

  /// Trả về danh sách UserPlanEntry loại "meal" trong 7 ngày bắt đầu từ [weekStart]
  Future<List<UserPlanEntry>> getMealPlansForWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    final dates = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(d);
    });

    // Firestore không hỗ trợ whereIn trên field khác nên query range ngày
    final snap = await _db
        .collection('user_plans')
        .where('user_id', isEqualTo: userId)
        .where('type', isEqualTo: 'meal')
        .where('date', whereIn: dates)
        .get();

    return snap.docs
        .map((doc) => UserPlanEntry.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // ── 2. Lấy chi tiết recipes theo danh sách ID ────────────────────────────

  /// Batch-fetch recipes theo danh sách referenceId từ user_plans
  Future<List<RecipeModel>> getRecipesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore giới hạn whereIn tối đa 30 phần tử — chia batch nếu cần
    final List<RecipeModel> results = [];
    const batchSize = 30;

    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      final snap = await _db
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      results.addAll(
        snap.docs.map((doc) => RecipeModel.fromFirestore(doc.id, doc.data())),
      );
    }

    return results;
  }

  // ── 3. Đọc grocery_list từ Firestore ─────────────────────────────────────

  /// Document ID theo schema: {userId}_{weekId}
  /// weekId = ngày Thứ 2 đầu tuần format YYYYMMDD
  String _docId(String userId, DateTime weekStart) {
    final weekId = DateFormat('yyyyMMdd').format(weekStart);
    return '${userId}_$weekId';
  }

  /// Stream realtime trạng thái isBought từ Firestore
  Stream<Map<String, bool>> watchBoughtStatus({
    required String userId,
    required DateTime weekStart,
  }) {
    return _db
        .collection('grocery_list')
        .doc(_docId(userId, weekStart))
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return {};

      final rawItems = snap.data()!['items'] as List<dynamic>? ?? [];
      final Map<String, bool> statusMap = {};

      for (final raw in rawItems) {
        final item = GroceryFirestoreItem.fromMap(
            Map<String, dynamic>.from(raw as Map));
        // Key: name__unit để map với AggregatedItem
        statusMap['${item.name}__${item.unit}'] = item.isBought;
      }

      return statusMap;
    });
  }

  // ── 4. Lưu toàn bộ grocery list lên Firestore ────────────────────────────

  /// Ghi toàn bộ items (kèm isBought) lên document grocery_list
  Future<void> saveGroceryList({
    required String userId,
    required DateTime weekStart,
    required List<GroceryFirestoreItem> items,
  }) async {
    final docId = _docId(userId, weekStart);
    await _db.collection('grocery_list').doc(docId).set({
      'user_id':    userId,
      'week_start': DateFormat('yyyy-MM-dd').format(weekStart),
      'items':      items.map((i) => i.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── 5. Toggle 1 item isBought (partial update) ───────────────────────────

  /// Cập nhật nhanh trạng thái isBought của 1 item mà không ghi lại toàn bộ list.
  /// Dùng transaction để tránh race condition khi nhiều thiết bị cùng cập nhật.
  Future<void> toggleItemBought({
    required String userId,
    required DateTime weekStart,
    required String itemName,
    required String itemUnit,
    required bool isBought,
  }) async {
    final docRef = _db
        .collection('grocery_list')
        .doc(_docId(userId, weekStart));

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