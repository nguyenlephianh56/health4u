// lib/router/app_router.dart
//
// Mô tả: Cấu hình toàn bộ điều hướng app bằng GoRouter.
//
// Vị trí đúng theo kiến trúc: lib/router/app_router.dart
//
// Luồng redirect (guard):
//   Chưa đăng nhập           → /onboarding
//   Đã login, chưa setup     → /info-setup  (bắt buộc điền thông tin)
//   Đã login + đã setup      → /home        (vào app bình thường)
//   role = "admin"           → thấy thêm tab Admin trong bottom nav
//
// Tất cả redirect chạy tự động mỗi khi AuthRepo.notifyListeners() được gọi
// (sau login / logout / saveUserInfo).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/info_setup_screen.dart';

// Main app screens
import '../features/home/views/home_screen.dart';
import '../features/nutrition/views/meal_plan_screen.dart';
import '../features/workout/views/workout_screen.dart';
import '../features/grocery/views/grocery_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/admin/views/admin_dashboard_screen.dart';

// ✅ Đúng kiến trúc: import từ data/repositories
import '../data/repositories/auth_repo.dart';

// Shell scaffold (bottom nav)
import 'shell_scaffold.dart';

// ─── Hằng số route ───────────────────────────────────────────────────────────
class AppRoutes {
  static const onboarding = '/onboarding';
  static const login      = '/login';
  static const register   = '/register';
  static const infoSetup  = '/info-setup';
  static const home       = '/home';
  static const meals      = '/meals';
  static const workout    = '/workout';
  static const grocery    = '/grocery';
  static const profile    = '/profile';
  static const admin      = '/admin';
}

// ─── Provider GoRouter ───────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  // ✅ Dùng AuthRouterNotifier (ChangeNotifier thuần) làm refreshListenable
  // → Không còn xung đột addListener với StateNotifier nữa
  final routerNotifier = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,

    // ✅ AuthRouterNotifier là ChangeNotifier → không bị lỗi override
    refreshListenable: routerNotifier,

    redirect: (context, state) {
      // Đọc AuthStateModel từ AuthRepo (StateNotifier)
      final authState = ref.read(authRepoProvider);
      final currentPath = state.matchedLocation;

      final isLoggedIn       = authState.isLoggedIn;
      final isSetupCompleted = authState.isSetupCompleted;

      final isOnAuthRoute = [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
      ].contains(currentPath);

      // RULE 1: Chưa đăng nhập → về onboarding
      if (!isLoggedIn && !isOnAuthRoute) return AppRoutes.onboarding;

      // RULE 2: Đã login nhưng chưa setup → bắt buộc vào info-setup
      if (isLoggedIn && !isSetupCompleted &&
          currentPath != AppRoutes.infoSetup) {
        return AppRoutes.infoSetup;
      }

      // RULE 3: Đã login + đã setup, đang ở auth route → vào home
      if (isLoggedIn && isSetupCompleted && isOnAuthRoute) {
        return AppRoutes.home;
      }

      return null; // Không redirect → cho đi tiếp
    },

    routes: [
      // ── Auth routes (không có bottom nav) ─────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (c, s) => _fadePage(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (c, s) => _fadePage(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (c, s) => _fadePage(s, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.infoSetup,
        pageBuilder: (c, s) => _fadePage(s, const InfoSetupScreen()),
      ),

      // ── Shell route: các tab có bottom nav ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (c, s) => _fadePage(s, const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.meals,
            pageBuilder: (c, s) => _fadePage(s, const MealPlanScreen()),
          ),
          GoRoute(
            path: AppRoutes.workout,
            pageBuilder: (c, s) => _fadePage(s, const WorkoutScreen()),
          ),
          GoRoute(
            path: AppRoutes.grocery,
            pageBuilder: (c, s) => _fadePage(s, const GroceryScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (c, s) => _fadePage(s, const ProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.admin,
            pageBuilder: (c, s) => _fadePage(s, const AdminDashboardScreen()),
          ),
        ],
      ),
    ],

    errorPageBuilder: (c, s) => _fadePage(s, const _NotFoundScreen()),
  );
});

// ── Fade transition helper ───────────────────────────────────────────────────
CustomTransitionPage _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

// ── 404 Screen ───────────────────────────────────────────────────────────────
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404',
                style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7))),
            const SizedBox(height: 8),
            const Text('Không tìm thấy trang này',
                style: TextStyle(color: Colors.black45, fontSize: 15)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7)),
              child: const Text('Về trang chủ',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}