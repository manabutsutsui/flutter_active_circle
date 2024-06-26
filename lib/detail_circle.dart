import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'invite_circle.dart';

class CircleDetailScreen extends StatelessWidget {
  final String circleId;

  CircleDetailScreen({required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('サークル詳細'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('circles').doc(circleId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final circleData = snapshot.data!.data() as Map<String, dynamic>;
          final members = circleData['members'] as List<dynamic>;

          return ListView(
            children: [
              ListTile(
                title: Text('サークル名: ${circleData['name']}'),
              ),
              ListTile(
                title: Text('メンバー'),
                subtitle: Column(
                  children: members.map((memberId) => Text(memberId)).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => InviteUserScreen(circleId: circleId),
                  ));
                },
                child: Text('メンバーを招待'),
              ),
            ],
          );
        },
      ),
    );
  }
}
