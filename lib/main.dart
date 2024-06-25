import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'terms_of_service.dart';
import 'utils/config.dart'; // Configユーティリティをインポート
import 'block_list.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Config.loadConfig(); // Configを読み込む
  final prefs = await SharedPreferences.getInstance();
  final acceptedTerms = prefs.getBool('acceptedTerms') ?? false;
  runApp(MyApp(acceptedTerms: acceptedTerms));
}

class MyApp extends StatelessWidget {
  final bool acceptedTerms;

  const MyApp({super.key, required this.acceptedTerms});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => acceptedTerms ? const SplashScreen() : const TermsOfServiceScreen(),
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) => const MyStatefulWidget(),
        ),
        GoRoute(
          path: '/block_list',
          builder: (context, state) => const BlockList(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'ActiveCircle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
  with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward().then((_) {
      Timer(const Duration(seconds: 2), () {
        context.go('/app');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _opacity,
        child: const Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'ActiveCircle',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: 'Pacifico',
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'スポーツ好きな人と繋がりましょう！',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}