// lib/features/nutrition/views/meal_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/recipe_model.dart';
import '../viewmodels/nutrition_viewmodel.dart';
import '../widgets/meal_card.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final ScrollController _calendarScrollController = ScrollController();
  static const double _itemWidth = 58.0;
  bool _slideFromRight = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _buildAnimations(fromRight: true);
    _animController.forward();
  }

  void _buildAnimations({required bool fromRight}) {
    _slideAnimation = Tween<Offset>(
      begin: Offset(fromRight ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  void _onDaySelected(int newIndex) {
    final currentIndex = ref.read(selectedDayIndexProvider);
    if (newIndex == currentIndex) return;

    _slideFromRight = newIndex > currentIndex;
    _buildAnimations(fromRight: _slideFromRight);
    _animController.forward(from: 0);
    ref.read(selectedDayIndexProvider.notifier).state = newIndex;
    _scrollCalendarTo(newIndex);
  }

  void _scrollCalendarTo(int index) {
    final screenWidth = MediaQuery.of(context).size.width - 60;
    final targetOffset =
        (_itemWidth * index) - (screenWidth / 2) + (_itemWidth / 2);
    _calendarScrollController.animateTo(
      targetOffset.clamp(
          0.0, _calendarScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nutritionState = ref.watch(nutritionViewModelProvider);
    final selectedIndex  = ref.watch(selectedDayIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header xanh ──────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                padding:
                const EdgeInsets.fromLTRB(20, 25, 20, 12),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildCalendar(selectedIndex),
                  ],
                ),
              ),

              // ── Loading ───────────────────────────────────────────────────
              if (nutritionState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
              // ── Nội dung với hiệu ứng ────────────────────────────────
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        children: [
                          _buildDailySummary(nutritionState, selectedIndex),
                          const SizedBox(height: 8),

                          // ── Breakfast ───────────────────────────────────────
                          if (nutritionState.breakfast.isNotEmpty) ...[
                            ...nutritionState.breakfast.map(
                                  (r) => MealCard(
                                meal: _recipeToMap(r),
                                onSwapTap: () {},
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // ── Lunch ───────────────────────────────────────────
                          if (nutritionState.lunch.isNotEmpty) ...[
                            ...nutritionState.lunch.map(
                                  (r) => MealCard(
                                meal: _recipeToMap(r),
                                onSwapTap: () {},
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // ── Dinner ──────────────────────────────────────────
                          if (nutritionState.dinner.isNotEmpty) ...[
                            ...nutritionState.dinner.map(
                                  (r) => MealCard(
                                meal: _recipeToMap(r),
                                onSwapTap: () {},
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // ── Snack ───────────────────────────────────────────
                          if (nutritionState.snack.isNotEmpty) ...[
                            ...nutritionState.snack.map(
                                  (r) => MealCard(
                                meal: _recipeToMap(r),
                                onSwapTap: () {},
                              ),
                            ),
                          ],

                          // ── Empty state ─────────────────────────────────────
                          if (nutritionState.allMeals.isEmpty)
                            _buildEmptyState(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Chuyển RecipeModel → Map để MealCard dùng
  Map<String, dynamic> _recipeToMap(RecipeModel r) => {
    'type':         r.mealType.toUpperCase(),
    'name':         r.name,
    'cal':          r.nutrition.calories.round(),
    'time':         '${r.prepTimeMin}m',
    'protein':      '${r.nutrition.protein.round()}g',
    'carb':         '${r.nutrition.carbs.round()}g',
    'fat':          '${r.nutrition.fat.round()}g',
    'image':        r.imageUrl,
    'instructions': r.instructions,
    'ingredients':  r.ingredients.map((i) => i.toMap()).toList(),
  };

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kế hoạch bữa ăn tuần',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tuần 3/5',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  // ── Lịch ngày (real-time theo tuần hiện tại) ────────────────────────────
  Widget _buildCalendar(int selectedIndex) {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final days = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return {'day': dayNames[i], 'date': '${d.day}'};
    });
    final todayIndex = now.weekday - 1; // 0=T2 ... 6=CN

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0273B0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final isToday    = index == todayIndex;

          return GestureDetector(
            onTap: () => _onDaySelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 50,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRect(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      days[index]['day']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days[index]['date']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 3),
                      CircleAvatar(
                        radius: 2,
                        backgroundColor:
                        isSelected ? AppColors.primary : Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tổng quan dinh dưỡng ──────────────────────────────────────────────────
  Widget _buildDailySummary(NutritionState state, int selectedIndex) {
    final daysOfWeek = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
      'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];
    // Real-time: tính ngày thực tế của tuần hiện tại
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dates  = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return '${d.day}/${d.month}';
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daysOfWeek[selectedIndex],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dates[selectedIndex],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.totalKcal.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'tổng kcal',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroCard('${state.protein}g', 'Đạm',
                  const Color(0xFF4285F4)),
              const SizedBox(width: 10),
              _buildMacroCard('${state.carbs}g', 'Tinh bột',
                  const Color(0xFFF9A825)),
              const SizedBox(width: 10),
              _buildMacroCard('${state.fat}g', 'Chất béo',
                  const Color(0xFFEA4335)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có món ăn nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Admin hãy thêm món ăn vào hệ thống',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}