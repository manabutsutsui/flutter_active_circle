import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteUserScreen extends StatefulWidget {
  final String circleId;

  InviteUserScreen({required this.circleId});

  @override
  _InviteUserScreenState createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final TextEditingController _emailController = TextEditingController();

  void _inviteUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _emailController.text.isNotEmpty) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final invitedUserId = userSnapshot.docs.first.id;

        await FirebaseFirestore.instance.collection('invitations').add({
          'circleId': widget.circleId,
          'invitedBy': user.uid,
          'invitedUser': invitedUserId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('招待を送信しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザーが見つかりません')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ユーザーを招待'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'ユーザーのメールアドレス'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _inviteUser,
              child: Text('招待'),
            ),
          ],
        ),
      ),
    );
  }
}
