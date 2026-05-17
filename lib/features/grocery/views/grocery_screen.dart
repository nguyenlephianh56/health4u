// lib/features/grocery/views/grocery_screen.dart
//
// Màn hình Smart Grocery List
// Data source: user_plans 7 ngày → recipes → gom nguyên liệu
// isBought sync realtime qua grocery_list collection (Firestore)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/recipe_model.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/grocery_viewmodel.dart';
import '../viewmodels/grocery_state.dart';
import '../widgets/grocery_category_section.dart';
import '../widgets/grocery_category_config.dart';

class GroceryScreen extends ConsumerWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groceryViewModelProvider);
    final vm    = ref.read(groceryViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header xanh ────────────────────────────────────────────────
            _GroceryHeader(
              state:             state,
              onCategoryChanged: vm.setCategory,
              onReset:           vm.resetAll,
              onPreviousWeek:    vm.previousWeek,
              onNextWeek:        vm.nextWeek,
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(child: _GroceryBody(state: state, vm: vm)),
          ],
        ),
      ),
    );
  }
}

// ─── Body (Loading / Error / Empty / List) ────────────────────────────────────

class _GroceryBody extends StatelessWidget {
  final GroceryState state;
  final GroceryViewModel vm;

  const _GroceryBody({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    // Loading
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error
    if (state.status == GroceryStatus.error) {
      return _ErrorState(
        message: state.errorMessage ?? 'Đã xảy ra lỗi.',
        onRetry: () => vm.loadWeek(state.weekStart),
      );
    }

    // Không có kế hoạch nào trong tuần
    if (state.items.isEmpty) {
      return _EmptyState(
        weekStart: state.weekStart,
        selected:  state.selectedCategory,
      );
    }

    // Không có item nào khớp filter
    if (state.filteredItems.isEmpty) {
      return _EmptyState(
        weekStart: null,
        selected:  state.selectedCategory,
      );
    }

    // Danh sách
    return _GroceryList(
      items:    state.filteredItems,
      onToggle: vm.toggleItem,
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _GroceryHeader extends StatelessWidget {
  final GroceryState state;
  final ValueChanged<IngredientCategory?> onCategoryChanged;
  final VoidCallback onReset;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const _GroceryHeader({
    required this.state,
    required this.onCategoryChanged,
    required this.onReset,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd    = state.weekStart.add(const Duration(days: 6));
    final fmt        = DateFormat('dd/MM');
    final weekLabel  = '${fmt.format(state.weekStart)} – ${fmt.format(weekEnd)}';
    final mealCount  = state.items.fold<int>(0, (s, i) => s + i.mealCount);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Tiêu đề + action buttons ─────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh Sách Đi Chợ',
                      style: TextStyle(
                        color:       Colors.white,
                        fontSize:    22,
                        fontWeight:  FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconBtn(
                icon:    Icons.refresh_rounded,
                onTap:   onReset,
                tooltip: 'Reset tất cả',
              ),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon:    Icons.ios_share_rounded,
                onTap:   () {},
                tooltip: 'Chia sẻ danh sách',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Week navigator ─────────────────────────────────────────
          Row(
            children: [
              // Nút tuần trước
              GestureDetector(
                onTap: onPreviousWeek,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekLabel,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$mealCount bữa ăn trong tuần',
                      style: const TextStyle(
                        color:    Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Nút tuần sau
              GestureDetector(
                onTap: onNextWeek,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Row 3: Progress bar ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ mua sắm',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${state.boughtItems}/${state.totalItems} mặt hàng',
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.totalItems == 0
                  ? 0
                  : state.boughtItems / state.totalItems,
              backgroundColor: Colors.white24,
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          // ── Row 4: Filter chips ───────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label:      'Tất cả',
                  emoji:      null,
                  isSelected: state.selectedCategory == null,
                  onTap:      () => onCategoryChanged(null),
                ),
                const SizedBox(width: 8),
                ...GroceryCategoryConfig.all.map((cat) {
                  final info = GroceryCategoryConfig.of(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label:      info.label,
                      emoji:      info.emoji,
                      isSelected: state.selectedCategory == cat,
                      onTap: () => onCategoryChanged(
                        state.selectedCategory == cat ? null : cat,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header icon button ───────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color:      isSelected ? AppColors.primary : Colors.white,
                fontSize:   13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grocery List (nhóm theo category) ───────────────────────────────────────

class _GroceryList extends StatelessWidget {
  final List<AggregatedItem> items;
  final void Function(String name, String unit) onToggle;

  const _GroceryList({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final Map<IngredientCategory, List<AggregatedItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final categories = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return ListView.builder(
      padding:     const EdgeInsets.only(top: 16, bottom: 32),
      itemCount:   categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return GroceryCategorySection(
          category: cat,
          items:    grouped[cat]!,
          onToggle: onToggle,
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final DateTime? weekStart;
  final IngredientCategory? selected;

  const _EmptyState({this.weekStart, this.selected});

  @override
  Widget build(BuildContext context) {
    final info = selected != null ? GroceryCategoryConfig.of(selected!) : null;

    final String emoji;
    final String msg;

    if (info != null) {
      emoji = info.emoji;
      msg   = 'Không có nguyên liệu\ntrong nhóm "${info.label}"';
    } else if (weekStart != null) {
      final fmt      = DateFormat('dd/MM');
      final weekEnd  = weekStart!.add(const Duration(days: 6));
      emoji = '📅';
      msg   = 'Chưa có kế hoạch bữa ăn\ntuần ${fmt.format(weekStart!)} – ${fmt.format(weekEnd)}.\n\nHãy thêm bữa ăn ở trang Dinh dưỡng.';
    } else {
      emoji = '🛒';
      msg   = 'Chưa có nguyên liệu nào.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:  Colors.black45,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:    Colors.black54,
                fontSize: 15,
                height:   1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}