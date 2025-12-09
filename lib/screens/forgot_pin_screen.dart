// lib/forgot_pin_screen.dart
import 'package:flutter/material.dart';
import '../utils/security_helper.dart';
import 'pin_entry_screen.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _answerController = TextEditingController();
  String? securityQuestion;
  bool loading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityQuestion() async {
    final question = await SecurityHelper.getSecurityQuestion();
    if (question == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pertanyaan keamanan belum diatur')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() {
      securityQuestion = question;
      loading = false;
    });
  }

  Future<void> _verifyAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      setState(() {
        hasError = true;
        errorMessage = 'Jawaban tidak boleh kosong';
      });
      return;
    }

    final isValid = await SecurityHelper.verifySecurityAnswer(
      _answerController.text,
    );

    if (isValid) {
      if (mounted) {
        // Navigate to create new PIN
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const PinEntryScreen(isSetup: true, title: 'Buat PIN Baru'),
          ),
        );
        if (result == true && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      setState(() {
        hasError = true;
        errorMessage = 'Jawaban salah!';
        _answerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa PIN')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jawab pertanyaan keamanan untuk mereset PIN:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    securityQuestion ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      labelText: 'Jawaban',
                      border: const OutlineInputBorder(),
                      errorText: hasError ? errorMessage : null,
                    ),
                    onChanged: (_) {
                      if (hasError) {
                        setState(() {
                          hasError = false;
                        });
                      }
                    },
                    onSubmitted: (_) => _verifyAnswer(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyAnswer,
                      child: const Text('Verifikasi'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
