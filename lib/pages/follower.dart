import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import '../parts/ad_banner.dart';

class Follower extends StatefulWidget {
  final String userId;
  final VoidCallback onFollowChanged;

  const Follower({super.key, required this.userId, required this.onFollowChanged});

  @override
  FollowerState createState() => FollowerState();
}

class FollowerState extends State<Follower> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<bool> _isFollowing(String followerId) async {
    if (currentUserId == null) return false;

    final followDoc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(currentUserId)
        .collection('following')
        .doc(followerId)
        .get();

    return followDoc.exists;
  }

  Future<void> _toggleFollow(String followerId) async {
    if (currentUserId == null) return;

    final isFollowing = await _isFollowing(followerId);

    if (isFollowing) {
      // フォロー解除
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUserId)
          .collection('following')
          .doc(followerId)
          .delete();

      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(followerId)
          .collection('followers')
          .doc(currentUserId)
          .delete();
    } else {
      // フォロー
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUserId)
          .collection('following')
          .doc(followerId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(followerId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 通知を作成
      await FirebaseFirestore.instance.collection('notifications').add({
        'senderId': currentUserId,
        'senderImageUrl': await _getUserProfileImageUrl(currentUserId!),
        'recipientId': followerId,
        'message': 'あなたをフォローしました',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {});
    widget.onFollowChanged();
  }

  Future<String> _getUserProfileImageUrl(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('profiles').doc(userId).get();
    return userDoc.data()?['profileImageUrl'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォロワー', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Column(
        children: [
          const AdBanner(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(widget.userId)
                  .collection('followers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('フォロワーはいません'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final followerId = snapshot.data!.docs[index].id;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('profiles').doc(followerId).get(),
                      builder: (context, profileSnapshot) {
                        if (profileSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text('読み込み中...'));
                        }
                        if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
                          return const ListTile(title: Text('ユーザー情報が見つかりません'));
                        }
                        final profileData = profileSnapshot.data!.data() as Map<String, dynamic>;
                        return FutureBuilder<bool>(
                          future: _isFollowing(followerId),
                          builder: (context, followSnapshot) {
                            if (followSnapshot.connectionState == ConnectionState.waiting) {
                              return const ListTile(title: Text('読み込み中...'));
                            }
                            final isFollowing = followSnapshot.data ?? false;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(profileData['profileImageUrl'] ?? ''),
                              ),
                              title: Text(profileData['nickName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: currentUserId != followerId
                                  ? ElevatedButton(
                                      onPressed: () => _toggleFollow(followerId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing ? Colors.grey : Colors.blue,
                                      ),
                                      child: Text(
                                        isFollowing ? 'フォロー中' : 'フォロー',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                if (followerId != currentUserId) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Profile(
                                        userId: followerId,
                                        isCurrentUser: false,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}