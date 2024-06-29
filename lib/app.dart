import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final TextEditingController _circleNameController = TextEditingController();
  List<String> selectedProfileIds = [];

  void _createCircle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _circleNameController.text.isNotEmpty) {
      final circleRef = await FirebaseFirestore.instance.collection('circles').add({
        'name': _circleNameController.text,
        'createdBy': user.uid,
        'members': [user.uid, ...selectedProfileIds],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final profileDoc = await FirebaseFirestore.instance.collection('profiles').doc(user.uid).get();
      final senderNickName = profileDoc['nickName'];
      final senderImage = profileDoc['profileImage'];

      for (String profileId in selectedProfileIds) {
        await FirebaseFirestore.instance.collection('invitations').add({
          'circleId': circleRef.id,
          'circleName': _circleNameController.text,
          'recipientId': profileId,
          'senderId': user.uid,
          'senderName': senderNickName,
          'senderImage': senderImage,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サークルを作成しました。')),
      );
    } else if (user == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが完了していません。', style: TextStyle(color: Colors.red))),
      );
    } else if (_circleNameController.text.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サークル名を入力してください。', style: TextStyle(color: Colors.red))),
      );
    }
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 50),
                            const Text(
                              'サークル作成',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('サークルを作成して、たくさんの仲間とつながろう！',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        TextField(
                          controller: _circleNameController,
                          decoration: const InputDecoration(
                              labelText: 'サークル名', hintText: 'サークル名を入力してください'),
                        ),
                        const SizedBox(height: 10),
                        const Text('誰を招待しますか？',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('profiles')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text('プロフィールがありません'));
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            final profiles = snapshot.data!.docs
                                .where((doc) => doc.id != user?.uid)
                                .toList();

                            return SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: profiles.length,
                                itemBuilder: (context, index) {
                                  final profile = profiles[index];
                                  final isSelected =
                                      selectedProfileIds.contains(profile.id);
                                  return Card(
                                    color: isSelected
                                        ? const Color.fromARGB(
                                            255, 226, 243, 33)
                                        : Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedProfileIds
                                                .remove(profile.id);
                                          } else {
                                            selectedProfileIds.add(profile.id);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child: Image.network(
                                                profile['profileImage'],
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              profile['nickName'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _createCircle,
                          child: const Text('作成'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
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
            label: '一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'サークル'
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
