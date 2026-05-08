// lib/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/info_setup_screen.dart';
import '../features/admin/views/admin_dashboard_screen.dart';

// TODO: Bỏ comment từng dòng khi màn hình thật sẵn sàng
// import '../features/home/views/home_screen.dart';
// import '../features/nutrition/views/meal_plan_screen.dart';
// import '../features/workout/views/workout_screen.dart';
// import '../features/grocery/views/grocery_screen.dart';
import '../features/profile/views/profile_screen.dart';

import '../data/repositories/auth_repo.dart';
import '../data/repositories/auth_state_model.dart';
import 'shell_scaffold.dart';

// ─── Hằng số route ───────────────────────────────────────────────────────────
class AppRoutes {
  static const splash     = '/';
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
  final routerNotifier = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: routerNotifier,

    redirect: (context, state) {
      final authState   = ref.read(authRepoProvider);
      final currentPath = state.matchedLocation;

      switch (authState.status) {

      // ── Đang load Firebase + SharedPreferences ────────────────────
      // Giữ nguyên ở SplashScreen, chờ _init() xong
        case AppAuthStatus.loading:
          return currentPath == AppRoutes.splash ? null : AppRoutes.splash;

      // ── Lần đầu vào app, chưa xem onboarding ─────────────────────
        case AppAuthStatus.onboarding:
          if (currentPath == AppRoutes.onboarding) return null;
          return AppRoutes.onboarding;

      // ── Đã xem onboarding, chưa đăng nhập ────────────────────────
        case AppAuthStatus.unauthenticated:
        // Cho phép ở login hoặc register
          if (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.register) return null;
          return AppRoutes.login;

      // ── Đã đăng nhập nhưng chưa điền thông tin ───────────────────
        case AppAuthStatus.needsSetup:
          if (currentPath == AppRoutes.infoSetup) return null;
          return AppRoutes.infoSetup;

      // ── Đã đăng nhập + đầy đủ thông tin ──────────────────────────
        case AppAuthStatus.authenticated:
        // Nếu đang ở auth route → vào home
          final isOnAuthRoute = [
            AppRoutes.splash,
            AppRoutes.onboarding,
            AppRoutes.login,
            AppRoutes.register,
            AppRoutes.infoSetup,
          ].contains(currentPath);
          if (isOnAuthRoute) return AppRoutes.home;
          return null; // Đang ở đúng màn hình rồi
      }
    },

    routes: [
      // ── Splash ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (c, s) => _fadePage(s, const _SplashScreen()),
      ),

      // ── Auth (không có bottom nav) ────────────────────────────────────
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

      // ── Shell (có bottom nav) ─────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (c, s) =>
                _fadePage(s, const _TempHomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.meals,
            pageBuilder: (c, s) =>
                _fadePage(s, const _ComingSoonScreen(title: 'Meals')),
          ),
          GoRoute(
            path: AppRoutes.workout,
            pageBuilder: (c, s) =>
                _fadePage(s, const _ComingSoonScreen(title: 'Workout')),
          ),
          GoRoute(
            path: AppRoutes.grocery,
            pageBuilder: (c, s) =>
                _fadePage(s, const _ComingSoonScreen(title: 'Grocery')),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (c, s) =>
                _fadePage(s, const ProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.admin,
            pageBuilder: (c, s) =>
                _fadePage(s, const AdminDashboardScreen()),
          ),
        ],
      ),
    ],

    errorPageBuilder: (c, s) => _fadePage(s, const _NotFoundScreen()),
  );
});

// ── Fade transition ───────────────────────────────────────────────────────────
CustomTransitionPage _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

// ── Splash Screen ─────────────────────────────────────────────────────────────
// Hiện trong lúc _init() chạy (đọc SharedPreferences + kiểm tra Firebase)
// Thường chỉ hiện < 1 giây
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0284C7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('💪', style: TextStyle(fontSize: 46)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Health4U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dinh dưỡng & Tập luyện thông minh',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Temp Home Screen — có nút logout để test ─────────────────────────────────
// Xóa class này khi HomeScreen thật sẵn sàng
class _TempHomeScreen extends ConsumerWidget {
  const _TempHomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏠', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'Home Screen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đang phát triển...',
                style: TextStyle(color: Colors.black45, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // ── Nút logout tạm thời ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authRepoProvider.notifier).signOut();
                    // Router tự redirect về /login khi state = unauthenticated
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất (tạm thời)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}

// ── Coming Soon (placeholder cho màn hình chưa làm) ──────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  final String title;
  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚧', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đang phát triển...',
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 404 Screen ────────────────────────────────────────────────────────────────
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
            const Text(
              '404',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Không tìm thấy trang này',
              style: TextStyle(color: Colors.black45, fontSize: 15),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.onboarding),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7)),
              child: const Text(
                'Về trang chủ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}