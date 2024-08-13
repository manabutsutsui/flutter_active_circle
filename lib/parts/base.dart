import 'package:flutter/material.dart';
import '../pages/home.dart';
import '../pages/search.dart';
import '../pages/notification.dart';
import '../pages/profile.dart';
import '../pages/post.dart';

class Base extends StatefulWidget {
  const Base({
    super.key,
  });

  @override
  State<Base> createState() => BaseState();
}

class BaseState extends State<Base> {
  late int _selectedIndex;
  final PageController _pageController = PageController();
  bool _showBottomNavigationBar = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  static final _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const PostPage(),
    const NotificationScreen(),
    const Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _screens.map((screen) {
          return Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => screen,
                settings: settings,
              );
            },
          );
        }).toList(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: _showBottomNavigationBar
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: '探す'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle, color: Colors.red),
                  label: '投稿',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '通知'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
              ],
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue,
            )
          : null,
    );
  }

  void setShowBottomNavigationBar(bool show) {
    setState(() {
      _showBottomNavigationBar = show;
    });
  }
}