import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'parts/sign_up_with_google.dart';
import 'parts/sign_up_with_apple.dart';
import 'parts/buttom_button.dart';
import 'reply.dart';
import 'parts/ad_banner.dart';
import 'package:intl/intl.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  String? userProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
  }

  Future<void> _loadUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      setState(() {
        userProfileImage = doc.data()?['profileImage'];
      });
    }
  }

  Future<void> blockUser(String blockedUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('blocks').add({
        'blockedBy': currentUser.uid,
        'blockedUser': blockedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
            onPressed: () {
              context.go('/home');
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text('メッセージリスト',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ログインしてください'),
                    SignUpWithGoogle(),
                    SignUpWithApple(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdBanner(),
            ButtomButton(),
          ],
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
          onPressed: () {
            context.go('/home');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('blocks')
            .where('blockedBy', isEqualTo: user.uid)
            .get(),
        builder: (context, blockSnapshot) {
          if (blockSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (blockSnapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${blockSnapshot.error}'));
          }

          final blockedUserIds = blockSnapshot.data?.docs
                  .map((doc) => doc['blockedUser'])
                  .toSet() ??
              {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('recipientId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('メッセージがありません'));
              }

              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !blockedUserIds.contains(data['senderId']);
              }).toList();

              return ListView(
                children: filteredDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(data['senderImage']),
                      radius: 32,
                    ),
                    title: Text(
                      data['message'] ?? 'No message',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: (data['isRead'] ?? false)
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('From: ${data['senderName'] ?? 'Unknown'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MM月dd日 HH:mm')
                              .format((data['timestamp'] as Timestamp).toDate()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.block),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('確認'),
                                  content: const Text('このユーザーをブロックしますか？'),
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
                                      child: const Text('ブロック'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              await blockUser(data['senderId']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ユーザーをブロックしました')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // メッセージを既読にする
                      FirebaseFirestore.instance
                          .collection('messages')
                          .doc(doc.id)
                          .update({'isRead': true});

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('メッセージ詳細'),
                            content: Text(data['message'] ?? 'No message'),
                            actions: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ReplyScreen(
                                            senderId: data['recipientId'],
                                            senderName: data['recipientName'],
                                            recipientId: data['senderId'],
                                            recipientName: data['senderName'],
                                            senderImage: userProfileImage ??
                                                '', // ログインユーザーの画像を送信
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text('${data['senderName']}に返信する'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('閉じる'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdBanner(),
          ButtomButton(),
        ],
      ),
    );
  }
}
