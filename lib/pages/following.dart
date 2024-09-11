import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/follow_service.dart';
import 'profile.dart';

class Following extends StatefulWidget {
  final String userId;
  final VoidCallback onFollowChanged;

  const Following({super.key, required this.userId, required this.onFollowChanged});

  @override
  FollowingState createState() => FollowingState();
}

class FollowingState extends State<Following> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _toggleFollow(String followingId) async {
    await FollowService.toggleFollow(followingId);
    setState(() {});
    widget.onFollowChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォロー中', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.userId)
            .collection('following')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('フォロー中のユーザーはいません'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final followingId = snapshot.data!.docs[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('profiles').doc(followingId).get(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('読み込み中...'));
                  }
                  if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
                    return const ListTile(title: Text('ユーザー情報が見つかりません'));
                  }
                  final profileData = profileSnapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(profileData['profileImageUrl'] ?? ''),
                    ),
                    title: Text(profileData['nickName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold),),
                    trailing: currentUserId == widget.userId
                        ? ElevatedButton(
                            onPressed: () => _toggleFollow(followingId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text(
                              'フォロー中',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                    onTap: () {
                      if (followingId != currentUserId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profile(
                              userId: followingId,
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
      ),
    );
  }
}