import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parts/app_drawer.dart';
import 'parts/ad_banner.dart';
import 'chat.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final TextEditingController _circleNameController = TextEditingController();
  List<String> selectedProfileIds = [];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      selectedProfileIds = [user.uid];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    void createCircle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _circleNameController.text.isNotEmpty) {
      final circleRef =
          await FirebaseFirestore.instance.collection('circles').add({
        'name': _circleNameController.text,
        'createdBy': user.uid,
        'members': [...selectedProfileIds],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
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
        const SnackBar(
            content:
                Text('ログインが完了していません。', style: TextStyle(color: Colors.red))),
      );
    } else if (_circleNameController.text.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('サークル名を入力してください。', style: TextStyle(color: Colors.red))),
      );
    }
  }


  Widget buildCircleCreationSheet(BuildContext context) {
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: _circleNameController,
                decoration: const InputDecoration(
                    labelText: 'サークル名', hintText: 'サークル名を入力してください'),
              ),
              const SizedBox(height: 10),
              const Text('誰を招待しますか？',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('profiles').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                              ? const Color.fromARGB(255, 226, 243, 33)
                              : Colors.white,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedProfileIds.remove(profile.id);
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
                                    borderRadius: BorderRadius.circular(30),
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
                onPressed: createCircle,
                child: const Text('作成'),
              ),
            ],
          ),
        );
      },
    );
  }

    if (user == null) {
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
        body: const Center(
          child: Text('ログインしてください'),
        ),
      );
    }

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
          const AdBanner(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('invitations')
                  .where('recipientId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('招待がありません'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(data['senderImage']),
                        radius: 32,
                      ),
                      title: Text(
                        data['circleName'] ?? 'No Circle Name',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('作成者: ${data['senderName']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('確認', style: TextStyle(color: Colors.red),),
                                content: const Text('このサークルを削除してもよろしいですか？'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('キャンセル'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('削除'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );

                          if (result == true) {
                            await FirebaseFirestore.instance
                                .collection('invitations')
                                .doc(doc.id)
                                .delete();
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(circleId: data['circleId'], circleName: data['circleName']),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) =>
                buildCircleCreationSheet(context),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}