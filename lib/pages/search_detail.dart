import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_detail.dart';
import '../services/report_service.dart';
import '../services/block_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/date_formatter.dart';

class SearchDetailScreen extends StatefulWidget {
  final String category;

  const SearchDetailScreen({super.key, required this.category});

  @override
  SearchDetailScreenState createState() => SearchDetailScreenState();
}

class SearchDetailScreenState extends State<SearchDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '検索結果: ${widget.category}',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('sportTag', isEqualTo: widget.category)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article, size: 86, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('この種目の投稿はまだありません', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final post = snapshot.data!.docs[index];
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
                            backgroundImage:
                                NetworkImage(data['userImageUrl'] ?? ''),
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
                                  ReportService.showReportDialog(context,
                                      (reason) async {
                                    final currentUserId =
                                        FirebaseAuth.instance.currentUser?.uid;
                                    if (currentUserId != null) {
                                      try {
                                        await ReportService.reportPost(
                                          postId: post.id,
                                          reporterId: currentUserId,
                                          reportedUserId: data['userId'] ?? '',
                                          reason: reason,
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('投稿を報告しました')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('投稿の報告に失敗しました')),
                                        );
                                      }
                                    }
                                  });
                                  break;
                                case 'ブロック':
                                  await BlockService.blockUser(data['userId']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('ユーザーをブロックしました')),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: '報告',
                                height: 24,
                                child: Text('報告',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const PopupMenuItem<String>(
                                value: 'ブロック',
                                height: 24,
                                child: Text('ブロック',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
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
      ),
    );
  }
}