// lib/features/admin/views/admin_header_section.dart
//
// Phần header của màn hình Admin:
//   - Label "ADMINISTRATION" + tiêu đề
//   - Hàng thẻ thống kê (Recipes / Workouts / Users)
//   - Tab chính: Content | Users

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_state.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../widgets/stat_card.dart';
import 'admin_tab_bar.dart';

class AdminHeaderSection extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;

  const AdminHeaderSection({
    super.key,
    required this.state,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label nhỏ
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

        // Tiêu đề
        const Text(
          'Quản lý ứng dụng',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          'Chào mừng tới phần quản lý ứng dụng',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.45),
          ),
        ),
        const SizedBox(height: 20),

        // Hàng thống kê
        AdminStatsRow(state: state),
        const SizedBox(height: 20),

        // Tab chính Content | Users
        AdminMainTabBar(state: state, vm: vm),
      ],
    );
  }
}

// ── Hàng thẻ thống kê ────────────────────────────────────────────────────────
class AdminStatsRow extends StatelessWidget {
  final AdminState state;

  const AdminStatsRow({super.key, required this.state});

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

// ── Tab chính Content | Users ─────────────────────────────────────────────────
class AdminMainTabBar extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;

  const AdminMainTabBar({
    super.key,
    required this.state,
    required this.vm,
  });

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
          AdminTabBtn(
            label: '📋  Content',
            isActive: state.activeTab == AdminTab.content,
            onTap: () => vm.setAdminTab(AdminTab.content),
          ),
          AdminTabBtn(
            label: '👥  Users',
            isActive: state.activeTab == AdminTab.users,
            onTap: () => vm.setAdminTab(AdminTab.users),
          ),
        ],
      ),
    );
  }
}