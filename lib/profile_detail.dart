import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'parts/buttom_button.dart';
import 'parts/ad_banner.dart';
import 'message.dart';

class ProfileDetail extends StatelessWidget {
  final String profileId;

  const ProfileDetail({super.key, required this.profileId});

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
        leading: IconButton(
          onPressed: () {
            context.go('/profile_list');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('profiles')
            .doc(profileId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('プロフィールが見つかりません'));
          }

          final profile = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      profile['profileImage'],
                      fit: BoxFit.cover,
                      width: 300,
                      height: 300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      SizedBox(
                        width: 300,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(
                                text: '名前: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 24),
                              ),
                              TextSpan(
                                text: profile['nickName'],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 300,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(
                                text: '年齢: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: profile['age'].toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 300,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(
                                text: '好きなスポーツ: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: profile['sports'],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 300,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(
                                text: '実績・経験: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: profile['experience'],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      profileId == FirebaseAuth.instance.currentUser!.uid
                          ? const SizedBox()
                          : Column(
                              children: [
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MessageScreen(
                                            recipientId: profileId,
                                            recipientName: profile['nickName'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text('${profile['nickName']}さんにメッセージを送信'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final TextEditingController reportController = TextEditingController();
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('報告内容を記入'),
                                            content: TextField(
                                              controller: reportController,
                                              maxLines: 5,
                                              decoration: const InputDecoration(
                                                hintText: '報告内容を記入してください',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('キャンセル'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore.instance.collection('reports').add({
                                                    'profileId': profileId,
                                                    'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                                                    'reportContent': reportController.text,
                                                    'timestamp': FieldValue.serverTimestamp(),
                                                  });
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('プロフィールを報告しました')),
                                                  );
                                                },
                                                child: const Text('送信'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('このプロフィールを報告'),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdBanner(),
          ButtomButton(),
        ],
      ),
    );
  }
}
