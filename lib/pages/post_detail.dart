import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';

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
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: widget.postData['userId'])
          .get();

      setState(() {
        _isFollowing = followDoc.docs.isNotEmpty;
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
      final likeDoc = await FirebaseFirestore.instance
          .collection('likes')
          .where('postId', isEqualTo: widget.postData['postId'])
          .where('userId', isEqualTo: currentUserId)
          .get();

      setState(() {
        _isLiked = likeDoc.docs.isNotEmpty;
      });
    }

    final likeCountDoc = await FirebaseFirestore.instance
        .collection('likes')
        .where('postId', isEqualTo: widget.postData['postId'])
        .get();

    setState(() {
      _likeCount = likeCountDoc.docs.length;
    });
  }

  Future<void> _toggleFollow() async {
    if (currentUserId == null) return;

    if (_isFollowing) {
      // フォロー解除
      final followDoc = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: widget.postData['userId'])
          .get();

      for (var doc in followDoc.docs) {
        await doc.reference.delete();
      }
    } else {
      // フォロー
      await FirebaseFirestore.instance.collection('follows').add({
        'followerId': currentUserId,
        'followingId': widget.postData['userId'],
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

    if (_isLiked) {
      // いいね解除
      final likeDoc = await FirebaseFirestore.instance
          .collection('likes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (var doc in likeDoc.docs) {
        await doc.reference.delete();
      }
    } else {
      // いいね
      await FirebaseFirestore.instance.collection('likes').add({
        'postId': postId,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _isLiked = !_isLiked;
    });

    await _checkLikeStatus();
  }

  Future<String> _getUserProfileImageUrl(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('profiles').doc(userId).get();
    return userDoc.data()?['profileImageUrl'] ?? '';
  }

  Future<void> _deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postData['postId'])
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
                icon: const Icon(Icons.delete, size: 30,),
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
      body: SingleChildScrollView(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.postData['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '投稿者: ${widget.postData['userName'] ?? ''}',
                          ),
                        ],
                      ),
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
                  const SizedBox(height: 8),
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
    );
  }
}