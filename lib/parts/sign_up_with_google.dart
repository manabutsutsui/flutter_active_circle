import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../app.dart';

class SignUpWithGoogle extends StatefulWidget {
  const SignUpWithGoogle({super.key});

  @override
  SignUpWithGoogleState createState() => SignUpWithGoogleState();
}

class SignUpWithGoogleState extends State<SignUpWithGoogle> {
  @override
  Widget build(BuildContext context) {
    return SignInButton(
      Buttons.googleDark,
      text: "Googleでアカウント作成",
      onPressed: () async {
        try {
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final AuthCredential credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            await FirebaseAuth.instance.signInWithCredential(credential);
            // 登録成功後の処理
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Googleアカウントでログインが完了しました。')),
              );
            }
            if (!mounted) return; // mountedチェックを追加
            // 'プロフィール'に遷移
            Navigator.of(context).pushReplacementNamed('/profile');
            // 'プロフィール'画面に遷移した後、_selectedIndexを更新
            final myStatefulWidgetState = context.findAncestorStateOfType<MyStatefulWidgetState>();
            myStatefulWidgetState?.navigateToPage(3); // 'プロフィール'のインデックスを設定
          }
        } catch (e) {
          print(e);
        }
      },
    );
  }
}
