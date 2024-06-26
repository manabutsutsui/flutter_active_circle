import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';

class AppDrawer extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppDrawer({super.key});

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _reAuthenticate(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      final providerId = user.providerData[0].providerId;

      if (providerId == 'password') {
        final email = user.email;
        if (email != null) {
          final passwordController = TextEditingController();
          final result = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('再認証が必要です'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('パスワードを入力してください: $email'),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'パスワード'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final credential = EmailAuthProvider.credential(
                          email: email,
                          password: passwordController.text,
                        );
                        await user.reauthenticateWithCredential(credential);
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('再認証に失敗しました。')),
                        );
                        Navigator.of(context).pop(false);
                      }
                    },
                    child: const Text('再認証'),
                  ),
                ],
              );
            },
          );
          return result ?? false;
        }
      } else if (providerId == 'google.com') {
        try {
          final googleUser = await GoogleSignIn().signIn();
          if (googleUser == null) {
            return false;
          }
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
          return true;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('再認証に失敗しました。')),
          );
          return false;
        }
      } else if (providerId == 'apple.com') {
        try {
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
          );
          await user.reauthenticateWithCredential(oauthCredential);
          return true;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('再認証に失敗しました。')),
          );
          return false;
        }
      }
    }
    return false;
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .delete();
      await user.delete();
      if (context.mounted) {
        Navigator.of(context).pop(); // メニューバーを閉じる
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アカウントが削除されました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const Center(
            child: Text(
              'ActiveCircle',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontFamily: 'Pacifico'),
            ),
          ),
          ListTile(
            title: const Text('ホーム'),
            leading: const Icon(Icons.home),
            onTap: () {
              Navigator.pop(context);
              final state =
                  context.findAncestorStateOfType<MyStatefulWidgetState>();
              state?.navigateToPage(0);
            },
          ),
          ListTile(
            title: const Text('一覧'),
            leading: const Icon(Icons.list),
            onTap: () {
              Navigator.pop(context);
              final state =
                  context.findAncestorStateOfType<MyStatefulWidgetState>();
              state?.navigateToPage(1);
            },
          ),
          ListTile(
            title: const Text('メッセージ'),
            leading: const Icon(Icons.message),
            onTap: () {
              Navigator.pop(context);
              final state =
                  context.findAncestorStateOfType<MyStatefulWidgetState>();
              state?.navigateToPage(2);
            },
          ),
          ListTile(
            title: const Text('プロフィール'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.pop(context);
              final state =
                  context.findAncestorStateOfType<MyStatefulWidgetState>();
              state?.navigateToPage(3);
            },
          ),
          if (_auth.currentUser != null)
            ListTile(
              title: const Text('ブロックリスト'),
              leading: const Icon(Icons.block),
              onTap: () {
                context.go('/block_list');
              },
            ),
          if (_auth.currentUser != null)
            ListTile(
              title: const Text(
                'ログアウト',
                style: TextStyle(color: Colors.red),
              ),
              leading: const Icon(
                Icons.exit_to_app,
                color: Colors.red,
              ),
              onTap: () async {
                bool? confirmLogout = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('確認'),
                      content: const Text(
                        '本当にログアウトしますか？',
                        style: TextStyle(color: Colors.red),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('キャンセル'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: const Text('ログアウト'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );

                if (confirmLogout == true) {
                  if (context.mounted) {
                    await _signOut(context); // ログアウト処理を呼び出す
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ログアウトが完了しました。')),
                      );
                      final state =
                          context.findAncestorStateOfType<MyStatefulWidgetState>();
                      state?.navigateToPage(0);
                    }
                  }
                }
              },
            ),
          if (_auth.currentUser != null) // ログインしている場合のみ表示
            ListTile(
              title: const Text(
                'アカウント削除',
                style: TextStyle(color: Colors.red),
              ),
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onTap: () async {
                bool? confirmDelete = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('確認'),
                      content: const Text(
                        '本当にアカウントを削除しますか？',
                        style: TextStyle(color: Colors.red),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('キャンセル'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: const Text('削除'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  if (context.mounted) {
                    bool reAuthenticated =
                        await _reAuthenticate(context); // 再認証を行う
                    if (context.mounted && reAuthenticated) {
                      await _deleteAccount(context); // アカウント削除処理を呼び出す
                    }
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
