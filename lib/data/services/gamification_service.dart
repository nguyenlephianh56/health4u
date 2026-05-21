// lib/data/services/gamification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────────────────────

class GamificationResult {
  final int pointsDelta;
  final int newTotalPoints;
  final int newStreak;
  final int newBestStreak;
  final bool streakIncreased;

  const GamificationResult({
    required this.pointsDelta,
    required this.newTotalPoints,
    required this.newStreak,
    required this.newBestStreak,
    required this.streakIncreased,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// GamificationService
// ─────────────────────────────────────────────────────────────────────────────

class GamificationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _fmt = DateFormat('yyyy-MM-dd');

  static const int _pointsPerMeal    = 10;
  static const int _pointsPerWorkout = 20;

  GamificationService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db   = db   ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  String _dateKey(DateTime d) => _fmt.format(d);

  // ── PUBLIC ────────────────────────────────────────────────────────────────

  Future<GamificationResult?> onMealToggled({
    required bool isCompleting,
    required DateTime date,
  }) async {
    final uid = _uid;
    print('[GAMI] onMealToggled | uid=$uid | completing=$isCompleting | date=${_dateKey(date)}');
    if (uid == null) return null;
    return _run(
      uid: uid,
      date: date,
      delta: isCompleting ? _pointsPerMeal : -_pointsPerMeal,
      checkStreak: isCompleting,
    );
  }

  Future<GamificationResult?> onWorkoutToggled({
    required bool isCompleting,
    required DateTime date,
  }) async {
    final uid = _uid;
    print('[GAMI] onWorkoutToggled | uid=$uid | completing=$isCompleting | date=${_dateKey(date)}');
    if (uid == null) return null;
    return _run(
      uid: uid,
      date: date,
      delta: isCompleting ? _pointsPerWorkout : -_pointsPerWorkout,
      checkStreak: isCompleting,
    );
  }

  /// Gọi khi mở app — reset streak về 0 nếu user bỏ lỡ ngày hôm qua.
  Future<void> checkStreakReset() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) return;

      final data     = snap.data() ?? {};
      final streak   = (data['current_streak'] as num?)?.toInt() ?? 0;
      final lastDate = data['last_streak_date']?.toString() ?? '';

      if (streak == 0 || lastDate.isEmpty) return;

      final today     = _dateKey(DateTime.now());
      final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

      // Đã hoàn thành hôm nay → không reset
      if (lastDate == today) return;

      // lastDate < hôm qua → bỏ lỡ ít nhất 1 ngày → reset
      if (lastDate.compareTo(yesterday) < 0) {
        await _db.collection('users').doc(uid).update({'current_streak': 0});
        print('[GAMI] ⚠️ streak reset | last=$lastDate yesterday=$yesterday');
      }
      // lastDate == yesterday → chưa hoàn thành hôm nay nhưng chưa bỏ lỡ → giữ nguyên
    } catch (e) {
      print('[GAMI] checkStreakReset error: $e');
    }
  }

  // ── PRIVATE ───────────────────────────────────────────────────────────────

  Future<GamificationResult?> _run({
    required String   uid,
    required DateTime date,
    required int      delta,
    required bool     checkStreak,
  }) async {
    final dateStr = _dateKey(date);
    final userRef = _db.collection('users').doc(uid);
    // Doc ID format khớp với nutrition_viewmodel và health_repo: {uid}_{date}
    final planRef = _db.collection('user_plans').doc('${uid}_$dateStr');

    print('[GAMI] _run START | dateStr=$dateStr | delta=$delta | planDocId=${uid}_$dateStr');

    GamificationResult? result;

    try {
      // FIX RACE CONDITION: Đọc planSnap NGOÀI transaction bằng get() thông thường.
      // Lý do: nutrition_viewmodel đã await ghi Firestore xong rồi mới gọi hàm này,
      // nên get() sẽ lấy được state mới nhất (meals đã updated).
      // Nếu đọc trong transaction, Firestore có thể trả về snapshot cũ (read-your-writes
      // không đảm bảo trong cross-document transaction trên mobile SDK).
      final planSnap = checkStreak
          ? await planRef.get()
          : null;

      print('[GAMI] planSnap | exists=${planSnap?.exists} | checkStreak=$checkStreak');

      await _db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);

        print('[GAMI] tx read | userExists=${userSnap.exists}');

        if (!userSnap.exists) {
          print('[GAMI] ❌ user doc missing → abort');
          return;
        }

        final ud        = userSnap.data()! as Map<String, dynamic>;
        final oldPts    = (ud['total_points']   as num?)?.toInt() ?? 0;
        final oldStreak = (ud['current_streak'] as num?)?.toInt() ?? 0;
        final oldBest   = (ud['best_streak']    as num?)?.toInt() ?? 0;
        final lastDate  = ud['last_streak_date']?.toString() ?? '';
        final newPts    = (oldPts + delta).clamp(0, 999999);

        int  newStreak = oldStreak;
        int  newBest   = oldBest;
        bool streakUp  = false;

        if (checkStreak && planSnap != null) {
          final done = _isDayFullyDone(planSnap, dateStr);
          print('[GAMI] checkStreak | dayFullyDone=$done | lastDate=$lastDate | today=$dateStr');

          // Tăng streak khi: ngày đã hoàn thành toàn bộ VÀ chưa tính hôm nay
          if (done && lastDate != dateStr) {
            newStreak = oldStreak + 1;
            newBest   = newStreak > oldBest ? newStreak : oldBest;
            streakUp  = true;
          }
        }

        final update = <String, dynamic>{'total_points': newPts};
        if (streakUp) {
          update['current_streak']   = newStreak;
          update['best_streak']      = newBest;
          update['last_streak_date'] = dateStr;
        }

        tx.update(userRef, update);

        print('[GAMI] ✅ tx done | pts $oldPts→$newPts | streak $oldStreak→$newStreak | best $oldBest→$newBest | streakUp=$streakUp');

        result = GamificationResult(
          pointsDelta:     delta,
          newTotalPoints:  newPts,
          newStreak:       newStreak,
          newBestStreak:   newBest,
          streakIncreased: streakUp,
        );
      });
    } catch (e, st) {
      print('[GAMI] ❌ ERROR: $e');
      print('[GAMI] ❌ STACK: $st');
      return null;
    }

    return result;
  }

  // ── Kiểm tra ngày hoàn thành toàn bộ ─────────────────────────────────────
  //
  // Cấu trúc user_plans/{uid}_{date}:
  //   is_completed: true          ← workout done (root level)
  //   meals:
  //     Breakfast: { is_completed: true }
  //     Lunch:     { is_completed: true }
  //     Dinner:    { is_completed: true }
  //     Snack:     { is_completed: true }

  bool _isDayFullyDone(DocumentSnapshot planSnap, String dateStr) {
    if (!planSnap.exists || planSnap.data() == null) {
      print('[GAMI] _isDayFullyDone($dateStr) → plan doc MISSING');
      return false;
    }

    final data = planSnap.data()! as Map<String, dynamic>;
    print('[GAMI] _isDayFullyDone($dateStr) → root keys: ${data.keys.toList()}');

    // 1. Workout hoàn thành (root is_completed)
    final workoutDone = data['is_completed'] == true;
    print('[GAMI] workout is_completed=${data['is_completed']} → workoutDone=$workoutDone');
    if (!workoutDone) return false;

    // 2. Cả 4 bữa ăn hoàn thành
    final mealsRaw = data['meals'];
    print('[GAMI] meals type=${mealsRaw?.runtimeType}');
    if (mealsRaw == null || mealsRaw is! Map) {
      print('[GAMI] meals missing or wrong type → false');
      return false;
    }

    final meals    = Map<String, dynamic>.from(mealsRaw as Map);
    const mealKeys = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    for (final k in mealKeys) {
      final m    = meals[k];
      final done = m is Map ? m['is_completed'] : null;
      print('[GAMI] meal[$k] is_completed=$done');
      if (m == null || m is! Map || m['is_completed'] != true) return false;
    }

    print('[GAMI] _isDayFullyDone($dateStr) → ✅ TRUE');
    return true;
  }
}