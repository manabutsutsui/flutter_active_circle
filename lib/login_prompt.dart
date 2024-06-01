import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'parts/app_drawer.dart';
import 'parts/buttom_button.dart';
import 'parts/sign_up_with_google.dart';
import 'parts/sign_up_with_apple.dart';

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key});

  @override
  Widget build(BuildContext context) {
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
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('プロフィールを作成するには、アカウントの作成が必要です。'),
          SizedBox(height: 10),
          SignUpWithGoogle(),
          SignUpWithApple(),
        ],
      ),
    ),
    bottomNavigationBar: const ButtomButton(),
    );
  }
}
  
