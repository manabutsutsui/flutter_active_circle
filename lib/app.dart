import 'package:flutter/material.dart';
import 'home.dart';
import 'profile_list.dart';
import 'message_list.dart';
import 'profile.dart';
import 'circle.dart';

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({
    super.key,
  });

  @override
  State<MyStatefulWidget> createState() => MyStatefulWidgetState();
}

class MyStatefulWidgetState extends State<MyStatefulWidget> {
  late int _selectedIndex;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  static const _screens = [
    HomeScreen(),
    ProfileList(),
    CircleScreen(),
    MessageList(),
    Profile(),
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
              if (settings.name == '/profile') {
                return MaterialPageRoute(
                  builder: (context) => const Profile(),
                );
              }
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '一覧'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'サークル'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'メッセージ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

