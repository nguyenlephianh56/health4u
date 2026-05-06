// lib/features/admin/views/admin_dashboard_screen.dart
//
// Mô tả: Màn hình Admin — bao gồm:
//   - Header thống kê (recipes / workouts / users count)
//   - Tab chọn: Content | Users
//   - Tab Content: sub-tab Recipes | Workouts + danh sách + CRUD
//
// Vai trò MVVM:
//   → VIEW: Chỉ lo UI, lắng nghe AdminState từ AdminViewModel
//   → Gọi viewModel.addRecipe() / updateRecipe() / deleteRecipe()
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../viewmodels/admin_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/recipe_list_item.dart';
import '../widgets/recipe_form_dialog.dart';
import '../../../data/models/recipe_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminViewModelProvider);
    final vm = ref.read(adminViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tiêu đề ──────────────────────────────────────────
                    Text(
                      'ADMINISTRATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Quản lý ứng dụng',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chào mừng tới phần quản lý ứng dụng',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── FIX LỖI 1: Dùng widget class thay vì method ──────
                    _StatsRow(state: state),
                    const SizedBox(height: 20),

                    // ── Tab chính ─────────────────────────────────────────
                    _MainTabBar(state: state, vm: vm),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Nội dung theo tab ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: state.activeTab == AdminTab.content
                    ? _ContentSection(state: state, vm: vm)
                    : _UsersSection(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Hàng thẻ thống kê ───────────────────────────────────────────────
// FIX LỖI 1: Tách thành StatelessWidget riêng → StatCard import hoạt động đúng
class _StatsRow extends StatelessWidget {
  final AdminState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Gọi StatCard như constructor bình thường trong widget build
          StatCard(
            emoji: '📖',
            count: state.recipeCount,
            label: 'Recipes',
            bgColor: const Color(0xFFE0F2FE),
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 10),
          StatCard(
            emoji: '🏋️',
            count: state.workoutCount,
            label: 'Workouts',
            bgColor: const Color(0xFFFFEDE0),
            iconColor: const Color(0xFFEA580C),
          ),
          const SizedBox(width: 10),
          StatCard(
            emoji: '👥',
            count: state.userCount,
            label: 'Users',
            bgColor: const Color(0xFFF0EEFF),
            iconColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Tab chính Content | Users ───────────────────────────────────────
class _MainTabBar extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;
  const _MainTabBar({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabBtn(
            label: '📋  Content',
            isActive: state.activeTab == AdminTab.content,
            onTap: () => vm.setAdminTab(AdminTab.content),
          ),
          _TabBtn(
            label: '👥  Users',
            isActive: state.activeTab == AdminTab.users,
            onTap: () => vm.setAdminTab(AdminTab.users),
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Section Content ──────────────────────────────────────────────────
class _ContentSection extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;
  const _ContentSection({required this.state, required this.vm});

  // FIX LỖI 2: Bỏ isScrollControlled (không có trong showDialog)
  // Dialog tự cuộn bên trong bằng SingleChildScrollView trong RecipeFormDialog
  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Bấm ra ngoài để đóng
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
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Xóa món ăn?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
              // ✅ Pop dialog TRƯỚC rồi mới xóa data
              // Thứ tự quan trọng: nếu xóa trước → stream emit → rebuild
              // → dialogContext invalid → Navigator bị locked → crash
              Navigator.pop(dialogContext);
              await vm.deleteRecipe(recipe.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        // Sub-tab Recipes | Workouts
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _SubTabBtn(
                label: '🍽️  Recipes',
                isActive: state.activeContentTab == ContentTab.recipes,
                onTap: () => vm.setContentTab(ContentTab.recipes),
              ),
              _SubTabBtn(
                label: '💪  Workouts',
                isActive: state.activeContentTab == ContentTab.workouts,
                onTap: () => vm.setContentTab(ContentTab.workouts),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nội dung sub-tab
        if (state.activeContentTab == ContentTab.recipes) ...[
          // Nút Add New Recipe
          _AddRecipeBtn(onTap: () => _openAddDialog(context)),
          const SizedBox(height: 16),

          // Danh sách recipes
          if (state.recipes.isEmpty)
            const _EmptyRecipes()
          else
            ...state.recipes.map(
                  (recipe) => RecipeListItem(
                recipe: recipe,
                onEdit: () => _openEditDialog(context, recipe),
                onDelete: () => _confirmDelete(context, recipe),
              ),
            ),
        ] else
          const _WorkoutPlaceholder(),
      ],
    );
  }
}

// ─── Widget: Nút thêm recipe ──────────────────────────────────────────────────
class _AddRecipeBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRecipeBtn({required this.onTap});

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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add New Recipe',
              style: TextStyle(
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

// ─── Widget: Empty state ──────────────────────────────────────────────────────
class _EmptyRecipes extends StatelessWidget {
  const _EmptyRecipes();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Chưa có món ăn nào.\nBấm "Add New Recipe" để thêm!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Widget: Workout placeholder ─────────────────────────────────────────────
class _WorkoutPlaceholder extends StatelessWidget {
  const _WorkoutPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          '💪 Phần Workouts sẽ được bổ sung sau.',
          style: TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Widget: Users placeholder ───────────────────────────────────────────────
class _UsersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          '👥 Phần quản lý Users sẽ được bổ sung sau.',
          style: TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Shared tab button widgets ────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubTabBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _SubTabBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : Colors.black45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}