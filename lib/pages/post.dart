import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'home.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  PostPageState createState() => PostPageState();
}

class PostPageState extends State<PostPage> {
  File? _image;
  final picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedSportTag;
  bool _isPosting = false;

  final List<String> _sportTags = [
    '陸上',
    'サッカー',
    'バスケットボール',
    '野球',
    'テニス',
    'バレーボール',
    'ラグビー',
    'バドミントン',
    '体操',
    '柔道',
    '水泳',
    '卓球',
    'その他',
  ];

  int _selectedIndex = 0;

  Future<String?> _uploadImage(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 画像を圧縮
        final bytes = await image.readAsBytes();
        final compressedImage = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 500,
          minHeight: 500,
          quality: 85,
          format: CompressFormat.jpeg,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        await storageRef.putData(compressedImage, SettableMetadata(contentType: 'image/jpeg'));
        final imageUrl = await storageRef.getDownloadURL();
        
        return imageUrl;
      }
    } catch (e) {
      print('画像のアップロードに失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像のアップロードに失敗しました。')),
      );
    }
    return null;
  }

  Future<void> _post() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedSportTag == null ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全ての項目を入力してください')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final userProfile = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      final userName = userProfile.data()?['nickName'] ?? '名無し';
      final userImageUrl = userProfile.data()?['profileImageUrl'] ?? '';

      final imageUrl = await _uploadImage(_image!);
      if (imageUrl == null) {
        throw Exception('画像のアップロードに失敗しました');
      }

      final userRef = FirebaseFirestore.instance.collection('profiles').doc(user.uid);
      final postRef = userRef.collection('posts').doc();

      await postRef.set({
        'userId': user.uid,
        'userName': userName,
        'userImageUrl': userImageUrl,
        'title': _titleController.text,
        'content': _contentController.text,
        'sportTag': _selectedSportTag,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'searchableFields': [
          _titleController.text.toLowerCase(),
          userName.toLowerCase(),
          _selectedSportTag!.toLowerCase(),
        ],
        'postId': postRef.id,
      });

      // メインの posts コレクションにも同じデータを保存
      await FirebaseFirestore.instance.collection('posts').doc(postRef.id).set({
        'userId': user.uid,
        'userName': userName,
        'userImageUrl': userImageUrl,
        'title': _titleController.text,
        'content': _contentController.text,
        'sportTag': _selectedSportTag,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'searchableFields': [
          _titleController.text.toLowerCase(),
          userName.toLowerCase(),
          _selectedSportTag!.toLowerCase(),
        ],
        'postId': postRef.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿が完了しました')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future getImage(ImageSource source) async {
    try {
        final pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
            setState(() {
                _image = File(pickedFile.path);
            });
        } else {
            throw Exception('画像が選択されませんでした');
        }
    } catch (e) {
        print('画像の取得に失敗しました: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像の取得に失敗しました。')),
        );
    }
  }

  void _showSportTagPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Container(
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('キャンセル'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('完了'),
                      onPressed: () {
                        setState(() {
                          _selectedSportTag = _sportTags[_selectedIndex];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    _selectedIndex = index;
                  },
                  children: _sportTags.map((String tag) {
                    return Center(child: Text(tag));
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('投稿', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.landscape,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _showSportTagPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedSportTag ?? 'スポーツタグ'),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isPosting ? null : _post,
                        child: _isPosting
                            ? const CircularProgressIndicator()
                            : const Text('投稿'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => getImage(ImageSource.camera),
              tooltip: '写真を撮る',
              child: const Icon(Icons.camera_alt),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: () => getImage(ImageSource.gallery),
              tooltip: 'ギャラリーから選択',
              child: const Icon(Icons.photo_library),
            ),
          ],
        ),
      ),
    );
  }
}