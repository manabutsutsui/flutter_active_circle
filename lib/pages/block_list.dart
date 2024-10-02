import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';

class BlockList extends StatefulWidget {
  const BlockList({super.key});

  @override
  BlockListState createState() => BlockListState();
}

class BlockListState extends State<BlockList> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _unblockUser(String blockId) async {
    await FirebaseFirestore.instance.collection('blocks').doc(blockId).delete();
    _scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('ブロックを解除しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ブロックリスト', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blocks')
            .where('blockedBy', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
            
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }
            
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 86, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ブロックしているユーザーはいません', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
            
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final blockData = snapshot.data!.docs[index];
              final blockedUserId = blockData['blockedUser'] as String;
            
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('profiles').doc(blockedUserId).get(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('読み込み中...'));
                  }
            
                  if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
                    return const ListTile(title: Text('ユーザー情報が見つかりません'));
                  }
            
                  final profileData = profileSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = profileData['nickName'] ?? '名前なし';
                  final userImageUrl = profileData['profileImageUrl'] ?? '';
            
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userImageUrl.isNotEmpty ? NetworkImage(userImageUrl) : null,
                      child: userImageUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userName),
                    trailing: ElevatedButton(
                      onPressed: () => _unblockUser(blockData.id),
                      child: const Text('ブロック解除'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Profile(userId: blockedUserId, isCurrentUser: false),
                        ),
                      );
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