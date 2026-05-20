// lib/features/nutrition/views/meal_plan_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_models.dart';
import '../viewmodels/nutrition_viewmodel.dart';
import '../widgets/meal_card.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  final _calCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _buildAnim(fromRight: true);
    _anim.forward();
  }

  void _buildAnim({required bool fromRight}) {
    _slide = Tween<Offset>(
      begin: Offset(fromRight ? 0.5 : -0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.easeOutCubic,
      ),
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.easeOut,
      ),
    );
  }

  void _onDayTap(int newIdx) {
    final cur = ref.read(selectedDayIndexProvider);

    if (newIdx == cur) return;

    _buildAnim(fromRight: newIdx > cur);
    _anim.forward(from: 0);

    ref.read(selectedDayIndexProvider.notifier).state = newIdx;

    _scrollCalendarTo(newIdx);
  }

  void _scrollCalendarTo(int idx) {
    if (!_calCtrl.hasClients) return;

    const itemWidth = 58.0;

    final screenWidth = MediaQuery.of(context).size.width - 60;

    final target =
        (itemWidth * idx) - (screenWidth / 2) + (itemWidth / 2);

    _calCtrl.animateTo(
      target.clamp(0.0, _calCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _changeWeek(int delta) {
    final cur = ref.read(weekStartProvider);

    ref.read(weekStartProvider.notifier).state =
        cur.add(Duration(days: 7 * delta));
  }

  @override
  void dispose() {
    _anim.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final weekStart = ref.read(weekStartProvider);
    await ref.read(nutritionViewModelProvider.notifier).loadWeek(weekStart);
  }

  @override
  Widget build(BuildContext context) {
    final nutritionState = ref.watch(nutritionViewModelProvider);

    final selIdx = ref.watch(selectedDayIndexProvider);

    final selDate = ref.watch(selectedDateProvider);

    final weekStart = ref.watch(weekStartProvider);

    final dayData = nutritionState.dayOf(selDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 20,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                  child: Column(
                    children: [
                      _buildHeader(weekStart),
                      const SizedBox(height: 14),
                      _buildCalendar(selIdx, weekStart),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _buildBody(
                    nutritionState,
                    dayData,
                    selIdx,
                    selDate,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    String fmt(DateTime d) => '${d.day}/${d.month}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kế hoạch bữa ăn',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${fmt(weekStart)} – ${fmt(weekEnd)}/${weekEnd.year}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        _weekNavBtn(
          Icons.chevron_left,
              () => _changeWeek(-1),
        ),
        const SizedBox(width: 4),
        _weekNavBtn(
          Icons.chevron_right,
              () => _changeWeek(1),
        ),
      ],
    );
  }

  Widget _weekNavBtn(
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCalendar(
      int selIdx,
      DateTime weekStart,
      ) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final todayStr =
    DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF0273B0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = math.min(
            (constraints.maxWidth - 36) / 7,
            52.0,
          );

          return Row(
            children: List.generate(7, (i) {
              final date =
              weekStart.add(Duration(days: i));

              final isSelected = i == selIdx;

              final isToday =
                  DateFormat('yyyy-MM-dd').format(date) ==
                      todayStr;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDayTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          names[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 1),

                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),

                        if (isToday) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildBody(
      NutritionState s,
      DayNutrition day,
      int selIdx,
      DateTime selDate,
      ) {
    if (s.isLoading) {
      return Column(
        children: [
          const SizedBox(height: 16),
          _buildDaySummarySkeleton(),
          const SizedBox(height: 12),
          ...List.generate(
            3,
                (_) => _buildCardSkeleton(),
          ),
        ],
      );
    }

    if (s.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              s.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref
                    .read(
                  nutritionViewModelProvider.notifier,
                )
                    .reloadDay(selDate);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            _buildDaySummary(
              day,
              selIdx,
              ref.watch(weekStartProvider),
            ),

            const SizedBox(height: 12),

            if (day.isEmpty)
              _buildEmpty()
            else ...[
              if (day.breakfast.isNotEmpty) ...[
                _mealLabel('🌅 Bữa sáng'),
                ...day.breakfast.map(
                      (e) => _buildMealCard(e, selDate),
                ),
                const SizedBox(height: 4),
              ],

              if (day.lunch.isNotEmpty) ...[
                _mealLabel('☀️ Bữa trưa'),
                ...day.lunch.map(
                      (e) => _buildMealCard(e, selDate),
                ),
                const SizedBox(height: 4),
              ],

              if (day.dinner.isNotEmpty) ...[
                _mealLabel('🌙 Bữa tối'),
                ...day.dinner.map(
                      (e) => _buildMealCard(e, selDate),
                ),
                const SizedBox(height: 4),
              ],

              if (day.snack.isNotEmpty) ...[
                _mealLabel('🍎 Bữa phụ'),
                ...day.snack.map(
                      (e) => _buildMealCard(e, selDate),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary(
      DayNutrition day,
      int idx,
      DateTime weekStart,
      ) {
    const dayNames = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
      'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
    ];

    final date = weekStart.add(Duration(days: idx));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD9EAF8),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    dayNames[idx],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    '${day.totalKcal}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'tổng kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _macroTile(
                '${day.totalProtein}g',
                'Đạm',
                const Color(0xFF4285F4),
              ),
              const SizedBox(width: 10),
              _macroTile(
                '${day.totalCarbs}g',
                'Tinh bột',
                const Color(0xFFF9A825),
              ),
              const SizedBox(width: 10),
              _macroTile(
                '${day.totalFat}g',
                'Chất béo',
                const Color(0xFFEA4335),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroTile(
      String val,
      String label,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius:
          BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(
      MealEntry entry,
      DateTime date,
      ) {
    return MealCard(
      meal: entry.toCardMap(),
    );
  }

  Widget _mealLabel(String t) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
        top: 2,
      ),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có kế hoạch bữa ăn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ngày này chưa được lên thực đơn',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummarySkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD9EAF8),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              _shimmer(width: 100, height: 18),
              _shimmer(width: 60, height: 28),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _shimmer(height: 40)),
              const SizedBox(width: 10),
              Expanded(child: _shimmer(height: 40)),
              const SizedBox(width: 10),
              Expanded(child: _shimmer(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD9EAF8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _shimmer(width: 78, height: 64, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  _shimmer(width: 140, height: 14),
                  const SizedBox(height: 8),
                  _shimmer(width: 100, height: 12),
                  const SizedBox(height: 8),
                  _shimmer(width: 80, height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer({
    double? width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius:
        BorderRadius.circular(radius),
      ),
    );
  }
}