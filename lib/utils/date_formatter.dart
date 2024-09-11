import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  static String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) {
      return '';
    }
    final date = timestamp.toDate();
    final formatter = DateFormat('yyyy/MM/dd HH:mm');
    return formatter.format(date);
  }
}
