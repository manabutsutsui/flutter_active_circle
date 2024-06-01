import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sign_in_button/sign_in_button.dart';

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
          // 登録成功後の処理
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appleアカウントでログインが完了しました。')),
            );
            context.go('/profile');
          }
        } catch (e) {
          if (e is SignInWithAppleAuthorizationException) {
            switch (e.code) {
              case AuthorizationErrorCode.canceled:
                print('ユーザーがサインインをキャンセルしました。');
                break;
              case AuthorizationErrorCode.failed:
                print('サインインに失敗しました。');
                break;
              case AuthorizationErrorCode.invalidResponse:
                print('無効なレスポンスが返されました。');
                break;
              case AuthorizationErrorCode.notHandled:
                print('サインインが処理されませんでした。');
                break;
              case AuthorizationErrorCode.unknown:
                print('不明なエラーが発生しました。');
                break;
              case AuthorizationErrorCode.notInteractive:
                print('インタラクティブではありません。');
                break;
              default:
                print('未処理のエラーが発生しました。');
                break;
            }
          } else {
            print('エラーが発生しました: $e');
          }
        }
      },
    );
  }
}

