import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class PostEdit extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostEdit({Key? key, required this.postData}) : super(key: key);

  @override
  PostEditState createState() => PostEditState();
}

class PostEditState extends State<PostEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedSportTag;
  File? _image;
  final picker = ImagePicker();
  bool _isUpdating = false;

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.postData['title']);
    _contentController = TextEditingController(text: widget.postData['content']);
    _selectedSportTag = widget.postData['sportTag'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(File image) async {
    try {
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
    } catch (e) {
      print('画像のアップロードに失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像のアップロードに失敗しました。')),
      );
    }
    return null;
  }

  Future<void> _updatePost() async {
    if (_formKey.currentState!.validate() && _selectedSportTag != null) {
      setState(() {
        _isUpdating = true;
      });

      try {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _uploadImage(_image!);
          if (imageUrl == null) {
            throw Exception('画像のアップロードに失敗しました');
          }
        }

        final updateData = {
          'title': _titleController.text,
          'content': _contentController.text,
          'sportTag': _selectedSportTag,
          if (imageUrl != null) 'imageUrl': imageUrl,
        };

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postData['postId'])
            .update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('投稿を更新しました')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿の更新に失敗しました: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
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
                    setState(() {
                      _selectedSportTag = _sportTags[index];
                    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿を編集', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : Image.network(widget.postData['imageUrl'], fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'タイトルを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: '内容'),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '内容を入力してください';
                      }
                      return null;
                    },
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updatePost,
                child: _isUpdating
                    ? const CircularProgressIndicator()
                    : const Text('更新'),
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
    );
  }
}
