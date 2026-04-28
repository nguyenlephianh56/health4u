// lib/data/repositories/admin_repo.dart
//
// Mô tả: Repository xử lý toàn bộ logic Firestore cho Admin.
// Bao gồm: thống kê (recipes/workouts/users count) + CRUD recipes.
//
// Được gọi từ: features/admin/viewmodels/admin_viewmodel.dart
// KHÔNG import Widget nào của Flutter UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_model.dart';

// ─── Provider ────────────────────────────────────────────────────────────────
final adminRepoProvider = Provider<AdminRepo>((ref) => AdminRepo());

class AdminRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Thống kê tổng quan ───────────────────────────────────────────────────

  /// Lấy số lượng documents trong 1 collection
  Future<int> getCount(String collection) async {
    final snap = await _db.collection(collection).count().get();
    return snap.count ?? 0;
  }

  /// Lấy cả 3 số cùng lúc (dùng Future.wait để song song)
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

  /// Lấy danh sách tất cả recipes (realtime stream)
  Stream<List<RecipeModel>> watchRecipes() {
    return _db
        .collection('recipes')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => RecipeModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  /// Thêm recipe mới
  Future<void> addRecipe(RecipeModel recipe) async {
    await _db.collection('recipes').add(recipe.toFirestore());
  }

  /// Cập nhật recipe đã có
  Future<void> updateRecipe(RecipeModel recipe) async {
    await _db
        .collection('recipes')
        .doc(recipe.id)
        .update(recipe.toFirestore());
  }

  /// Xóa recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _db.collection('recipes').doc(recipeId).delete();
  }
}