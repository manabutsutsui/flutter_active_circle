import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_detail.dart';
import '../services/block_service.dart';
import '../services/report_service.dart'; 
import '../utils/date_formatter.dart';
import '../parts/ad_native.dart';

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
                
                return FutureBuilder<List<String>>(
                  future: BlockService.getBlockedUserIds(),
                  builder: (context, blockSnapshot) {
                    if (blockSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                
                    final blockedUserIds = blockSnapshot.data ?? [];
                
                    final filteredPosts = snapshot.data!.docs
                        .where((doc) => !blockedUserIds.contains(doc['userId']))
                        .toList();
                
                    return ListView.builder(
                      itemCount: (filteredPosts.length / 3).ceil() * 2,
                      itemBuilder: (context, index) {
                        if (index.isOdd) {
                          // 広告を表示
                          return const NativeAdWidget();
                        } else {
                          // 投稿を3つ表示
                          final startIndex = (index ~/ 2) * 3;
                          final endIndex = startIndex + 3 > filteredPosts.length ? filteredPosts.length : startIndex + 3;
                          return Column(
                            children: filteredPosts.sublist(startIndex, endIndex).map((post) {
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
                                                  '投稿者: ${data['userName'] ?? ''} ${DateFormatter.formatDate(data['createdAt'])}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (String result) async {
                                              switch (result) {
                                                case '報告':
                                                  ReportService.showReportDialog(context, (reason) async {
                                                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                                    if (currentUserId != null) {
                                                      try {
                                                        await ReportService.reportPost(
                                                          postId: post.id,
                                                          reporterId: currentUserId,
                                                          reportedUserId: data['userId'] ?? '',
                                                          reason: reason,
                                                        );
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('投稿を報告しました')),
                                                        );
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('投稿の報告に失敗しました')),
                                                        );
                                                      }
                                                    }
                                                  });
                                                  break;
                                                case 'ブロック':
                                                  await BlockService.blockUser(data['userId']);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('ユーザーをブロックしました')),
                                                  );
                                                  break;
                                              }
                                            },
                                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: '報告',
                                                height: 24,
                                                child: Text('報告', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'ブロック',
                                                height: 24,
                                                child: Text('ブロック', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        }
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
                
                    final filteredPosts = postSnapshot.data!.docs;
                
                    return ListView.builder(
                      itemCount: (filteredPosts.length / 3).ceil() * 2,
                      itemBuilder: (context, index) {
                        if (index.isOdd) {
                          // 広告を表示
                          return const NativeAdWidget();
                        } else {
                          // 投稿を3つ表示
                          final startIndex = (index ~/ 2) * 3;
                          final endIndex = startIndex + 3 > filteredPosts.length ? filteredPosts.length : startIndex + 3;
                          return Column(
                            children: filteredPosts.sublist(startIndex, endIndex).map((post) {
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
                                                  '投稿者: ${data['userName'] ?? ''} ${DateFormatter.formatDate(data['createdAt'])}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (String result) async {
                                              switch (result) {
                                                case '報告':
                                                  ReportService.showReportDialog(context, (reason) async {
                                                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                                    if (currentUserId != null) {
                                                      try {
                                                        await ReportService.reportPost(
                                                          postId: post.id,
                                                          reporterId: currentUserId,
                                                          reportedUserId: data['userId'] ?? '',
                                                          reason: reason,
                                                        );
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('投稿を報告しました')),
                                                        );
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('投稿の報告に失敗しました')),
                                                        );
                                                      }
                                                    }
                                                  });
                                                  break;
                                                case 'ブロック':
                                                  await BlockService.blockUser(data['userId']);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('ユーザーをブロックしました')),
                                                  );
                                                  break;
                                              }
                                            },
                                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: '報告',
                                                height: 24,
                                                child: Text('報告', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'ブロック',
                                                height: 24,
                                                child: Text('ブロック', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        }
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