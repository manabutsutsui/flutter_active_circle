import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  ProfileEditState createState() => ProfileEditState();
}

class ProfileEditState extends State<ProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  String _gender = '未選択';
  DateTime? _birthDate;
  String? _profileImageUrl;

  final List<String> _genderOptions = ['未選択', '男性', '女性', 'その他'];
  int _selectedGenderIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _nicknameController.text = doc.data()?['nickName'] ?? '';
          _bioController.text = doc.data()?['bio'] ?? '';
          _gender = doc.data()?['gender'] ?? '未選択';
          _selectedGenderIndex = _genderOptions.indexOf(_gender);
          _birthDate = doc.data()?['birthDate']?.toDate();
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 画像を圧縮
          final bytes = await pickedFile.readAsBytes();
          final compressedImage = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 500,
            minHeight: 500,
            quality: 85,
            format: CompressFormat.jpeg,
          );

          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');
          
          await ref.putData(compressedImage, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();
          
          setState(() {
            _profileImageUrl = url;
          });
        }
      }
    } catch (e) {
      print('画像のアップロードに失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像のアップロードに失敗しました。')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updatedData = {
          'nickName': _nicknameController.text,
          'bio': _bioController.text,
          'gender': _gender,
          'birthDate': _birthDate,
          'profileImageUrl': _profileImageUrl,
        };

        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .update(updatedData);

        await _updateUserPosts(user.uid, updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('プロフィールを更新しました')),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }

  Future<void> _updateUserPosts(String userId, Map<String, dynamic> updatedData) async {
    final postsQuery = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId);

    final querySnapshot = await postsQuery.get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {
        'userName': updatedData['nickName'],
        'userImageUrl': updatedData['profileImageUrl'],
      });
    }

    await batch.commit();
  }

  void _showGenderPicker() {
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
                          _gender = _genderOptions[_selectedGenderIndex];
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
                    _selectedGenderIndex = index;
                  },
                  children: _genderOptions.map((String gender) {
                    return Center(child: Text(gender));
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
          title: const Text('プロフィール編集',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          backgroundColor: Colors.blue,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _uploadProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '名前（ニックネーム）',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '名前を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '自己紹介',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showGenderPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '性別',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_gender),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('生年月日'),
                subtitle: Text(_birthDate == null
                    ? '未設定'
                    : '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _birthDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}