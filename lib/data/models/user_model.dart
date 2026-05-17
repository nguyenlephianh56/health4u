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
    int? totalPoints,
    int? shieldCount,
    String? activeTagName,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      gender: gender,
      dob: dob,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goal: goal,
      currentStreak: currentStreak ?? this.currentStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,

      shieldCount: shieldCount ?? this.shieldCount,
      activeTagName: activeTagName ?? this.activeTagName,
    );
  }
}