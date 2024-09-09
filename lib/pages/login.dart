import 'package:flutter/material.dart';
import '../parts/sign_up_with_google.dart';
import '../parts/sign_up_with_apple.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../parts/base.dart';
import 'create_nickname.dart';
import '../parts/term_of_service.dart';
import '../parts/privacy_policy.dart';
import 'create_account.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatelessWidget {
  const Login({super.key});

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
      appBar: AppBar(
        title: const Text('ログイン', style: TextStyle(fontWeight: FontWeight.bold),),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              EmailPasswordLogin(onSignInComplete: _onSignInComplete),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  children: [
                    const TextSpan(text: ''),
                    TextSpan(
                      text: '利用規約',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => showTermsOfService(context),
                    ),
                    const TextSpan(text: '及び'),
                    TextSpan(
                      text: 'プライバシーポリシー',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => showPrivacyPolicy(context),
                    ),
                    const TextSpan(text: 'に同意の上、\nアカウントを作成して下さい。'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('または', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              SignUpWithGoogle(
                onSignInComplete: _onSignInComplete,
                buttonText: 'Googleでサインイン',
              ),
              SignUpWithApple(
                onSignInComplete: _onSignInComplete,
                buttonText: 'Appleでサインイン',
              ),
              const SizedBox(height: 64),
              const Text('まだ、アカウントをお持ちでない方は', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateAccount()),
                  );
                },
                child: const Text(
                  'こちら',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmailPasswordLogin extends StatefulWidget {
  final Function(BuildContext, String) onSignInComplete;

  const EmailPasswordLogin({Key? key, required this.onSignInComplete}) : super(key: key);

  @override
  _EmailPasswordLoginState createState() => _EmailPasswordLoginState();
}

class _EmailPasswordLoginState extends State<EmailPasswordLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (userCredential.user != null) {
        widget.onSignInComplete(context, userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'このメールアドレスのユーザーが見つかりません。';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'パスワードが間違っています。';
      } else {
        errorMessage = 'ログインに失敗しました。もう一度お試しください。';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインに失敗しました。もう一度お試しください。', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'パスワード',
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
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('ログイン', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}