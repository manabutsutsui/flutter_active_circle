import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'parts/ad_banner.dart';
import 'parts/app_drawer.dart';
import 'parts/buttom_button.dart';
import 'login_prompt.dart';
import 'utils/filters.dart'; // フィルタリングのユーティリティをインポート
import 'package:permission_handler/permission_handler.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  XFile? _profileImage;
  String? _imageUrl; // Firestoreから取得した画像のURLを保持する
  bool _isEditing = false; // プロフィールが編集中かどうかを追跡するフラグ

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
          _imageUrl = null;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真ライブラリへのアクセスが拒否されました。')),
        );
      }
    }
  }

  Future<String> _uploadImage(File image) async {
    if (!image.existsSync()) {
      throw Exception('選択されたファイルが存在しません。');
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _sportsController.text.isEmpty ||
        _experienceController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'すべてのフィールドを入力してください',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        );
      }
      return;
    }

    // フィルタリングを追加
    final name = _nameController.text;
    final sports = _sportsController.text;
    final experience = _experienceController.text;

    if (await containsProhibitedContent(name) ||
        await containsProhibitedContent(sports) ||
        await containsProhibitedContent(experience)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不適切な内容が含まれています。', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),)),
        );
      }
      return;
    }

    String imageUrl = _imageUrl ?? ''; // 既存の画像URLを使用

    // 新しい画像が選択されている場合のみアップロード
    if (_profileImage != null && File(_profileImage!.path).existsSync()) {
      imageUrl = await _uploadImage(File(_profileImage!.path));
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final profileData = {
      'uid': uid,
      'name': _nameController.text,
      'age': int.parse(_ageController.text),
      'sports': _sportsController.text,
      'experience': _experienceController.text,
      'profileImage': imageUrl,
    };

    await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .set(profileData);

    // メッセージコレクションのsenderImageフィールドを更新
    final messages = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'senderImage': imageUrl});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールが保存されました')),
      );
      context.go('/profile_list');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _isEditing = true; // データが存在するため、編集モード設定
        });
        final data = doc.data();
        _nameController.text = data?['name'] ?? '';
        _ageController.text = data?['age'].toString() ?? '';
        _sportsController.text = data?['sports'] ?? '';
        _experienceController.text = data?['experience'] ?? '';
        _imageUrl = data?['profileImage'] ?? ''; // URLを取得
        if (_imageUrl!.isNotEmpty) {
          _profileImage = XFile(_imageUrl!); // XFileにURLを設定
        }
      } else if (mounted) {
        setState(() {
          _isEditing = false; // データが存在しないため、新規作成モードに設定
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginPrompt();
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ActiveCircle',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontFamily: 'Pacifico',
              )),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: AppDrawer(),
        body: SingleChildScrollView( // SingleChildScrollViewでラップする
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text('プロフィールを設定してください',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名前'),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: '年齢'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _sportsController,
                decoration: const InputDecoration(labelText: '好きなスポーツ'),
              ),
              TextField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: '実績・経験'),
                maxLines: null, // 長い文を入力できるようにする
              ),
              const SizedBox(height: 20),
              _profileImage == null
                  ? const Text('プロフィール写真を選択してください')
                  : ClipOval(
                      child: _imageUrl != null && _imageUrl!.isNotEmpty
                          ? Image.network(
                              _imageUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.account_circle, size: 120),
                            )
                          : Image.file(
                              File(_profileImage!.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.account_circle, size: 120),
                            ),
                    ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('プロフィール写真を選択'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(_isEditing ? '変更を保存' : '作成'), // ボタンのテキストを動的に変更
              ),
            ],
          ),
        ),
        bottomNavigationBar: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdBanner(),
            ButtomButton(),
          ],
        ),
      );
    }
  }
}
