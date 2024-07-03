import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/filters.dart'; // フィルタリングのユーティリティをインポート

class MessageScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientImage;

  const MessageScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientImage,
  });

  @override
  MessageScreenState createState() => MessageScreenState();
}

class MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final containsProhibited = await containsProhibitedContent(_controller.text);
      if (containsProhibited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('不適切な内容が含まれています。', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),)),
          );
        }
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();

        final senderName = userProfile.data()?['nickName'] ?? 'Unknown';
        final senderImage = userProfile.data()?['profileImage'] ?? '';

        await FirebaseFirestore.instance.collection('messages').add({
          'recipientId': widget.recipientId,
          'recipientName': widget.recipientName,
          'senderId': user.uid,
          'senderName': senderName,
          'senderImage': senderImage,
          'message': _controller.text,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        if (mounted) {
          _controller.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メッセージが送信されました')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ActiveCircle',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontFamily: 'Pacifico',
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${widget.recipientName}さんにメッセージを送信',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              backgroundImage: NetworkImage(widget.recipientImage),
              radius: 48,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'メッセージを入力してください',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('送信'),
            ),
          ],
        ),
      ),
    );
  }
}
