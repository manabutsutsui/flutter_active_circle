import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileDetail extends StatefulWidget {
  final String userId;

  const ProfileDetail({super.key, required this.userId});

  @override
  ProfileDetailState createState() => ProfileDetailState();
}

class ProfileDetailState extends State<ProfileDetail> {
  String _username = '';
  String _imageUrl = '';
  int _followingCount = 0;
  int _followerCount = 0;
  int _postCount = 0;

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
    if (doc.exists && mounted) {
      setState(() {
        _username = doc.data()?['nickName'] ?? '';
        _imageUrl = doc.data()?['profileImageUrl'] ?? '';
      });
    }

    final followingDocs = await FirebaseFirestore.instance
        .collection('follows')
        .where('followerId', isEqualTo: widget.userId)
        .get();
    
    final followerDocs = await FirebaseFirestore.instance
        .collection('follows')
        .where('followingId', isEqualTo: widget.userId)
        .get();

    final postDocs = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (mounted) {
      setState(() {
        _followingCount = followingDocs.docs.length;
        _followerCount = followerDocs.docs.length;
        _postCount = postDocs.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _imageUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_imageUrl),
                )
              : const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
          const SizedBox(height: 10),
          Text(
            _username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('フォロー中', _followingCount.toString()),
              _buildStatColumn('フォロワー', _followerCount.toString()),
              _buildStatColumn('ポスト', _postCount.toString()),
            ],
          ),
          // ここに他のプロフィール情報を追加できます
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}