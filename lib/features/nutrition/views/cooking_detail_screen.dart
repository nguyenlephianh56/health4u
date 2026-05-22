// lib/features/nutrition/views/cooking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../viewmodels/cooking_detail_viewmodel.dart';
import '../widgets/cooking_detail_widgets.dart';
import '../../../data/services/gamification_service.dart';
import '../../gamification/viewmodels/discipline_viewmodel.dart';

// ── Screen ────────────────────────────────────────────────────────────────────
class CookingDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> meal;

  const CookingDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeId    = meal['id']?.toString() ?? '';
    final selectedTab = ref.watch(selectedTabProvider);

    final alreadyCompleted = meal['is_completed'] as bool? ?? false;
    final justEaten        = ref.watch(eatenProvider(recipeId));
    final isEaten          = alreadyCompleted || justEaten;

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

    final List<String> tips = (meal['tips'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        _autoTips(protein, carb);

    final String healthNote =
        'Món này chứa $protein đạm hỗ trợ duy trì cơ bắp '
        'và $carb tinh bột cung cấp năng lượng bền vững suốt cả ngày.';

    return Scaffold(
      backgroundColor: const Color(0xFFDDF0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                    NutritionRow(
                      calories: '$calories',
                      protein: protein.replaceAll('g', ''),
                      carbs: carb.replaceAll('g', ''),
                      fat: fat.replaceAll('g', ''),
                    ),
                    const SizedBox(height: 14),

                    MarkEatenButton(
                      isEaten: isEaten,
                      onTap: () async {
                        if (isEaten) return;
                        // Optimistic update UI ngay
                        ref.read(eatenProvider(recipeId).notifier).state = true;
                        await _markCompleted(context, ref, calories: calories);
                      },
                    ),
                    const SizedBox(height: 14),

                    CookingTabBar(
                      selectedTab: selectedTab,
                      onTabChanged: (i) =>
                      ref.read(selectedTabProvider.notifier).state = i,
                    ),
                    const SizedBox(height: 14),

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

  Future<void> _markCompleted(
      BuildContext context,
      WidgetRef ref, {
        required int calories,
      }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final db      = FirebaseFirestore.instance;
      final dateStr = meal['date']?.toString() ??
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docId   = '${uid}_$dateStr';

      final String rawType    = meal['type']?.toString() ?? 'Breakfast';
      final String mealTypeKey = rawType.isNotEmpty
          ? '${rawType[0].toUpperCase()}${rawType.substring(1).toLowerCase()}'
          : 'Breakfast';

      // 1. Ghi user_plans và daily_tracking (không ghi điểm ở đây)
      final batch = db.batch();

      batch.update(
        db.collection('user_plans').doc(docId),
        {'meals.$mealTypeKey.is_completed': true},
      );

      batch.set(
        db.collection('daily_tracking').doc(docId),
        {
          'consumed_kcal':    FieldValue.increment(calories),
          'meals_completed':  FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // 2. Gọi GamificationService SAU KHI Firestore ghi xong
      //    Service tự đọc lại doc → kiểm tra isDayFullyDone → cộng điểm + streak
      final date   = DateTime.parse(dateStr);
      final result = await GamificationService().onMealToggled(
        isCompleting: true,
        date: date,
      );

      // 3. Trigger animation điểm
      if (result != null && result.pointsDelta != 0) {
        ref
            .read(disciplineViewModelProvider.notifier)
            .showPointsDelta(result.pointsDelta);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Đã đánh dấu hoàn thành và nhận +10 điểm!'),
            backgroundColor: const Color(0xFF0D86CF),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ CookingDetail._markCompleted error: $e');
    }
  }

  List<String> _autoTips(String protein, String carb) => [
    'Nhai chậm và thưởng thức từng miếng để cảm nhận vị ngon trọn vẹn.',
    'Ăn kèm rau xanh để bổ sung thêm chất xơ và vitamin.',
    'Uống đủ nước trong suốt bữa ăn để hỗ trợ tiêu hóa tốt hơn.',
  ];
}