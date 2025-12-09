import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  final String _apiKey;
  
  DeepSeekService() : _apiKey = 'sk-c279b9f2446044a4bd97f6cb385fe3e6'; // ← PASTIKAN INI KEY ASLI
  
  Future<String> getAIResponse(String prompt, {String? context}) async {
    if (!_isValidApiKey(_apiKey)) {
      throw Exception('Invalid API Key. Please check your DeepSeek API key.');
    }
    
    return await _callDeepSeekAPI(prompt, context);
  }
  
  bool _isValidApiKey(String key) {
    return key.startsWith('sk-') && key.length > 30;
  }
  
  Future<String> _callDeepSeekAPI(String prompt, String? context) async {
    final fullPrompt = context != null 
        ? '''
Konteks Tugas: $context

Pertanyaan: $prompt

Tolong berikan bantuan yang spesifik, praktis, dan terstruktur untuk menyelesaikan tugas ini.
'''
        : prompt;
    // ignore: avoid_print
    print('Calling DeepSeek API...');
    
    try {
      // Buat request tanpa timeout exception khusus
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'Anda adalah asisten AI khusus untuk membantu mahasiswa menyelesaikan tugas kuliah. Berikan respons yang terstruktur dan praktis.'
            },
            {
              'role': 'user',
              'content': fullPrompt
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
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
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        throw Exception('Request timeout. Coba lagi dengan koneksi yang lebih stabil.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('Network is unreachable')) {
        throw Exception('Connection error. Periksa koneksi internet Anda.');
      } else {
        throw Exception('Error: $e');
      }
    }
  }
  
  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [{'role': 'user', 'content': 'Hello'}],
          'max_tokens': 5,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}