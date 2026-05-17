// lib/data/repositories/reward_repo.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class RewardRepo {
  final FirebaseFirestore _db;

  RewardRepo({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _items => _db.collection('reward_items');

  CollectionReference get _userRewards =>
      _db.collection('user_rewards');

  DocumentReference _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<List<RewardItem>> fetchAllItems() async {
    final snap = await _items.orderBy('cost_pts').get();

    return snap.docs
        .map((d) =>
        RewardItem.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserReward>> fetchUserRewards(String uid) async {
    final snap = await _userRewards
        .where('user_id', isEqualTo: uid)
        .get();

    return snap.docs
        .map((d) =>
        UserReward.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<String?> purchaseReward({
    required String uid,
    required RewardItem item,
  }) async {
    try {
      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(_userDoc(uid));

        final userData =
        userSnap.data() as Map<String, dynamic>;

        final currentPts =
            (userData['total_points'] as num?)?.toInt() ?? 0;

        if (currentPts < item.costPts) {
          throw Exception('Không đủ điểm');
        }

        final docId = '${uid}_${item.id}';

        final docRef = _userRewards.doc(docId);

        final existing = await txn.get(docRef);

        if (existing.exists) {
          if (item.type == RewardType.streakShield) {
            final qty =
                ((existing.data() as Map<String, dynamic>)['quantity']
                as num?)
                    ?.toInt() ??
                    0;

            txn.update(docRef, {
              'quantity': qty + 1,
            });
          } else {
            throw Exception('Bạn đã sở hữu danh hiệu này');
          }
        } else {
          txn.set(
            docRef,
            UserReward(
              id: docId,
              userId: uid,
              rewardId: item.id,
              purchasedAt: DateTime.now(),
              isActive: false,
              quantity: 1,
            ).toMap(),
          );
        }

        final updates = <String, dynamic>{
          'total_points':
          FieldValue.increment(-item.costPts),
        };

        if (item.type == RewardType.streakShield) {
          updates['shield_count'] =
              FieldValue.increment(1);
        }

        txn.update(_userDoc(uid), updates);
      });

      return null;
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> activateTag({
    required String uid,
    required String rewardId,
  }) async {
    final batch = _db.batch();

    final activeSnap = await _userRewards
        .where('user_id', isEqualTo: uid)
        .where('is_active', isEqualTo: true)
        .get();

    for (final d in activeSnap.docs) {
      batch.update(d.reference, {
        'is_active': false,
      });
    }

    batch.update(
      _userRewards.doc('${uid}_$rewardId'),
      {
        'is_active': true,
      },
    );

    final rewardSnap =
    await _items.doc(rewardId).get();

    final rewardData =
    rewardSnap.data() as Map<String, dynamic>;

    final tagName =
        rewardData['name']?.toString() ?? '';

    batch.update(_userDoc(uid), {
      'active_tag_name': tagName,
    });

    await batch.commit();
  }

  Future<void> deactivateTag(String uid) async {
    final batch = _db.batch();

    final snap = await _userRewards
        .where('user_id', isEqualTo: uid)
        .where('is_active', isEqualTo: true)
        .get();

    for (final d in snap.docs) {
      batch.update(d.reference, {
        'is_active': false,
      });
    }

    batch.update(_userDoc(uid), {
      'active_tag_name': '',
    });

    await batch.commit();
  }

  Future<bool> consumeStreakShield({
    required String uid,
    required String shieldRewardId,
  }) async {
    final docRef =
    _userRewards.doc('${uid}_$shieldRewardId');

    bool used = false;

    await _db.runTransaction((txn) async {
      final snap = await txn.get(docRef);

      if (!snap.exists) return;

      final data =
      snap.data() as Map<String, dynamic>;

      final qty =
          (data['quantity'] as num?)?.toInt() ?? 0;

      if (qty <= 0) return;

      txn.update(docRef, {
        'quantity': qty - 1,
      });

      txn.update(_userDoc(uid), {
        'shield_count':
        FieldValue.increment(-1),
      });

      used = true;
    });

    return used;
  }
}