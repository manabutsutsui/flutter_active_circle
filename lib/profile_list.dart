import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parts/ad_banner.dart';
import 'parts/app_drawer.dart';

class ProfileList extends StatefulWidget {
  const ProfileList({super.key});

  @override
  State<ProfileList> createState() => ProfileListState();
}

class ProfileListState extends State<ProfileList> {
  Future<List<String>> getBlockedUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }
    final querySnapshot = await FirebaseFirestore.instance
        .collection('blocks')
        .where('blockedBy', isEqualTo: currentUser.uid)
        .get();
    return querySnapshot.docs
        .map((doc) => doc['blockedUser'] as String)
        .toList();
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
      body: FutureBuilder<List<String>>(
        future: getBlockedUsers(),
        builder: (context, blockedSnapshot) {
          if (blockedSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (blockedSnapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }

          final blockedUsers = blockedSnapshot.data ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('profiles').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('プロフィールがありません'));
              }

              final profiles = snapshot.data!.docs
                  .where((doc) => !blockedUsers.contains(doc.id))
                  .toList();

              return Column(
                children: [
                  const AdBanner(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('プロフィール一覧',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2列に設定
                        childAspectRatio: 0.75, // カードの縦横比を調整
                      ),
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        return GestureDetector(
                          onTap: () {
                            if (FirebaseAuth.instance.currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('プロフィールの詳細を確認するには、ログインが必要です。'),
                                ),
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/profile_detail',
                                arguments: profile.id,
                              );
                            }
                          },
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      profile['profileImage'],
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    profile['nickName'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '年齢: ${profile['age']}\n好きなスポーツ: \n${profile['sports']}',
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
