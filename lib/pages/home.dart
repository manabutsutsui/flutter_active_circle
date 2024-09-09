import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(
                child: Text(
                  'おすすめ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  'フォロー中',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            indicatorColor: Colors.blue,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article, size: 86, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('投稿がありません', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }
                
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) {
                  return const Center(child: Text('ログインしてください'));
                }
                
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('blocks')
                      .where('blockedBy', isEqualTo: currentUserId)
                      .get(),
                  builder: (context, blockSnapshot) {
                    if (blockSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                
                    final blockedUserIds = blockSnapshot.data?.docs
                        .map((doc) => doc['blockedUser'] as String)
                        .toList() ?? [];
                
                    final filteredPosts = snapshot.data!.docs
                        .where((doc) => !blockedUserIds.contains(doc['userId']))
                        .toList();
                
                    return ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        final data = post.data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(postData: data),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  data['imageUrl'] ?? '',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(data['userImageUrl'] ?? ''),
                                      radius: 25,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '投稿者: ${data['userName'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('following')
                  .snapshots(),
              builder: (context, followSnapshot) {
                if (followSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (followSnapshot.hasError) {
                  return Center(child: Text('エラーが発生しました: ${followSnapshot.error}'));
                }
                
                final followingIds = followSnapshot.data?.docs
                    .map((doc) => doc.id)
                    .toList() ?? [];
                
                if (followingIds.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 86, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('フォロー中のユーザーがいません', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }
                
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', whereIn: followingIds)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                
                    if (postSnapshot.hasError) {
                      return Center(child: Text('エラーが発生しました: ${postSnapshot.error}'));
                    }
                
                    if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('フォロー中のユーザーの投稿がありません'));
                    }
                
                    return ListView.builder(
                      itemCount: postSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final post = postSnapshot.data!.docs[index];
                        final data = post.data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(postData: data),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  data['imageUrl'] ?? '',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(data['userImageUrl'] ?? ''),
                                      radius: 25,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '投稿者: ${data['userName'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}