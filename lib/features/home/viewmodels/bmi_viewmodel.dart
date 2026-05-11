// lib/features/home/viewmodels/bmi_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';


class WeightRecord {
  final int      measurement;
  final double   weightKg;
  final DateTime date;

  const WeightRecord({
    required this.measurement,
    required this.weightKg,
    required this.date,
  });

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      measurement: (map['measurement'] as num?)?.toInt() ?? 0,
      weightKg:    (map['weight_kg']   as num?)?.toDouble() ?? 0,
      date:        DateTime.tryParse(map['date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'measurement': measurement,
    'weight_kg':   weightKg,
    'date':        DateFormat('yyyy-MM-dd').format(date),
  };
}

//State
enum BmiStatus { initial, loading, success, error }

class BmiState {
  final BmiStatus          status;
  final String?            errorMessage;
  final List<WeightRecord> history;

  // Lấy thẳng từ users collection — source of truth
  final double?            currentWeight;
  final double?            heightCm;
  final bool               isSaving;

  const BmiState({
    this.status        = BmiStatus.initial,
    this.errorMessage,
    this.history       = const [],
    this.currentWeight,
    this.heightCm,
    this.isSaving      = false,
  });

  // ── Computed getters ──────────────────────────────────────────────────────

  // BMI tính từ users.weight_kg + users.height_cm (luôn đồng bộ)
  double? get bmi {
    if (currentWeight == null || heightCm == null || heightCm == 0) return null;
    final hm = heightCm! / 100;
    return currentWeight! / (hm * hm);
  }

  // Cân nặng ban đầu = lần đo measurement = 0
  double? get initialWeight {
    try {
      return history
          .firstWhere((r) => r.measurement == 0)
          .weightKg;
    } catch (_) {
      return currentWeight;
    }
  }

  // Thay đổi = cân nặng hiện tại - cân nặng ban đầu (lần 0)
  double? get weightChange {
    if (currentWeight == null || initialWeight == null) return null;
    return currentWeight! - initialWeight!;
  }

  // Label BMI
  String get bmiLabel {
    final b = bmi;
    if (b == null) return '—';
    if (b < 18.5) return 'Thiếu cân';
    if (b < 25.0) return 'Bình thường';
    if (b < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  // Số lần đo tiếp theo (không tính lần 0)
  int get nextMeasurementNumber {
    final updates = history.where((r) => r.measurement > 0).toList();
    return updates.isEmpty ? 1 : updates.last.measurement + 1;
  }

  BmiState copyWith({
    BmiStatus?          status,
    String?             errorMessage,
    List<WeightRecord>? history,
    double?             currentWeight,
    double?             heightCm,
    bool?               isSaving,
  }) {
    return BmiState(
      status:        status        ?? this.status,
      errorMessage:  errorMessage  ?? this.errorMessage,
      history:       history       ?? this.history,
      currentWeight: currentWeight ?? this.currentWeight,
      heightCm:      heightCm      ?? this.heightCm,
      isSaving:      isSaving      ?? this.isSaving,
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final bmiViewModelProvider =
StateNotifierProvider<BmiViewModel, BmiState>((ref) => BmiViewModel());

// ─── ViewModel ───────────────────────────────────────────────────────────────
class BmiViewModel extends StateNotifier<BmiState> {
  final FirebaseAuth     _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  BmiViewModel() : super(const BmiState()) {
    loadData();
  }

  // ── Load dữ liệu từ Firestore ─────────────────────────────────────────────
  Future<void> loadData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(status: BmiStatus.loading);
    try {
      final doc  = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      // ✅ currentWeight + heightCm luôn lấy từ users (không phải history)
      final heightCm      = (data['height_cm'] as num?)?.toDouble();
      final currentWeight = (data['weight_kg'] as num?)?.toDouble();

      // history_bmi từ Firestore → sort theo measurement tăng dần
      final rawHistory = (data['history_bmi'] as List?) ?? [];
      final history    = rawHistory
          .map((e) => WeightRecord.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.measurement.compareTo(b.measurement));

      state = state.copyWith(
        status:        BmiStatus.success,
        heightCm:      heightCm,
        currentWeight: currentWeight,
        history:       history,
      );
    } catch (e) {
      state = state.copyWith(
        status:       BmiStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      );
    }
  }

  // ── Cập nhật cân nặng + chiều cao ────────────────────────────────────────
  // Lưu vào users.weight_kg + users.height_cm (source of truth cho BMI)
  // Đồng thời append vào history_bmi (lần 1, 2, 3...)
  Future<void> saveWeightAndHeight({
    required double weightKg,
    required double heightCm,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(isSaving: true);
    try {
      final today   = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final history = List<WeightRecord>.from(state.history);

      // Số thứ tự lần cập nhật mới (lần 1 trở đi)
      final newMeasurement = state.nextMeasurementNumber;

      final newRecord = WeightRecord(
        measurement: newMeasurement,
        weightKg:    weightKg,
        date:        DateTime.now(),
      );

      history.add(newRecord);

      // ✅ Update users collection:
      //   weight_kg + height_cm → dùng để tính BMI realtime
      //   history_bmi           → lưu lịch sử
      await _db.collection('users').doc(uid).update({
        'weight_kg':   weightKg,   // ← source of truth cho BMI
        'height_cm':   heightCm,   // ← source of truth cho BMI
        'history_bmi': history.map((r) => r.toMap()).toList(),
      });

      state = state.copyWith(
        isSaving:      false,
        currentWeight: weightKg,   // cập nhật local state ngay
        heightCm:      heightCm,
        history:       history,
        status:        BmiStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving:     false,
        errorMessage: 'Lưu thất bại: $e',
      );
    }
  }
}