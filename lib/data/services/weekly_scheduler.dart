// lib/data/services/weekly_scheduler.dart
//
// Quản lý lịch generate plan dùng WorkManager (không cần Cloud Function).
//
// Luồng:
//   1. Sau InfoSetup → registerWeeklyTask() + runOnce() (generate ngay)
//   2. WorkManager trigger mỗi 24h → callbackDispatcher kiểm tra nếu thứ Hai → generate
//   3. Sau logout → cancelWeeklyTask()

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'plan_generator_service.dart';
import 'plan_worker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kLastGeneratedKey = 'last_plan_generated';

class WeeklyScheduler {
  final _generator = PlanGeneratorService();
  final _auth      = FirebaseAuth.instance;

  // ── Gọi sau khi user hoàn thành InfoSetup ─────────────────────────────
  Future<void> onUserSetupComplete() async {
    // 1. Generate ngay lập tức
    await _generateNow();

    // 2. Đăng ký WorkManager chạy định kỳ
    await PlanWorkerService.registerWeeklyTask();
  }

  // ── Gọi trong WorkManager callbackDispatcher ──────────────────────────
  // Kiểm tra nếu hôm nay là thứ Hai VÀ chưa generate tuần này → generate
  Future<bool> runIfNeeded() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final now        = DateTime.now();
    final isMonday   = now.weekday == DateTime.monday;
    final thisMonday = _getThisMonday();
    final mondayStr  = _fmt(thisMonday);

    final prefs        = await SharedPreferences.getInstance();
    final lastGenerated = prefs.getString('${_kLastGeneratedKey}_$uid');

    // Chỉ generate nếu là thứ Hai và chưa generate tuần này
    if (!isMonday || lastGenerated == mondayStr) return false;

    await _generateNow(weekStart: isMonday ? thisMonday : null);
    await prefs.setString('${_kLastGeneratedKey}_$uid', mondayStr);
    return true;
  }

  // ── Force generate lại (sau khi user đổi mục tiêu / cân nặng) ────────
  Future<void> forceRegenerate() async {
    await _generateNow();
    // Chạy lại ngay 1 lần qua WorkManager
    await PlanWorkerService.runOnce();
  }

  // ── Gọi khi logout ────────────────────────────────────────────────────
  Future<void> onLogout() async {
    await PlanWorkerService.cancelWeeklyTask();
  }

  // ── Internal ──────────────────────────────────────────────────────────
  Future<void> _generateNow({DateTime? weekStart}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final monday = weekStart ?? _getThisMonday();
    await _generator.generateWeeklyPlan(uid: uid, weekStart: monday);

    // Lưu timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kLastGeneratedKey}_$uid', _fmt(monday));
  }

  DateTime _getThisMonday() {
    final now     = DateTime.now();
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}



final weeklySchedulerProvider = Provider<WeeklyScheduler>(
      (ref) => WeeklyScheduler(),
);