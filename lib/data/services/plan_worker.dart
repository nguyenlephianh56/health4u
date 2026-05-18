// lib/data/services/plan_worker.dart
//
// WorkManager callback — chạy trong background khi app đóng.
// Được đăng ký trong main.dart, trigger mỗi 24h.
// Logic check thứ Hai được xử lý trong WeeklyScheduler.runIfNeeded().

import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'weekly_scheduler.dart';

// Task name constants
const kWeeklyPlanTask    = 'weeklyPlanGenerator';
const kWeeklyPlanTaskTag = 'health4u_weekly_plan';

// ── Callback chạy trong Isolate riêng ────────────────────────────────────────
// @pragma bắt buộc để không bị tree-shaken khi build release
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Firebase phải init lại vì chạy trong Isolate riêng
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (taskName == kWeeklyPlanTask) {
        // WeeklyScheduler.runIfNeeded() tự kiểm tra:
        //   - Hôm nay có phải thứ Hai không
        //   - Tuần này đã generate chưa (via SharedPreferences)
        await WeeklyScheduler().runIfNeeded();
      }

      return Future.value(true); // Task hoàn thành
    } catch (e) {
      print('[WorkManager] Error: $e');
      return Future.value(false); // Retry sau
    }
  });
}

// ── Service đăng ký + hủy task ───────────────────────────────────────────────
class PlanWorkerService {

  // Khởi tạo WorkManager — gọi 1 lần trong main()
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // true để xem log khi dev
    );
  }

  // Đăng ký periodic task chạy mỗi 24h
  // WeeklyScheduler.runIfNeeded() sẽ guard logic thứ Hai bên trong
  static Future<void> registerWeeklyTask() async {
    await Workmanager().registerPeriodicTask(
      kWeeklyPlanTaskTag,  // unique name
      kWeeklyPlanTask,     // task name (nhận trong callbackDispatcher)

      frequency: const Duration(hours: 24),

      // Chạy lúc thiết bị rảnh + có mạng
      constraints: Constraints(
        networkType:           NetworkType.connected,
        requiresBatteryNotLow: true,
      ),

      // Nếu task fail → retry sau 30 phút
      backoffPolicy:      BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 30),

      // Giữ task khi reboot thiết bị
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  // Hủy task (dùng khi logout)
  static Future<void> cancelWeeklyTask() async {
    await Workmanager().cancelByUniqueName(kWeeklyPlanTaskTag);
  }

  // Chạy ngay 1 lần (dùng sau InfoSetup hoặc khi test)
  static Future<void> runOnce() async {
    await Workmanager().registerOneOffTask(
      '${kWeeklyPlanTaskTag}_once',
      kWeeklyPlanTask,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}