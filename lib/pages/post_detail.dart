import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import '../parts/ad_banner.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostDetailScreen({super.key, required this.postData});

  @override
  PostDetailScreenState createState() => PostDetailScreenState();
}

class PostDetailScreenState extends State<PostDetailScreen> {
  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 0;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isOwnPost = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
    _checkIfOwnPost();
    _checkLikeStatus();
  }

  Future<void> _checkIfFollowing() async {
    if (currentUserId != null) {
      final followDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.postData['userId'])
          .get();

      setState(() {
        _isFollowing = followDoc.exists;
      });
    }
  }

  void _checkIfOwnPost() {
    setState(() {
      _isOwnPost = currentUserId == widget.postData['userId'];
    });
  }

  Future<void> _checkLikeStatus() async {
    if (currentUserId != null) {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postData['postId']);

      final likeDoc = await postRef
          .collection('likes')
          .doc(currentUserId)
          .get();

      setState(() {
        _isLiked = likeDoc.exists;
      });

      final likeCountDoc = await postRef.get();

      setState(() {
        _likeCount = likeCountDoc.data()?['likeCount'] ?? 0;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (currentUserId == null) return;

    if (_isFollowing) {
      // フォロー解除
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.postData['userId'])
          .delete();

      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.postData['userId'])
          .collection('followers')
          .doc(currentUserId)
          .delete();
    } else {
      // フォロー
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.postData['userId'])
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.postData['userId'])
          .collection('followers')
          .doc(currentUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 通知を作成
      await FirebaseFirestore.instance.collection('notifications').add({
        'senderId': currentUserId,
        'senderImageUrl': await _getUserProfileImageUrl(currentUserId!),
        'recipientId': widget.postData['userId'],
        'message': 'あなたをフォローしました',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  Future<void> _toggleLike() async {
    if (currentUserId == null) return;

    final postId = widget.postData['postId'];
    if (postId == null) {
      print('Error: postId is null');
      return;
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);

      if (!postSnapshot.exists) {
        throw Exception('Post does not exist!');
      }

      final currentLikes = postSnapshot.data()?['likes'] as Map<String, dynamic>? ?? {};
      final isLiked = currentLikes[currentUserId] == true;

      if (isLiked) {
        // いいね解除
        currentLikes.remove(currentUserId);
        transaction.update(postRef, {
          'likes': currentLikes,
          'likeCount': FieldValue.increment(-1),
        });
        await postRef.collection('likes').doc(currentUserId).delete();
      } else {
        // いいね
        currentLikes[currentUserId!] = true;
        transaction.update(postRef, {
          'likes': currentLikes,
          'likeCount': FieldValue.increment(1),
        });
        await postRef.collection('likes').doc(currentUserId).set({});
      }
    });

    // 状態を更新
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  Future<String> _getUserProfileImageUrl(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(userId)
        .get();
    return userDoc.data()?['profileImageUrl'] ?? '';
  }

  Future<void> _deletePost() async {
    try {
      final postId = widget.postData['postId'];
      final userId = widget.postData['userId'];

      // メインの posts コレクションから削除
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .delete();

      // ユーザーの posts サブコレクションから削除
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿を削除しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿の削除に失敗しました')),
        );
      }
    }
  }

  void _showReportDialog() {
    String reportReason = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('投稿を報告'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('報告理由を記入してください：'),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                onChanged: (value) {
                  reportReason = value;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '報告理由を入力',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reportReason.isNotEmpty) {
                  _reportPost(reportReason);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('報告する'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reportPost(String reason) async {
    if (currentUserId == null) return;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'postId': widget.postData['postId'],
        'reporterId': currentUserId,
        'reportedUserId': widget.postData['userId'],
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿を報告しました')),
      );
    } catch (e) {
      print('Error reporting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿の報告に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                if (widget.postData['userId'] != currentUserId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profile(
                        userId: widget.postData['userId'],
                        isCurrentUser: false,
                      ),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage:
                    NetworkImage(widget.postData['userImageUrl'] ?? ''),
                radius: 20,
              ),
            ),
            if (_isOwnPost)
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 30,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('確認'),
                        content: const Text('この投稿を削除しますか？'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('キャンセル'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('削除'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deletePost();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              )
            else if (!_isOwnPost)
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey : Colors.blue,
                  ),
                  child: Text(
                    _isFollowing ? 'フォロー中' : 'フォロー',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          const AdBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.postData['imageUrl'] ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.postData['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _toggleLike,
                                  icon: Icon(
                                    _isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: _isLiked ? Colors.red : Colors.grey,
                                    size: 30,
                                  ),
                                ),
                                Text(
                                  '$_likeCount',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '投稿者: ${widget.postData['userName'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.flag),
                              onPressed: _showReportDialog,
                            ),
                          ],
                        ),
                        Text(
                          widget.postData['content'] ?? '',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}