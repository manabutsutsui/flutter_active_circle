import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  MessageScreenState createState() => MessageScreenState();
}

class MessageScreenState extends State<MessageScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
      ),
      body: const Center(
        child: Text('メッセージ画面の内容をここに追加します'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'フォロー中'),
                        Tab(text: '検索'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildFollowingList(),
                          _buildSearchList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.mail),
      ),
    );
  }

  Widget _buildFollowingList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('ユーザーがログインしていません'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('フォロー中のユーザーはいません'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final followData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final followingId = followData['followingId'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(followingId)
                  .get(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const ListTile(title: Text('読み込み中...'));
                }

                if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
                  return const ListTile(title: Text('ユーザー情報が見つかりません'));
                }

                final profileData =
                    profileSnapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        NetworkImage(profileData['profileImageUrl'] ?? ''),
                  ),
                  title: Text(profileData['nickName'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          recipientId: profileSnapshot.data!.id,
                          recipientName: profileData['nickName'] ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchList() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ニックネーム',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5),
                ),
                onChanged: (value) {
                  setModalState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _searchUsers()
                  : const Center(child: Text('ユーザーを検索してください')),
            ),
          ],
        );
      },
    );
  }

  Widget _searchUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('profiles')
          .orderBy('nickName')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ユーザーが見つかりません'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final nickName = userData['nickName'] as String? ?? '';
            if (nickName.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userData['profileImageUrl'] ?? ''),
                ),
                title: Text(nickName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        recipientId: snapshot.data!.docs[index].id,
                        recipientName: nickName,
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}