// lib/data/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String gender;
  final String dob;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? goal;
  final int currentStreak;

  /// Streak dài nhất mà user đạt được (không bao giờ giảm)
  final int bestStreak;

  /// Ngày cuối cùng được tính streak (format yyyy-MM-dd)
  /// Dùng để kiểm tra có được tính streak hôm nay chưa
  final String lastStreakDate;

  final int totalPoints;
  final String? avatarUrl;
  final int shieldCount;
  final String? activeTagName;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.goal,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastStreakDate = '',
    this.totalPoints = 0,
    this.avatarUrl,
    this.shieldCount = 0,
    this.activeTagName,
  });

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      gender: data['gender']?.toString() ?? '',
      dob: data['dob']?.toString() ?? '',
      heightCm: (data['height_cm'] as num?)?.toDouble(),
      weightKg: (data['weight_kg'] as num?)?.toDouble(),
      activityLevel: data['activity_level']?.toString(),
      goal: data['goal']?.toString(),
      currentStreak: (data['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (data['best_streak'] as num?)?.toInt() ?? 0,
      lastStreakDate: data['last_streak_date']?.toString() ?? '',
      totalPoints: (data['total_points'] as num?)?.toInt() ?? 0,
      avatarUrl: data['avatar_url']?.toString(),
      shieldCount: (data['shield_count'] as num?)?.toInt() ?? 0,
      activeTagName: data['active_tag_name']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'gender': gender,
    'dob': dob,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': activityLevel,
    'goal': goal,
    'current_streak': currentStreak,
    'best_streak': bestStreak,
    'last_streak_date': lastStreakDate,
    'total_points': totalPoints,
    'avatar_url': avatarUrl,
    'shield_count': shieldCount,
    'active_tag_name': activeTagName,
  };

  String get goalLabel {
    switch (goal) {
      case 'Tăng cân':
        return '📈 Tăng cân';
      case 'Giảm cân':
        return '📉 Giảm cân';
      case 'Giữ cân':
        return '⚖️ Giữ cân';
      default:
        return goal ?? '—';
    }
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    int? currentStreak,
    int? bestStreak,
    String? lastStreakDate,
    int? totalPoints,
    int? shieldCount,
    String? activeTagName,
    String? goal,
    String? activityLevel,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      gender: gender,
      dob: dob,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      totalPoints: totalPoints ?? this.totalPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      shieldCount: shieldCount ?? this.shieldCount,
      activeTagName: activeTagName ?? this.activeTagName,
    );
  }
}