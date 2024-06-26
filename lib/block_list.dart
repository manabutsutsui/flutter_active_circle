import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class BlockList extends StatefulWidget {
  const BlockList({super.key});

  @override
  State<BlockList> createState() => _BlockListState();
}

class _BlockListState extends State<BlockList> {
  Future<void> _unblockUser(String blockId) async {
    await FirebaseFirestore.instance.collection('blocks').doc(blockId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ユーザーのブロックを解除しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ブロックリスト'),
        ),
        body: const Center(
          child: Text('ログインしてください'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ActiveCircle',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontFamily: 'Pacifico',
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/app');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blocks')
            .where('blockedBy', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ブロックしているユーザーはいません'));
          }

          final blockDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: blockDocs.length,
            itemBuilder: (context, index) {
              final blockData = blockDocs[index].data() as Map<String, dynamic>;
              final blockedUserId = blockData['blockedUser'];
              final blockId = blockDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(blockedUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('読み込み中...'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('ユーザー情報が見つかりません'),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(userData['profileImage']),
                    ),
                    title: Text(userData['nickName']),
                    trailing: IconButton(
                      icon: const Icon(Icons.block),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('確認'),
                              content: const Text('このユーザーのブロックを解除しますか？'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('解除'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          await _unblockUser(blockId);
                        }
                      },
                    ),
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
