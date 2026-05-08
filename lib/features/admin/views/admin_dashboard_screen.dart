// lib/features/admin/views/admin_dashboard_screen.dart
//
// Shell chính của màn hình Admin.
// File này CHỈ lo layout tổng thể, mọi logic và UI con
// đã được tách ra các file riêng:
//
//   admin_header_section.dart  ← tiêu đề + stats + tab chính
//   content_section.dart       ← tab Content (recipe + workout)
//   recipe_tab_view.dart       ← danh sách + CRUD recipe
//   workout_tab_view.dart      ← danh sách + CRUD workout
//   users_section.dart         ← tab Users
//   admin_tab_bar.dart         ← widget tab button dùng chung

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../viewmodels/admin_state.dart';
import 'admin_header_section.dart';
import 'content_section.dart';
import 'users_section.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminViewModelProvider);
    final vm    = ref.read(adminViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header: tiêu đề + stats + tab chính ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: AdminHeaderSection(state: state, vm: vm),
              ),
            ),

            // ── Nội dung theo tab ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: state.activeTab == AdminTab.content
                    ? ContentSection(state: state, vm: vm)
                    : const UsersSection(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}