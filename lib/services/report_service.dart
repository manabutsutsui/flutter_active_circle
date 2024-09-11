import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  static Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String reportedUserId,
    required String reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'postId': postId,
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error reporting post: $e');
      throw Exception('投稿の報告に失敗しました');
    }
  }

  static void showReportDialog(BuildContext context, Function(String) onReport) {
    String reportReason = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('投稿を報告'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('報告理由を記入してください：'),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                onChanged: (value) {
                  reportReason = value;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '報告理由を入力',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reportReason.isNotEmpty) {
                  onReport(reportReason);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('報告する'),
            ),
          ],
        );
      },
    );
  }
}
