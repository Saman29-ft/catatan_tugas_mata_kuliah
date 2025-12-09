import 'package:flutter/material.dart';
import '../services/deepseek_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatScreen extends StatefulWidget {
  final String? initialPrompt;
  final String? context;
  
  const ChatScreen({super.key, this.initialPrompt, this.context});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DeepSeekService _chatService = DeepSeekService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
      _checkInternet();
    // Test koneksi saat init
    _testApiConnection();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _sendMessage(widget.initialPrompt!);
    }
  }
  
  Future<void> _checkInternet() async {
    final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
      setState(() {
      _error = 'Tidak ada koneksi internet';
      });
    }
  }

  Future<void> _testApiConnection() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await _chatService.testConnection();
      if (!isConnected) {
        setState(() {
          _error = 'API Connection Test Failed\nPastikan:\n1. API Key valid\n2. Koneksi internet aktif\n3. API Key memiliki quota';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
      _error = null;
    });
    
    _controller.clear();
    
    try {
      final response = await _chatService.getAIResponse(
        text,
        context: widget.context,
      );
      
      setState(() {
        _messages.add({'text': response, 'isUser': false});
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _messages.add({
          'text': '**Error:** $e\n\nSilakan:\n1. Periksa API Key di deepseek_service.dart\n2. Cek koneksi internet\n3. Pastikan API Key masih aktif',
          'isUser': false,
        });
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek AI Assistant'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_error != null)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_error!),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange[50],
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          _buildInputField(),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message['isUser'] as bool)
            const Spacer(),
          CircleAvatar(
            backgroundColor: message['isUser'] as bool
                ? Colors.deepPurple
                : Colors.green,
            child: Icon(
              message['isUser'] as bool ? Icons.person : Icons.auto_awesome,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message['isUser'] as bool
                    ? Colors.deepPurple[50]
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: message['isUser'] as bool
                      ? Colors.deepPurple[100]!
                      : Colors.green[100]!,
                ),
              ),
              child: Text(
                message['text'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: message['text'].toString().contains('x')
                      ? Colors.red[700]
                      : Colors.black87,
                ),
              ),
            ),
          ),
          if (!(message['isUser'] as bool))
            const Spacer(),
        ],
      ),
    );
  }
  
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Tanyakan tentang tugas kuliah Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: _sendMessage,
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}