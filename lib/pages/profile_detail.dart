import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileDetail extends StatefulWidget {
  final String userId;

  const ProfileDetail({super.key, required this.userId});

  @override
  ProfileDetailState createState() => ProfileDetailState();
}

class ProfileDetailState extends State<ProfileDetail> {
  String _nickname = '';
  String _bio = '';
  String _gender = '';
  DateTime? _birthDate;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.userId)
        .get();
    if (doc.exists) {
      setState(() {
        _nickname = doc.data()?['nickName'] ?? '';
        _bio = doc.data()?['bio'] ?? '';
        _gender = doc.data()?['gender'] ?? '未設定';
        _birthDate = doc.data()?['birthDate']?.toDate();
        _profileImageUrl = doc.data()?['profileImageUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール詳細',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoTile('名前', _nickname),
          _buildInfoTile('自己紹介', _bio),
          _buildInfoTile('性別', _gender),
          _buildInfoTile('生年月日', _birthDate == null
              ? '未設定'
              : '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日'),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 18),
          ),
          const Divider(),
        ],
      ),
    );
  }
}