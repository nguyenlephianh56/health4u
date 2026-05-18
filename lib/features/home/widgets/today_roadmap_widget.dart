// lib/features/home/widgets/today_roadmap_widget.dart
//
// Widget lộ trình hôm nay — lấy data từ user_plans Firestore
// Hiển thị 4 bữa ăn + 1 bài tập theo timeline
// Mỗi bữa hiển thị: tên, calo, protein, carbs, chất béo
// Bấm "Xem tất cả" → chuyển sang tab /meals

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';

// ── Model nhỏ cho từng item trong roadmap ────────────────────────────────────
class _RoadmapItem {
  final String type;       // 'meal' | 'workout'
  final String label;      // 'Bữa sáng' | 'Tập luyện'
  final String name;
  final int    calories;
  final String emoji;
  final double? protein;
  final double? carbs;
  final double? fat;
  // Workout only
  final int?    durationMin;
  final String? difficulty;
  final String? muscleGroup;

  const _RoadmapItem({
    required this.type,
    required this.label,
    required this.name,
    required this.calories,
    required this.emoji,
    this.protein,
    this.carbs,
    this.fat,
    this.durationMin,
    this.difficulty,
    this.muscleGroup,
  });
}

// ── Provider fetch user_plans hôm nay ───────────────────────────────────────
final todayRoadmapProvider = FutureProvider<List<_RoadmapItem>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final doc = await FirebaseFirestore.instance
      .collection('user_plans')
      .doc('${uid}_$today')
      .get();

  if (!doc.exists || doc.data() == null) return [];

  final data  = doc.data()!;
  final items = <_RoadmapItem>[];

  // Thứ tự bữa ăn
  const mealOrder = [
    ('Breakfast', 'Bữa sáng', '🍳'),
    ('Lunch',     'Bữa trưa', '🌤️'),
    ('Snack',     'Bữa phụ',  '🍎'),
    ('Dinner',    'Bữa tối',  '🌙'),
  ];

  final meals = (data['meals'] as Map<String, dynamic>?) ?? {};
  for (final (key, label, emoji) in mealOrder) {
    final meal = meals[key] as Map<String, dynamic>?;
    items.add(_RoadmapItem(
      type:     'meal',
      label:    label,
      name:     meal?['name']?.toString() ?? '—',
      calories: (meal?['calories'] as num?)?.toInt() ?? 0,
      emoji:    emoji,
      protein:  (meal?['protein']  as num?)?.toDouble(),
      carbs:    (meal?['carbs']    as num?)?.toDouble(),
      fat:      (meal?['fat']      as num?)?.toDouble(),
    ));
  }

  // Bài tập
  final workout = data['workout'] as Map<String, dynamic>?;
  if (workout != null) {
    items.add(_RoadmapItem(
      type:        'workout',
      label:       'Tập luyện',
      name:        workout['title']?.toString() ?? '—',
      calories:    (workout['calories_burned'] as num?)?.toInt() ?? 0,
      emoji:       '🏋️',
      durationMin: (workout['duration_min']    as num?)?.toInt(),
      difficulty:  workout['difficulty']?.toString(),
      muscleGroup: workout['muscle_group']?.toString(),
    ));
  }

  return items;
});

// ── Widget ───────────────────────────────────────────────────────────────────
class TodayRoadmapWidget extends ConsumerWidget {
  const TodayRoadmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayRoadmapProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                'Lộ trình hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go(AppRoutes.meals),
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Content ─────────────────────────────────────────────────
          async.when(
            loading: () => _buildSkeleton(),
            error:   (_, __) => _buildEmpty('Không thể tải lộ trình'),
            data:    (items) => items.isEmpty
                ? _buildEmpty('Chưa có lộ trình hôm nay')
                : _buildTimeline(items),
          ),
        ],
      ),
    );
  }

  // ── Timeline ─────────────────────────────────────────────────────────────
  Widget _buildTimeline(List<_RoadmapItem> items) {
    return Column(
      children: List.generate(items.length, (i) {
        final item      = items[i];
        final isLast    = i == items.length - 1;
        final isWorkout = item.type == 'workout';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cột timeline trái ──────────────────────────────────
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isWorkout
                            ? const Color(0xFFF59E0B).withOpacity(0.12)
                            : AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: Colors.black.withOpacity(0.07),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Nội dung bên phải ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                    bottom: isLast ? 0 : 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: isWorkout
                        ? _buildWorkoutContent(item)
                        : _buildMealContent(item),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Meal card content ────────────────────────────────────────────────────
  Widget _buildMealContent(_RoadmapItem item) {
    final hasData = item.protein != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + tên + calo
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Kcal badge
            if (item.calories > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.calories} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),

        // Macro row
        if (hasData) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroCell(
                value: '${item.protein!.toStringAsFixed(0)}g',
                label: 'Protein',
                color: const Color(0xFF3B82F6),
              ),
              _buildMacroDivider(),
              _buildMacroCell(
                value: '${item.carbs!.toStringAsFixed(0)}g',
                label: 'Carbs',
                color: const Color(0xFF10B981),
              ),
              _buildMacroDivider(),
              _buildMacroCell(
                value: '${item.fat!.toStringAsFixed(0)}g',
                label: 'Chất béo',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Workout card content ─────────────────────────────────────────────────
  Widget _buildWorkoutContent(_RoadmapItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Calories burned badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '-${item.calories} kcal',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        // Workout meta info
        if (item.durationMin != null || item.difficulty != null) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (item.durationMin != null)
                _buildWorkoutTag('⏱ ${item.durationMin} phút'),
              if (item.difficulty != null)
                _buildWorkoutTag('🎯 ${item.difficulty}'),
              if (item.muscleGroup != null)
                _buildWorkoutTag('💪 ${item.muscleGroup}'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMacroCell({
    required String value,
    required String label,
    required Color  color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDivider() => Container(
    width: 1,
    height: 28,
    color: Colors.black.withOpacity(0.07),
  );

  Widget _buildWorkoutTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.black.withOpacity(0.55),
        ),
      ),
    );
  }

  // ── Skeleton loading ─────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Column(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            _bone(36, 36, radius: 18),
            const SizedBox(width: 12),
            Expanded(child: _bone(double.infinity, 64)),
          ],
        ),
      )),
    );
  }

  Widget _buildEmpty(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            msg,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bone(double w, double h, {double radius = 8}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.07),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}