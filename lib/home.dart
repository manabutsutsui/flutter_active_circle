import 'package:flutter/material.dart';
import 'parts/ad_banner.dart';
import 'parts/sign_up_with_google.dart';
import 'parts/sign_up_with_apple.dart';
import 'parts/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
  with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget buildFadeTransition() {
    return FadeTransition(
      opacity: _animation,
      child: const Column(
        children: [
          Text(
            'Welcome to Active Circle!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pacifico',
            ),
          ),
          SizedBox(height: 20),
          Text(
            'ActiveCircle(アクティブサークル)は、\nスポーツが好きな人が集まるプラットフォームです。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'あなたと同じスポーツが好きな人を探して、\n仲間を見つけましょう!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButtons(BuildContext context) {
    return const Column(
      children: [
        SignUpWithGoogle(),
        SignUpWithApple(),
      ],
    );
  }

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AdBanner(),
            const SizedBox(height: 20),
            buildFadeTransition(),
            const SizedBox(height: 20),
            buildButtons(context),
          ],
        ),
      ),
    );
  }
}
