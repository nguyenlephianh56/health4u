// lib/router/shell_scaffold.dart
//
// Mô tả: Widget bọc tất cả màn hình có bottom navigation bar.
// GoRouter ShellRoute truyền `child` vào đây.
//
// Logic hiển thị tab:
//   role = "user"  → 5 tab: Home / Meals / Workout / Grocery / Profile
//   role = "admin" → 6 tab: thêm tab Admin (có badge vàng)
//
// Đọc role từ AuthRepo (data/repositories/auth_repo.dart) — không tự gọi Firestore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../data/repositories/auth_repo.dart';   // ✅ đúng kiến trúc
import 'app_router.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  // ── Định nghĩa tất cả tab ───────────────────────────────────────────────
  static const _userTabs = <_TabItem>[
    _TabItem(
      label: 'Home',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      route: AppRoutes.home,
    ),
    _TabItem(
      label: 'Meals',
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu_rounded,
      route: AppRoutes.meals,
    ),
    _TabItem(
      label: 'Workout',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
      route: AppRoutes.workout,
    ),
    _TabItem(
      label: 'Grocery',
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      route: AppRoutes.grocery,
    ),
    _TabItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: AppRoutes.profile,
    ),
  ];

  // Tab Admin chỉ thêm khi role = "admin"
  static const _adminTab = _TabItem(
    label: 'Admin',
    icon: Icons.admin_panel_settings_outlined,
    activeIcon: Icons.admin_panel_settings_rounded,
    route: AppRoutes.admin,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đọc role từ AuthRepo — không gọi Firestore trực tiếp
    // ✅ authRepoProvider là tên đúng được khai báo trong auth_repo.dart
    final authState = ref.watch(authRepoProvider);
    final isAdmin = authState.isAdmin;

    // Danh sách tab theo role
    final tabs = isAdmin ? [..._userTabs, _adminTab] : _userTabs;

    // Tab nào đang active dựa vào current path
    final currentPath = GoRouterState.of(context).matchedLocation;
    final activeIndex = _getActiveIndex(currentPath, tabs);

    return Scaffold(
      backgroundColor: AppColors.background,
      // child là màn hình của tab đang active (do ShellRoute truyền vào)
      body: child,
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        activeIndex: activeIndex,
      ),
    );
  }

  int _getActiveIndex(String path, List<_TabItem> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (path.startsWith(tabs[i].route)) return i;
    }
    return 0;
  }
}

// ─── Bottom Navigation Widget ────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final List<_TabItem> tabs;
  final int activeIndex;

  const _BottomNav({
    required this.tabs,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == activeIndex;
              final isAdminTab = tab.route == AppRoutes.admin;

              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tab.route),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon với background khi active
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              size: 22,
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.black.withOpacity(0.35),
                            ),
                          ),

                          // Badge vàng riêng cho tab Admin
                          if (isAdminTab)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary, // #F59E0B
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : Colors.black.withOpacity(0.35),
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Data class cho mỗi tab ───────────────────────────────────────────────────
class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}