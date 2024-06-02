import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'home.dart';
import 'profile.dart';
import 'profile_list.dart';
import 'profile_detail.dart';
import 'message_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Profile(),
        ),
        GoRoute(
          path: '/profile_list',
          builder: (context, state) => const ProfileList(),
        ),
        GoRoute(
          path: '/profile_detail/:profileId',
          builder: (context, state) => ProfileDetail(profileId: state.pathParameters['profileId']!),
        ),
        GoRoute(
          path: '/message_list',
          builder: (context, state) => const MessageList(),
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
        context.go('/home');
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
                    'スポーツ好きと繋がりましょう！',
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
