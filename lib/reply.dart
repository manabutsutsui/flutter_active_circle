import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReplyScreen extends StatefulWidget {
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String senderImage;

  const ReplyScreen(
      {required this.senderId,
      required this.senderName,
      required this.recipientId,
      required this.recipientName,
      required this.senderImage,
      super.key});

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _controller.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': widget.senderId,
        'senderName': widget.senderName,
        'senderImage': widget.senderImage,
        'recipientId': widget.recipientId,
        'recipientName': widget.recipientName,
        'message': _controller.text,
        'timestamp': Timestamp.now(),
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
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${widget.recipientName}さんにメッセージを送信',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
