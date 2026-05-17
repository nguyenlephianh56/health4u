// lib/data/models/reward_model.dart
//
// Model ánh xạ từ Firestore:
//   - collection `reward_items`  : danh mục phần thưởng (do Admin tạo sẵn)
//   - collection `user_rewards`  : phần thưởng user đã mua

enum RewardType { streakShield, titleTag }

class RewardItem {
  final String     id;
  final RewardType type;
  final String     name;
  final String     description;
  final String     iconEmoji;
  final int        costPts;

  const RewardItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.costPts,
  });

  factory RewardItem.fromMap(String id, Map<String, dynamic> map) {
    return RewardItem(
      id:          id,
      type:        map['type'] == 'streak_shield'
          ? RewardType.streakShield
          : RewardType.titleTag,
      name:        map['name']        as String,
      description: map['description'] as String,
      iconEmoji:   map['icon_emoji']  as String,
      costPts:     (map['cost_pts']   as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type':        type == RewardType.streakShield ? 'streak_shield' : 'title_tag',
    'name':        name,
    'description': description,
    'icon_emoji':  iconEmoji,
    'cost_pts':    costPts,
  };
}

class UserReward {
  final String   id;          // '{userId}_{rewardId}'
  final String   userId;
  final String   rewardId;
  final DateTime purchasedAt;
  final bool     isActive;
  final int      quantity;    // dùng cho streakShield (số thẻ còn lại)

  const UserReward({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.purchasedAt,
    required this.isActive,
    required this.quantity,
  });

  factory UserReward.fromMap(String id, Map<String, dynamic> map) {
    return UserReward(
      id:          id,
      userId:      map['user_id']     as String,
      rewardId:    map['reward_id']   as String,
      purchasedAt: DateTime.parse(map['purchased_at'] as String),
      isActive:    map['is_active']   as bool,
      quantity:    (map['quantity']   as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id':      userId,
    'reward_id':    rewardId,
    'purchased_at': purchasedAt.toIso8601String(),
    'is_active':    isActive,
    'quantity':     quantity,
  };

  UserReward copyWith({bool? isActive, int? quantity}) => UserReward(
    id:          id,
    userId:      userId,
    rewardId:    rewardId,
    purchasedAt: purchasedAt,
    isActive:    isActive    ?? this.isActive,
    quantity:    quantity    ?? this.quantity,
  );
}