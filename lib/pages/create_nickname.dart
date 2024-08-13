import 'package:flutter/material.dart';
import '../parts/base.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateNickname extends StatefulWidget {
  const CreateNickname({super.key});

  @override
  State<CreateNickname> createState() => _CreateNicknameState();
}

class _CreateNicknameState extends State<CreateNickname> {
  final TextEditingController _nicknameController = TextEditingController();

  Future<void> _saveNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nicknameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set({
          'nickName': _nicknameController.text,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Base()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ニックネームの保存に失敗しました')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ニックネームを入力してください')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名前(ニックネーム)', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '名前(ニックネーム)を入力してください',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: '名前(ニックネーム)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveNickname,
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }
}