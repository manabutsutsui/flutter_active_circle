import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'home.dart';
import 'profile_list.dart';
import 'message_list.dart';
import 'profile.dart';
import 'profile_detail.dart';


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
    MessageList(),
    Profile(),
    ProfileDetail(profileId: ''),
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
              if (settings.name == '/profile_detail') {
                final profileId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => ProfileDetail(profileId: profileId),
                );
              }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'リスト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'メッセージ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}


