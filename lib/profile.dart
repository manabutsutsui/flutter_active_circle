import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'parts/ad_banner.dart';
import 'utils/filters.dart'; // フィルタリングのユーティリティをインポート
import 'package:permission_handler/permission_handler.dart';
import 'parts/app_drawer.dart';
import 'parts/sign_up_with_google.dart';
import 'parts/sign_up_with_apple.dart';
import 'app.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  final TextEditingController _nickNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  XFile? _profileImage;
  String? _imageUrl;
  bool _isEditing = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null && mounted) {
          setState(() {
            _profileImage = image;
            _imageUrl = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像の読み込みに失敗しました')),
          );
        }
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
    if (_nickNameController.text.isEmpty ||
        _sportsController.text.isEmpty ||
        _experienceController.text.isEmpty ||
        _bioController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'すべての必須フィールドを入力してください',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        );
      }
      return;
    }

    // フィルタリングを追加
    final nickName = _nickNameController.text;
    final sports = _sportsController.text;
    final experience = _experienceController.text;
    final bio = _bioController.text;

    if (await containsProhibitedContent(nickName) ||
        await containsProhibitedContent(sports) ||
        await containsProhibitedContent(experience) ||
        await containsProhibitedContent(bio)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
            '不適切な内容が含まれています。',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          )),
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
      'nickName': _nickNameController.text,
      'age': _ageController.text,
      'sports': _sportsController.text,
      'experience': _experienceController.text,
      'bio': _bioController.text,
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
      final state = context.findAncestorStateOfType<MyStatefulWidgetState>();
      state?.navigateToPage(1);
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
          _isEditing = true;
        });
        final data = doc.data();
        _nickNameController.text = data?['nickName'] ?? '';
        _ageController.text = data?['age'] ?? '';
        _sportsController.text = data?['sports'] ?? '';
        _experienceController.text = data?['experience'] ?? '';
        _bioController.text = data?['bio'] ?? '';
        _imageUrl = data?['profileImage'] ?? '';
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

  void _showAgePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _ageController.text = index == 0 ? '非公開' : '$index歳';
                    });
                  },
                  children: List<Widget>.generate(101, (int index) {
                    return Center(
                      child: Text(index == 0 ? '非公開' : '$index歳'),
                    );
                  }),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('選択'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
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
        body: const Column(
          children: [
            AdBanner(),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text('あなたのプロフィールを作成してください',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('プロフィールを作成するには、ログインが必要です。'),
                    SignUpWithGoogle(),
                    SignUpWithApple(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const AdBanner(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('プロフィールを設定してください',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              _profileImage == null
                  ? const Icon(Icons.account_circle, size: 150)
                  : ClipOval(
                      child: _imageUrl != null && _imageUrl!.isNotEmpty
                          ? Image.network(
                              _imageUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.account_circle, size: 150),
                            )
                          : Image.file(
                              File(_profileImage!.path),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.account_circle, size: 150),
                            ),
                    ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('プロフィール写真を選択'),
              ),
              TextField(
                controller: _nickNameController,
                decoration: const InputDecoration(labelText: 'ニックネーム'),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: '年齢 (オプション)'),
                readOnly: true,
                onTap: _showAgePicker,
              ),
              TextField(
                controller: _sportsController,
                decoration: const InputDecoration(labelText: '好きなスポーツ'),
              ),
              TextField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: '実績・経験'),
                maxLines: null,
              ),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: '自己紹介'),
                maxLines: null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(_isEditing ? '変更を保存' : '作成'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
