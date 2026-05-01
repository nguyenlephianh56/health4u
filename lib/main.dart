// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: Health4UApp()));
}

class Health4UApp extends ConsumerWidget {
  const Health4UApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy GoRouter từ provider — đã tích hợp auth guard tự động
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Health4U',
      debugShowCheckedModeBanner: false,

      // Bắt buộc để DatePicker + dialog hiển thị tiếng Việt
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],

      // Theme từ app_theme.dart
      theme: AppTheme.lightTheme,

      // GoRouter config — thay cho onGenerateRoute
      routerConfig: router,
    );
  }
}