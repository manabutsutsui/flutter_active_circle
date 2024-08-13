import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../parts/app_drawer.dart';
import 'profile_edit.dart';
import 'following.dart';
import 'follower.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  String _username = '';
  String _imageUrl = '';
  int _followingCount = 0;
  int _followerCount = 0;
  int _postCount = 0;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _username = doc.data()?['nickName'] ?? '';
          _imageUrl = doc.data()?['profileImageUrl'] ?? '';
        });
      }

      // フォロー数を取得
      final followingDocs = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: user.uid)
          .get();
      
      // フォロワー数を取得
      final followerDocs = await FirebaseFirestore.instance
          .collection('follows')
          .where('followingId', isEqualTo: user.uid)
          .get();

      // 投稿数を取得（postsコレクションがある場合）
      final postDocs = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _followingCount = followingDocs.docs.length;
          _followerCount = followerDocs.docs.length;
          _postCount = postDocs.docs.length;
        });
      }
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
      drawer: AppDrawer(),
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
                      userId: FirebaseAuth.instance.currentUser!.uid,
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
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      onFollowChanged: _updateFollowCounts,
                    )),
                  );
                },
                child: _buildStatColumn('フォロワー', _followerCount.toString()),
              ),
              _buildStatColumn('ポスト', _postCount.toString()),
            ],
          ),
          const SizedBox(height: 20),
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
            style: ElevatedButton.styleFrom(
            ),
            child: const Text('プロフィールを編集'),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
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
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post['imageUrl'] ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikesGrid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('likes')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, likesSnapshot) {
        if (likesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!likesSnapshot.hasData || likesSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('いいねした投稿がありません'));
        }

        final likedPostIds = likesSnapshot.data!.docs
            .map((doc) => doc['postId'] as String?)
            .where((postId) => postId != null)
            .cast<String>()
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where(FieldPath.documentId, whereIn: likedPostIds)
              .snapshots(),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!postsSnapshot.hasData || postsSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('いいねした投稿が見つかりません'));
            }
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: postsSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final post = postsSnapshot.data!.docs[index];
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}