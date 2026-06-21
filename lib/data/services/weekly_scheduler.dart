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

  // ── Gọi trong WorkManager callbackDispatcher, và cũng gọi mỗi khi app mở ──
  // (xem ProfileViewModel.loadProfile()) làm fallback vì WorkManager không
  // đảm bảo chạy đúng giờ.
  //
  // Điều kiện generate: tuần hiện tại (tính từ thứ Hai gần nhất) CHƯA được
  // generate — KHÔNG yêu cầu hôm nay phải đúng là thứ Hai. Nhờ vậy nếu app
  // bị bỏ quên qua cả thứ Hai (không mở app, WorkManager cũng không chạy),
  // thì lần mở app kế tiếp — dù là thứ Ba, thứ Tư... — vẫn sẽ generate bù
  // ngay, thay vì im lặng giữ plan của tuần trước.
  Future<bool> runIfNeeded() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final thisMonday = _getThisMonday();
    final mondayStr  = _fmt(thisMonday);

    final prefs         = await SharedPreferences.getInstance();
    final lastGenerated = prefs.getString('${_kLastGeneratedKey}_$uid');

    // Đã generate cho tuần này rồi (kể cả nếu generate trễ vào thứ Ba...)
    // thì không cần generate lại.
    if (lastGenerated == mondayStr) return false;

    await _generateNow(weekStart: thisMonday);
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