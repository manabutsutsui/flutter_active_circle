import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'detail_circle.dart';

class CreateCircleScreen extends StatefulWidget {
  @override
  _CreateCircleScreenState createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final TextEditingController _circleNameController = TextEditingController();

  void _createCircle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _circleNameController.text.isNotEmpty) {
      final circleRef = await FirebaseFirestore.instance.collection('circles').add({
        'name': _circleNameController.text,
        'createdBy': user.uid,
        'members': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // サークル作成後にサークル詳細画面に遷移
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CircleDetailScreen(circleId: circleRef.id),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('サークル作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _circleNameController,
              decoration: InputDecoration(labelText: 'サークル名'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createCircle,
              child: Text('作成'),
            ),
          ],
        ),
      ),
    );
  }
}
