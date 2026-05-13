// lib/data/models/admin_user_model.dart
//
// Model user dành riêng cho màn hình Admin.
// Chứa thêm age (tính từ dob) và bmi (tính từ height/weight).

import 'package:intl/intl.dart';

class AdminUserModel {
  final String  id;
  final String  name;
  final String  email;
  final String  gender;
  final String  dob;           // "YYYY-MM-DD"
  final double? heightCm;
  final double? weightKg;
  final String  role;          // "user" | "admin"
  final int     currentStreak;
  final int     totalPoints;
  final String? avatarUrl;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
    this.heightCm,
    this.weightKg,
    required this.role,
    required this.currentStreak,
    required this.totalPoints,
    this.avatarUrl,
  });

  factory AdminUserModel.fromFirestore(
      String uid, Map<String, dynamic> data) {
    return AdminUserModel(
      id:            uid,
      name:          data['name']?.toString() ?? '',
      email:         data['email']?.toString() ?? '',
      gender:        data['gender']?.toString() ?? '',
      dob:           data['dob']?.toString() ?? '',
      heightCm:      (data['height_cm']    as num?)?.toDouble(),
      weightKg:      (data['weight_kg']    as num?)?.toDouble(),
      role:          data['role']?.toString() ?? 'user',
      currentStreak: (data['current_streak'] as num?)?.toInt() ?? 0,
      totalPoints:   (data['total_points']   as num?)?.toInt() ?? 0,
      avatarUrl:     data['avatar_url']?.toString(),
    );
  }

  // Tính tuổi từ dob
  int get age {
    if (dob.isEmpty) return 0;
    try {
      final birth = DateTime.parse(dob);
      final now   = DateTime.now();
      int age     = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  // Tính BMI
  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final hm = heightCm! / 100;
    return weightKg! / (hm * hm);
  }

  String get bmiLabel {
    final b = bmi;
    if (b == null) return '—';
    if (b < 18.5) return 'Thiếu cân';
    if (b < 25.0) return 'Bình thường';
    if (b < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }
}