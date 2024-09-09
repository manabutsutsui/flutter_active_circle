import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'utils/config.dart';
import 'parts/base.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/login.dart';
import 'pages/create_nickname.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Config.loadConfig();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ActiveCircle',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
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
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward().then((_) {
      Timer(const Duration(seconds: 2), () {
        _checkAuthAndNavigate();
      });
    });
  }

  Future<void> _handleIncomingLinks() async {
    if (await FirebaseAuth.instance.isSignInWithEmailLink(Uri.base.toString())) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userCredential = await FirebaseAuth.instance.signInWithEmailLink(
          email: prefs.getString('emailForSignIn') ?? '',
          emailLink: Uri.base.toString(),
        );

        if (userCredential.user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CreateNickname()),
          );
        }
      } catch (e) {
        print('Error signing in with email link: $e');
      }
    }
  }

  void _checkAuthAndNavigate() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Base()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
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
              child: Text(
                'ActiveCircle',
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontFamily: 'Pacifico',
                ),
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