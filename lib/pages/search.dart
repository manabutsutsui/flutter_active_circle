import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  List<Map<String, String>> categories = [
    {'name': '陸上', 'image': 'athletics.jpg'},
    {'name': 'サッカー', 'image': 'soccer.jpg'},
    {'name': 'バスケットボール', 'image': 'basketball.jpg'},
    {'name': '野球', 'image': 'baseball.jpg'},
    {'name': 'テニス', 'image': 'tennis.jpg'},
    {'name': 'バレーボール', 'image': 'volleyball.jpg'},
    {'name': 'ラグビー', 'image': 'rugby.jpg'},
    {'name': 'バドミントン', 'image': 'badminton.jpg'},
    {'name': '体操', 'image': 'gymnastics.jpg'},
    {'name': '柔道', 'image': 'judo.jpg'},
    {'name': '水泳', 'image': 'swimming.jpg'},
    {'name': '卓球', 'image': 'table-tennis.jpg'},
  ];

  Widget buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchDetailScreen(category: categories[index]['name']!),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage('assets/images/${categories[index]['image']}'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: Text(
                  categories[index]['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('searchableFields', arrayContains: _searchQuery.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('検索結果がありません'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];
            final data = post.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(data['userImageUrl'] ?? ''),
              ),
              title: Text('タイトル: ${data['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text('ニックネーム: ${data['userName'] ?? ''} スポーツ: ${data['sportTag'] ?? ''}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchDetailScreen(category: data['sportTag']),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'ニックネーム、タイトル、スポーツなど',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
      body: _searchQuery.isEmpty ? buildCategoryGrid() : buildSearchResults(),
    );
  }
}