import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'parts/sign_up_with_google.dart';
import 'parts/sign_up_with_apple.dart';
import 'parts/buttom_button.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
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
        bottomNavigationBar: const ButtomButton(),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('recipientId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('メッセージがありません'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['message'] ?? 'No message'),
                subtitle: Text('From: ${data['senderName'] ?? 'Unknown'}'),
                trailing: Text(data['timestamp']?.toDate().toString() ?? ''),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: const ButtomButton(),
    );
  }
}
