import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../viewmodels/nutrition_viewmodel.dart';
import '../widgets/meal_card.dart';
import '../widgets/nutrition_label.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  final ScrollController _calendarScrollController = ScrollController();
  int _previousSelectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Mỗi lần mở màn hình, tự chọn đúng ngày hiện tại (T2..CN => 0..6)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now().toLocal();
      final todayIndex = (now.weekday - 1).clamp(0, 6);
      _previousSelectedIndex = todayIndex;
      ref.read(selectedDayIndexProvider.notifier).state = todayIndex;
      _scrollToSelectedDay(todayIndex);
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay(int selectedIndex) {
    if (!_calendarScrollController.hasClients) return;

    const double itemWidth = 58; // width 50 + margin ngang (4 * 2)
    final double viewportWidth = _calendarScrollController.position.viewportDimension;

    final double targetOffset =
        (selectedIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);

    final double maxScroll = _calendarScrollController.position.maxScrollExtent;
    final double safeOffset = targetOffset.clamp(0.0, maxScroll);

    _calendarScrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutritionState = ref.watch(nutritionViewModelProvider);
    final selectedIndex = ref.watch(selectedDayIndexProvider);

    // Lấy đầu tuần theo thứ 2 (real-time theo ngày hiện tại)
    final now = DateTime.now().toLocal();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    _buildHeader(weekStart),
                    const SizedBox(height: 25),
                    _buildCalendar(ref, selectedIndex, weekStart),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final currentIndex = (child.key as ValueKey<int>).value;
                  final isForward = currentIndex > _previousSelectedIndex;

                  final inBegin =
                  isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
                  final outEnd =
                  isForward ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);

                  final inSlide = Tween<Offset>(
                    begin: inBegin,
                    end: Offset.zero,
                  ).animate(animation);

                  final outSlide = Tween<Offset>(
                    begin: Offset.zero,
                    end: outEnd,
                  ).animate(animation);

                  final isIncoming = currentIndex == selectedIndex;

                  return ClipRect(
                    child: SlideTransition(
                      position: isIncoming ? inSlide : outSlide,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(selectedIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        _buildDailySummary(nutritionState, selectedIndex, weekStart),
                        const SizedBox(height: 20),
                        ...nutritionState.meals.map(
                              (meal) => MealCard(
                            meal: meal,
                            onSwapTap: () {
                              // Logic đổi món
                            },
                          ),
                        ),
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

  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }

  Widget _buildHeader(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kế hoạch bữa ăn tuần',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tuần từ ${_formatDate(weekStart)} đến ${_formatDate(weekEnd)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar(WidgetRef ref, int selectedIndex, DateTime weekStart) {
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final days = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      return {
        'day': dayLabels[index],
        'date': date.day.toString(),
      };
    });

    final now = DateTime.now().toLocal();
    final isSameDate = (DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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
          final currentDate = weekStart.add(Duration(days: index));
          final isToday = isSameDate(currentDate, now);

          return GestureDetector(
            onTap: () {
              if (index == selectedIndex) return;
              _previousSelectedIndex = selectedIndex;
              ref.read(selectedDayIndexProvider.notifier).state = index;
              _scrollToSelectedDay(index);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index]['day']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index]['date']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    CircleAvatar(
                      radius: 2.5,
                      backgroundColor: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySummary(dynamic nutritionState, int selectedIndex, DateTime weekStart) {
    final daysOfWeek = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];

    final currentDate = weekStart.add(Duration(days: selectedIndex));
    final currentDayName = daysOfWeek[selectedIndex];
    final currentDateText = _formatDate(currentDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentDayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentDateText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nutritionState.totalKcal.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tổng kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroCard('${nutritionState.protein}g', 'Đạm', const Color(0xFF4285F4)),
              const SizedBox(width: 10),
              _buildMacroCard('${nutritionState.carbs}g', 'Tinh bột', const Color(0xFFF9A825)),
              const SizedBox(width: 10),
              _buildMacroCard('${nutritionState.fat}g', 'Chất béo', const Color(0xFFEA4335)),
            ],
          )
        ],
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}