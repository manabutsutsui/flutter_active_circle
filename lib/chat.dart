import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String circleId;
  final String circleName;

  const ChatScreen(
      {required this.circleId, required this.circleName, super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  late User? user;
  late Future<DocumentSnapshot> profileDoc;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    profileDoc =
        FirebaseFirestore.instance.collection('profiles').doc(user?.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.circleName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        body: const Center(
          child: Text('ログインしてください'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.circleName,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              _showCircleMembers(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('circles')
                  .doc(widget.circleId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('メッセージがありません'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(data['senderId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const CircleAvatar(
                              child: Icon(Icons.person),
                            );
                          }
                          final profileData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final profileImage =
                              profileData?['profileImage'] as String?;
                          return profileImage != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(profileImage),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.person),
                                );
                        },
                      ),
                      title: Text(
                        data['message'],
                      ),
                      subtitle: Text(
                        data['senderName'] +
                            ' ' +
                            DateFormat('MM月dd日HH:mm').format(
                                (data['timestamp'] as Timestamp).toDate()),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final message = _messageController.text;
                    if (message.isNotEmpty) {
                      final profileData =
                          (await profileDoc).data() as Map<String, dynamic>?;
                      final String senderName =
                          profileData?['nickName'] as String? ?? 'Unknown';
                      await FirebaseFirestore.instance
                          .collection('circles')
                          .doc(widget.circleId)
                          .collection('messages')
                          .add({
                        'senderId': user.uid,
                        'senderName': senderName,
                        'message': message,
                        'timestamp': Timestamp.now(),
                      });
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCircleMembers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('circles')
              .doc(widget.circleId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('エラーが発生しました'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('サークルが見つかりません'));
            }

            final circleData = snapshot.data!.data() as Map<String, dynamic>;
            final members = circleData['members'] as List<dynamic>? ?? [];

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 50),
                      const Text('サークルメンバー', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final memberId = members[index];
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('profiles')
                              .doc(memberId)
                              .get(),
                          builder: (context, profileSnapshot) {
                            if (profileSnapshot.connectionState == ConnectionState.waiting) {
                              return const ListTile(title: Text('読み込み中...'));
                            }
                            
                            if (profileSnapshot.hasError || !profileSnapshot.hasData) {
                              return const ListTile(title: Text('ユーザー情報を取得できません'));
                            }
                            
                            final profileData = profileSnapshot.data!.data() as Map<String, dynamic>?;
                            final nickName = profileData?['nickName'] as String? ?? '名前';
                            final profileImage = profileData?['profileImage'] as String?;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                                child: profileImage == null ? const Icon(Icons.person) : null,
                              ),
                              title: Text(nickName),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: ElevatedButton(
                      onPressed: () {
                        _showInviteDialog(context);
                      },
                      child: const Text('サークルに招待'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context) {
    List<String> selectedProfileIds = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('サークルに招待'),
              content: SizedBox(
                width: double.maxFinite,
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('profiles').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('招待可能なユーザーがいません'));
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('circles')
                          .doc(widget.circleId)
                          .get(),
                      builder: (context, circleSnapshot) {
                        if (circleSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!circleSnapshot.hasData || !circleSnapshot.data!.exists) {
                          return const Center(child: Text('サークル情報を取得できません'));
                        }

                        final circleData = circleSnapshot.data!.data() as Map<String, dynamic>;
                        final currentMembers = (circleData['members'] as List<dynamic>?)?.cast<String>() ?? [];

                        final profiles = snapshot.data!.docs
                            .where((doc) => !currentMembers.contains(doc.id))
                            .toList();

                        return ListView.builder(
                          itemCount: profiles.length,
                          itemBuilder: (context, index) {
                            final profile = profiles[index];
                            final isSelected = selectedProfileIds.contains(profile.id);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(profile['profileImage']),
                              ),
                              title: Text(profile['nickName']),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedProfileIds.add(profile.id);
                                    } else {
                                      selectedProfileIds.remove(profile.id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('招待する'),
                  onPressed: () {
                    _inviteMembers(selectedProfileIds);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _inviteMembers(List<String> selectedProfileIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final circleDoc = await FirebaseFirestore.instance
        .collection('circles')
        .doc(widget.circleId)
        .get();
    final circleData = circleDoc.data() as Map<String, dynamic>;
    final creatorId = circleData['createdBy'] as String;

    final creatorProfileDoc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(creatorId)
        .get();
    final creatorNickName = creatorProfileDoc['nickName'];
    final creatorImage = creatorProfileDoc['profileImage'];

    // Firestoreのバッチ処理を作成
    final batch = FirebaseFirestore.instance.batch();

    for (String profileId in selectedProfileIds) {
      // 招待を追加
      final invitationRef = FirebaseFirestore.instance.collection('invitations').doc();
      batch.set(invitationRef, {
        'circleId': widget.circleId,
        'circleName': widget.circleName,
        'recipientId': profileId,
        'senderId': creatorId,
        'senderName': creatorNickName,
        'senderImage': creatorImage,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // circleのmembersフィールドを更新
      final circleRef = FirebaseFirestore.instance.collection('circles').doc(widget.circleId);
      batch.update(circleRef, {
        'members': FieldValue.arrayUnion([profileId])
      });
    }

    // バッチ処理を実行
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待メールを送信しました。')),
      );
    }
  }
}