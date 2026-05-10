import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';  // nếu chưa có thì tạo stub
import '../features/home/views/home_screen.dart';
import '../features/workout/views/workout_schedule_screen.dart';
import '../features/workout/views/exercise_detail_screen.dart';
// Thêm các màn hình khác (tạm tạo stub nếu chưa có)
import '../features/nutrition/views/meal_plan_screen.dart';
import '../features/grocery/views/smart_grocery_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/admin/views/admin_dashboard_screen.dart';
import 'shell_scaffold.dart';

class AppRoutes {
  static const String home = '/';
  static const String meals = '/meals';
  static const String workout = '/workout';
  static const String exerciseDetail = '/exercise-detail';
  static const String grocery = '/grocery';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String login = '/login';
  static const String register = '/register';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.meals,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MealPlanScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.workout,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorkoutScheduleScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.grocery,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SmartGroceryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.admin,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.exerciseDetail,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExerciseDetailScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(), // bạn sẽ tạo sau
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(), // bạn sẽ tạo sau
      ),
    ],
  );
});