import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> blockUser(String blockedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      await _firestore.collection('blocks').add({
        'blockedBy': currentUserId,
        'blockedUser': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<bool> isBlocked(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      final querySnapshot = await _firestore
          .collection('blocks')
          .where('blockedBy', isEqualTo: currentUserId)
          .where('blockedUser', isEqualTo: userId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    }
    return false;
  }

  static Future<List<String>> getBlockedUserIds() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      final querySnapshot = await _firestore
          .collection('blocks')
          .where('blockedBy', isEqualTo: currentUserId)
          .get();
      return querySnapshot.docs.map((doc) => doc['blockedUser'] as String).toList();
    }
    return [];
  }
}
