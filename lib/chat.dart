import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String circleId;
  final String circleName;

  const ChatScreen(
      {required this.circleId, required this.circleName, super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  late User? user;
  late Future<DocumentSnapshot> profileDoc;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    profileDoc =
        FirebaseFirestore.instance.collection('profiles').doc(user?.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.circleName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        body: const Center(
          child: Text('ログインしてください'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.circleName,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('circles')
                  .doc(widget.circleId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('メッセージがありません'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(data['senderId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const CircleAvatar(
                              child: Icon(Icons.person),
                            );
                          }
                          final profileData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final profileImage =
                              profileData?['profileImage'] as String?;
                          return profileImage != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(profileImage),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.person),
                                );
                        },
                      ),
                      title: Text(
                        data['message'],
                      ),
                      subtitle: Text(
                        data['senderName'] +
                            ' ' +
                            DateFormat('MM月dd日HH:mm').format(
                                (data['timestamp'] as Timestamp).toDate()),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final message = _messageController.text;
                    if (message.isNotEmpty) {
                      final profileData =
                          (await profileDoc).data() as Map<String, dynamic>?;
                      final String senderName =
                          profileData?['nickName'] as String? ?? 'Unknown';
                      await FirebaseFirestore.instance
                          .collection('circles')
                          .doc(widget.circleId)
                          .collection('messages')
                          .add({
                        'senderId': user.uid,
                        'senderName': senderName,
                        'message': message,
                        'timestamp': Timestamp.now(),
                      });
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
