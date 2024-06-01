import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authenticationをインポート

class AppDrawer extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuthのインスタンスを取得

  AppDrawer({super.key}); // 'key'をsuperパラメータに変換

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut(); // ログアウト処理
    if (context.mounted) {
      Navigator.of(context).pop(); // メニューバーを閉じる
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            title: const Text('ホーム'),
            leading: const Icon(Icons.home),
            onTap: () {
              context.go('/home');
            },
          ),
          ListTile(
            title: const Text('プロフィール'),
            leading: const Icon(Icons.person),
            onTap: () {
              context.go('/profile');
            },
          ),
          ListTile(
            title: const Text('一覧'),
            leading: const Icon(Icons.list),
            onTap: () {
              context.go('/profile_list');
            },
          ),
          if (_auth.currentUser != null) // ログインしている場合のみ表示
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
