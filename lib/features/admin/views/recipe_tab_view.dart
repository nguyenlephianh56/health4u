// lib/features/admin/views/recipe_tab_view.dart
//
// Tab Recipes: thanh tìm kiếm + bộ lọc theo buổi + nút Add + danh sách + sửa + xóa

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_state.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../widgets/recipe_list_item.dart';
import '../widgets/recipe_form_dialog.dart';
import '../../../data/models/recipe_model.dart';

class RecipeTabView extends StatefulWidget {
  final AdminState state;
  final AdminViewModel vm;

  const RecipeTabView({
    super.key,
    required this.state,
    required this.vm,
  });

  @override
  State<RecipeTabView> createState() => _RecipeTabViewState();
}

class _RecipeTabViewState extends State<RecipeTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMealType; // null = "Tất cả"

  static const List<_MealFilter> _mealFilters = [
    _MealFilter(label: 'Tất cả',   value: null,        icon: Icons.restaurant_menu_rounded),
    _MealFilter(label: 'Sáng',     value: 'Breakfast', icon: Icons.wb_sunny_rounded),
    _MealFilter(label: 'Trưa',     value: 'Lunch',     icon: Icons.light_mode_rounded),
    _MealFilter(label: 'Tối',      value: 'Dinner',    icon: Icons.nights_stay_rounded),
    _MealFilter(label: 'Bữa phụ',  value: 'Snack',     icon: Icons.cookie_rounded),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecipeModel> get _filteredRecipes {
    return widget.state.recipes.where((recipe) {
      // Lọc theo buổi ăn
      final matchMeal = _selectedMealType == null ||
          recipe.mealType == _selectedMealType;

      // Lọc theo tên (không phân biệt hoa thường, có dấu)
      final query = _searchQuery.trim().toLowerCase();
      final matchSearch = query.isEmpty ||
          recipe.name.toLowerCase().contains(query);

      return matchMeal && matchSearch;
    }).toList();
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RecipeFormDialog(
        recipe: null,
        onSave: (recipe) => widget.vm.addRecipe(recipe),
      ),
    );
  }

  void _openEditDialog(RecipeModel recipe) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RecipeFormDialog(
        recipe: recipe,
        onSave: (updated) => widget.vm.updateRecipe(updated),
      ),
    );
  }

  void _confirmDelete(RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa món ăn?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa "${recipe.name}" không?\nHành động này không thể hoàn tác.',
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.vm.deleteRecipe(recipe.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecipes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Nút Add ───────────────────────────────────────────────────────────
        _AddBtn(
          label: 'Thêm công thức mới',
          onTap: _openAddDialog,
        ),
        const SizedBox(height: 16),

        // ── Thanh tìm kiếm ────────────────────────────────────────────────────
        _SearchBar(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
        const SizedBox(height: 12),

        // ── Bộ lọc buổi ăn ───────────────────────────────────────────────────
        _MealFilterChips(
          filters: _mealFilters,
          selected: _selectedMealType,
          onSelected: (value) => setState(() => _selectedMealType = value),
        ),
        const SizedBox(height: 16),

        // ── Danh sách / trạng thái rỗng ───────────────────────────────────────
        if (widget.state.recipes.isEmpty)
          const _EmptyState(
            icon: Icons.menu_book_rounded,
            message: 'Chưa có món ăn nào.\nBấm "Thêm công thức mới" để thêm!',
          )
        else if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.search_off_rounded,
            message: _searchQuery.isNotEmpty
                ? 'Không có món ăn nào khớp với\n"$_searchQuery"'
                : 'Không có món ăn nào trong công thức\ncho buổi này.',
          )
        else
          ...filtered.map(
                (recipe) => RecipeListItem(
              recipe: recipe,
              onEdit:   () => _openEditDialog(recipe),
              onDelete: () => _confirmDelete(recipe),
            ),
          ),
      ],
    );
  }
}

// ── Thanh tìm kiếm ────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm món ăn...',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.35),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.black.withOpacity(0.4),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close_rounded,
              color: Colors.black.withOpacity(0.4),
              size: 18,
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Model cho mỗi chip lọc ────────────────────────────────────────────────────
class _MealFilter {
  final String label;
  final String? value; // null = tất cả
  final IconData icon;

  const _MealFilter({
    required this.label,
    required this.value,
    required this.icon,
  });
}

// ── Bộ lọc buổi ăn dạng chip ngang ──────────────────────────────────────────
class _MealFilterChips extends StatelessWidget {
  final List<_MealFilter> filters;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _MealFilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((filter) {
          final isActive = selected == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(filter.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : Colors.black.withOpacity(0.12),
                  ),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 15,
                      color: isActive ? Colors.white : Colors.black54,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Nút Add chung ─────────────────────────────────────────────────────────────
class _AddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.black12),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}