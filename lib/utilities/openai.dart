import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../openai_configuration.dart';

Future<String?> requestOpenAiResponse(
  List<Map<String, String>> messages, {
  String model = 'gpt-4o-mini', // Updated to a more efficient/modern model
  double temperature = 0.7,
}) async {
  final apiKey = openAiApiKeyDev;
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  final body = jsonEncode({
    'model': model,
    'messages': messages,
    'temperature': temperature,
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decodedBody);
    //final data = jsonDecode(response.body);
    print(data['choices'][0]['message']['content']);
    return data['choices'][0]['message']['content'];
  } else {
    print('Error: ${response.statusCode}');
    print(response.body);
    return null;
  }
}
