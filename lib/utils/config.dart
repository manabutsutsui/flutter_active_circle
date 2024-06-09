import 'dart:convert';
import 'package:flutter/services.dart';

class Config {
  static Map<String, dynamic>? _config;

  static Future<void> loadConfig() async {
    final configString = await rootBundle.loadString('assets/config/config.json');
    _config = jsonDecode(configString);
  }

  static String get googleCloudApiKey {
    if (_config == null) {
      throw Exception('Config not loaded');
    }
    return _config!['googleCloudApiKey'];
  }
}
