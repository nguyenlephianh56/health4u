// lib/features/nutrition/views/cooking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../viewmodels/cooking_detail_viewmodel.dart';
import '../widgets/cooking_detail_widgets.dart';

// ── Screen ────────────────────────────────────────────────────────────────────
class CookingDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> meal;

  const CookingDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeId    = meal['id']?.toString() ?? '';
    final selectedTab = ref.watch(selectedTabProvider);

    // is_completed từ Firestore (qua MealEntry.toCardMap) là source of truth.
    // eatenProvider chỉ để phản hồi ngay khi user vừa bấm trong session này.
    final alreadyCompleted = meal['is_completed'] as bool? ?? false;
    final justEaten        = ref.watch(eatenProvider(recipeId));
    final isEaten          = alreadyCompleted || justEaten;

    // ── Parse data từ RecipeModel (qua _recipeToMap) ──────────────────────
    final String name      = meal['name']?.toString() ?? '';
    final String imageUrl  = meal['image']?.toString() ?? '';
    final String prepTime  = meal['time']?.toString() ?? '0m';
    final int    calories  = (meal['cal'] as num?)?.toInt() ?? 0;
    final String protein   = meal['protein']?.toString() ?? '0g';
    final String carb      = meal['carb']?.toString() ?? '0g';
    final String fat       = meal['fat']?.toString() ?? '0g';

    final List<String> tags = (meal['tags'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    final List<Map<String, dynamic>> ingredients =
        (meal['ingredients'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
            [];

    final List<String> instructions = (meal['instructions'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    // Tạo tips tự động từ nutrition nếu không có
    final List<String> tips = (meal['tips'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        _autoTips(protein, carb);

    // Ghi chú sức khỏe tự động
    final String healthNote =
        'Món này chứa $protein đạm hỗ trợ duy trì cơ bắp '
        'và $carb tinh bột cung cấp năng lượng bền vững suốt cả ngày.';

    return Scaffold(
      backgroundColor: const Color(0xFFDDF0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Ảnh + tiêu đề ─────────────────────────────────────────
              HeaderSection(
                imageUrl: imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
                title: name,
                prepTime: '$prepTime thời gian chuẩn bị',
                tags: tags,
                onBack: () => Navigator.pop(context),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  children: [
                    // ── Dinh dưỡng ───────────────────────────────────────
                    NutritionRow(
                      calories: '$calories',
                      protein: protein.replaceAll('g', ''),
                      carbs: carb.replaceAll('g', ''),
                      fat: fat.replaceAll('g', ''),
                    ),
                    const SizedBox(height: 14),

                    // ── Nút đã ăn ────────────────────────────────────────
                    MarkEatenButton(
                      isEaten: isEaten,
                      onTap: () async {
                        if (isEaten) return;
                        ref.read(eatenProvider(recipeId).notifier).state = true;
                        await _markCompletedInFirestore(context, calories: calories);
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Tab bar ──────────────────────────────────────────
                    CookingTabBar(
                      selectedTab: selectedTab,
                      onTabChanged: (i) =>
                      ref.read(selectedTabProvider.notifier).state = i,
                    ),
                    const SizedBox(height: 14),

                    // ── Nội dung tab ─────────────────────────────────────
                    if (selectedTab == 0)
                      IngredientsTab(ingredients: ingredients),

                    if (selectedTab == 1)
                      StepsTab(steps: instructions),

                    if (selectedTab == 2)
                      TipsTab(tips: tips, healthNote: healthNote),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cập nhật Firebase: user_plans, daily_tracking và users
  Future<void> _markCompletedInFirestore(BuildContext context, {required int calories}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Ngày và docId
      final String dateStr = meal['date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String docId = '${uid}_$dateStr';

      // 2. Loại bữa ăn
      final String rawType = meal['type']?.toString() ?? 'Breakfast';
      final String mealTypeKey = rawType.isNotEmpty
          ? '${rawType[0].toUpperCase()}${rawType.substring(1).toLowerCase()}'
          : 'Breakfast';

      // 3. Update user_plans
      final userPlansRef = db.collection('user_plans').doc(docId);
      batch.update(userPlansRef, {'meals.$mealTypeKey.is_completed': true});

      // 4. Update daily_tracking
      final dailyTrackingRef = db.collection('daily_tracking').doc(docId);
      batch.set(
        dailyTrackingRef,
        {
          'consumed_kcal': FieldValue.increment(calories),
          'meals_completed': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      // 5. Update users điểm
      final userRef = db.collection('users').doc(uid);
      batch.update(userRef, {'total_points': FieldValue.increment(10)});

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Đã đánh dấu hoàn thành và nhận +10 điểm!'),
            backgroundColor: const Color(0xFF0D86CF),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ LỖI FIREBASE: $e");
    }
  }

  // Tips tự động nếu Firestore chưa có field 'tips'
  List<String> _autoTips(String protein, String carb) => [
    'Nhai chậm và thưởng thức từng miếng để cảm nhận vị ngon trọn vẹn.',
    'Ăn kèm rau xanh để bổ sung thêm chất xơ và vitamin.',
    'Uống đủ nước trong suốt bữa ăn để hỗ trợ tiêu hóa tốt hơn.',
  ];
}