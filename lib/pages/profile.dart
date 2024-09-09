import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../parts/app_drawer.dart';
import 'profile_edit.dart';
import 'following.dart';
import 'follower.dart';
import 'profile_detail.dart';
import 'post_detail.dart';

class Profile extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const Profile({
    super.key,
    required this.userId,
    this.isCurrentUser = true,
  });

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  String _username = '';
  String _imageUrl = '';
  int _followingCount = 0;
  int _followerCount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    // フォロー数を取得
    final followingSnapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.userId)
        .collection('following')
        .get();
    
    // フォロワー数を取得
    final followerSnapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.userId)
        .collection('followers')
        .get();

    if (mounted) {
      setState(() {
        _followingCount = followingSnapshot.docs.length;
        _followerCount = followerSnapshot.docs.length;
      });
    }
  }

  Future<void> _updateFollowCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final followingDocs = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: user.uid)
          .get();
      
      final followerDocs = await FirebaseFirestore.instance
          .collection('follows')
          .where('followingId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _followingCount = followingDocs.docs.length;
          _followerCount = followerDocs.docs.length;
        });
      }
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ユーザーをブロック'),
          content: const Text('このユーザーをブロックしますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('ブロック', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId != null) {
                  await FirebaseFirestore.instance.collection('blocks').add({
                    'blockedBy': currentUserId,
                    'blockedUser': widget.userId,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ユーザーをブロックしました')),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        actions: widget.isCurrentUser
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.block),
                  onPressed: () {
                    _showBlockDialog();
                  },
                ),
              ],
      ),
      drawer: widget.isCurrentUser ? AppDrawer() : null,
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Following(
                      userId: widget.userId,
                      onFollowChanged: _updateFollowCounts,
                    )),
                  );
                },
                child: _buildStatColumn('フォロー中', _followingCount.toString()),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Follower(
                      userId: widget.userId,
                      onFollowChanged: _updateFollowCounts,
                    )),
                  );
                },
                child: _buildStatColumn('フォロワー', _followerCount.toString()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.isCurrentUser)
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEdit()),
                );
                if (result == true) {
                  await _loadProfileData();
                }
              },
              style: ElevatedButton.styleFrom(),
              child: const Text('プロフィールを編集'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileDetail(userId: widget.userId)),
                );
              },
              style: ElevatedButton.styleFrom(),
              child: const Text('プロフィール詳細'),
            ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on)),
              Tab(icon: Icon(Icons.favorite)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsGrid(),
                _buildLikesGrid(),
              ],
            ),
          ),
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

  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('投稿がありません'));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postData: post.data() as Map<String, dynamic>),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post['imageUrl'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('likes', arrayContains: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('いいねした投稿がありません'));
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postData: post.data() as Map<String, dynamic>),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post['imageUrl'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      },
    );
  }
}