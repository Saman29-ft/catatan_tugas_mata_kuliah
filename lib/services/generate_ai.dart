import 'dart:convert';
import 'package:http/http.dart' as http;

class GenerateAI {
  final String _apiKey;

  GenerateAI()
    : _apiKey = 'hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; // HuggingFace API Key

  Future<String> getAIResponse(String prompt, {String? context}) async {
    if (!_isValidApiKey(_apiKey)) {
      throw Exception(
        'Invalid API Key. Please check your HuggingFace API key.',
      );
    }

    return await _callHuggingFaceAPI(prompt, context);
  }

  bool _isValidApiKey(String key) {
    return key.startsWith('hf_') && key.length > 30;
  }

  Future<String> _callHuggingFaceAPI(String prompt, String? context) async {
    final fullPrompt = context != null
        ? '''
Konteks Tugas: $context

Pertanyaan: $prompt

Tolong berikan bantuan yang spesifik, praktis, dan terstruktur untuk menyelesaikan tugas ini.
'''
        : prompt;
    // ignore: avoid_print
    print('Calling HuggingFace API...');

    try {
      // Request ke HuggingFace API
      final response = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b:fastest',
          'temperature': 0,
          'top_p': 1,
          'frequency_penalty': 0,
          'presence_penalty': 0,
          'stop': [' END'],
          'messages': [
            {'role': 'user', 'content': fullPrompt},
          ],
        }),
      );
      // ignore: avoid_print
      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception('API Key tidak valid. Status: 401 Unauthorized');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Tunggu beberapa saat.');
      } else {
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      // Tangkap semua error termasuk timeout (tanpa spesifik)
      if (e.toString().contains('timeout') ||
          e.toString().contains('timed out')) {
        throw Exception(
          'Request timeout. Coba lagi dengan koneksi yang lebih stabil.',
        );
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Connection error. Periksa koneksi internet Anda.');
      } else {
        throw Exception('Error: $e');
      }
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b:fastest',
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'temperature': 0,
          'top_p': 1,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
