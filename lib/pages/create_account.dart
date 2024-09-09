import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_nickname.dart';
import '../parts/sign_up_with_google.dart';
import '../parts/sign_up_with_apple.dart';
import '../parts/base.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  CreateAccountState createState() => CreateAccountState();
}

class CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'パスワードが一致しません。';
        });
        return;
      }
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateNickname()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'アカウント作成に失敗しました。';
        });
      }
    }
  }

  Future<void> _onSignInComplete(BuildContext context, String userId) async {
    DocumentSnapshot userProfile = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(userId)
        .get();

    if (userProfile.exists) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Base()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CreateNickname()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント作成', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'パスワードを入力してください';
                  }
                  return null;
                },
                keyboardType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'パスワード（確認）',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'パスワードを再入力してください';
                  }
                  if (value != _passwordController.text) {
                    return 'パスワードが一致しません';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('アカウント作成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 64),
              const Text('または', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              Center(
                child: SignUpWithGoogle(
                  onSignInComplete: _onSignInComplete,
                  buttonText: 'Googleでサインアップ',
                ),
              ),
              Center(
                child: SignUpWithApple(
                  onSignInComplete: _onSignInComplete,
                  buttonText: 'Appleでサインアップ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}