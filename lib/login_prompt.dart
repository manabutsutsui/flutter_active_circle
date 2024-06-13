import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'parts/buttom_button.dart';
import 'parts/ad_banner.dart';
// import 'parts/sign_up_with_google.dart';
// import 'parts/sign_up_with_apple.dart';

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
        leading: IconButton(
          onPressed: () {
            context.go('/home');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
                child: Text('あなたのプロフィールを作成してください',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text('プロフィールを作成するには、ログインが必要です。'),
                  // SignUpWithGoogle(),
                  // SignUpWithApple(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdBanner(),
          ButtomButton(),
        ],
      ),
    );
  }
}
