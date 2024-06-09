import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart'; // Configユーティリティをインポート

const String apiUrl = 'https://language.googleapis.com/v1/documents:analyzeSentiment?key=';

Future<bool> containsProhibitedContent(String text) async {
  final response = await http.post(
    Uri.parse('$apiUrl${Config.googleCloudApiKey}'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'document': {
        'type': 'PLAIN_TEXT',
        'content': text,
      },
      'encodingType': 'UTF8',
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final sentiment = data['documentSentiment']['score'];
    // ここでは、ネガティブなスコアが一定以下の場合を不適切と判断
    return sentiment < -0.5;
  } else {
    throw Exception('Failed to analyze text');
  }
}
