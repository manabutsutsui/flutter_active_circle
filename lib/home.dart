import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_drawer.dart';
import 'buttom_button.dart';
import 'sign_up_with_google.dart';
import 'sign_up_with_apple.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _images = [
    'assets/soccer.jpg',
    'assets/basketball.jpg',
    'assets/tennis.jpg',
    'assets/volleyball.jpg',
  ];

  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _startSlideshow();
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

  void _startSlideshow() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        int nextIndex = _currentIndex + 1;
        if (nextIndex >= _images.length) {
          _pageController.jumpToPage(0);
          nextIndex = 0;
        } else {
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        setState(() {
          _currentIndex = nextIndex;
        });
        _startSlideshow();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget buildPageView() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Image.asset(
            _images[index],
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget buildFadeTransition() {
    return FadeTransition(
      opacity: _animation,
      child: const Column(
        children: [
          Text(
            'Welcome to Active Circle!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pacifico',
            ),
          ),
          SizedBox(height: 20),
          Text(
            'ActiveCircle(アクティブサークル)は、\nスポーツが好きな人が集まるプラットフォームです。',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'あなたと同じスポーツが好きな人を探して、\n仲間を見つけましょう!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SignUpWithGoogle(),
        const SignUpWithApple(),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            context.go('/profile_list');
          },
          child: const Text('後で'),
        ),
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
      body: Column(
        children: [
          buildPageView(),
          const SizedBox(height: 40),
          buildFadeTransition(),
          const SizedBox(height: 40),
          buildButtons(),
        ],
      ),
      bottomNavigationBar: const ButtomButton(),
    );
  }
}
