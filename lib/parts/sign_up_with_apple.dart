import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../pages/create_nickname.dart';

class SignUpWithApple extends StatefulWidget {
  const SignUpWithApple({super.key});

  @override
  SignUpWithAppleState createState() => SignUpWithAppleState();
}

class SignUpWithAppleState extends State<SignUpWithApple> {
  @override
  Widget build(BuildContext context) {
    return SignInButton(
      Buttons.appleDark,
      text: "Appleでアカウント作成",
      onPressed: () async {
        try {
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

          final oauthCredential = OAuthProvider("apple.com").credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
          );

          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CreateNickname()),
            );
          }
        } catch (e) {
          if (e is SignInWithAppleAuthorizationException) {
            switch (e.code) {
              case AuthorizationErrorCode.canceled:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appleアカウントでログインがキャンセルされました。')),
                );
                break;
              case AuthorizationErrorCode.failed:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('サインインに失敗しました。')),
                );
                break;
              case AuthorizationErrorCode.invalidResponse:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('無効なレスポンスが返されました。')),
                );
                break;
              case AuthorizationErrorCode.notHandled:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('サインインが処理されませんでした。')),
                );
                break;
              case AuthorizationErrorCode.unknown:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('不明なエラーが発生しました。')),
                );
                break;
              case AuthorizationErrorCode.notInteractive:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('インタラクティブではありません。')),
                );
                break;
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('未処理のエラーが発生しました。')),
                );
                break;
            }
          }
        }
      },
    );
  }
}