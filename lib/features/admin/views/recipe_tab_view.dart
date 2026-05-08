// lib/features/admin/views/recipe_tab_view.dart
//
// Tab Recipes: nút Add + danh sách + sửa + xóa

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_state.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../widgets/recipe_list_item.dart';
import '../widgets/recipe_form_dialog.dart';
import '../../../data/models/recipe_model.dart';

class RecipeTabView extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;

  const RecipeTabView({
    super.key,
    required this.state,
    required this.vm,
  });

  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RecipeFormDialog(
        recipe: null,
        onSave: (recipe) => vm.addRecipe(recipe),
      ),
    );
  }

  void _openEditDialog(BuildContext context, RecipeModel recipe) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RecipeFormDialog(
        recipe: recipe,
        onSave: (updated) => vm.updateRecipe(updated),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RecipeModel recipe) {
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
              Navigator.pop(dialogContext); // Pop TRƯỚC
              await vm.deleteRecipe(recipe.id);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nút Add New Recipe
        _AddBtn(
          label: 'Add New Recipe',
          onTap: () => _openAddDialog(context),
        ),
        const SizedBox(height: 16),

        // Danh sách
        if (state.recipes.isEmpty)
          const _EmptyState(
            message: 'Chưa có món ăn nào.\nBấm "Add New Recipe" để thêm!',
          )
        else
          ...state.recipes.map(
                (recipe) => RecipeListItem(
              recipe: recipe,
              onEdit:   () => _openEditDialog(context, recipe),
              onDelete: () => _confirmDelete(context, recipe),
            ),
          ),
      ],
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
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }
}