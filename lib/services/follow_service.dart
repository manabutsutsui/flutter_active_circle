import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> toggleFollow(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final followDoc = await _firestore
        .collection('profiles')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .get();

    if (followDoc.exists) {
      // フォロー解除
      await _unfollow(currentUserId, targetUserId);
    } else {
      // フォロー
      await _follow(currentUserId, targetUserId);
    }
  }

  static Future<void> _unfollow(String currentUserId, String targetUserId) async {
    await _firestore
        .collection('profiles')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .delete();

    await _firestore
        .collection('profiles')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .delete();
  }

  static Future<void> _follow(String currentUserId, String targetUserId) async {
    await _firestore
        .collection('profiles')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('profiles')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    // フォローした人の名前を取得
    final currentUserDoc = await _firestore.collection('profiles').doc(currentUserId).get();
    final currentUserName = currentUserDoc.data()?['nickName'] ?? '名前なし';

    // 通知を作成
    await _firestore.collection('notifications').add({
      'senderId': currentUserId,
      'senderImageUrl': await _getUserProfileImageUrl(currentUserId),
      'recipientId': targetUserId,
      'message': '$currentUserNameさんがあなたをフォローしました',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> _getUserProfileImageUrl(String userId) async {
    final userDoc = await _firestore.collection('profiles').doc(userId).get();
    return userDoc.data()?['profileImageUrl'] ?? '';
  }

  static Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final followDoc = await _firestore
        .collection('profiles')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .get();

    return followDoc.exists;
  }
}
