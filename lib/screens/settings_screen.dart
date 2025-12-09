// lib/settings_screen.dart
import 'package:flutter/material.dart';
import '../utils/security_helper.dart';
import 'pin_entry_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pinEnabled = false;
  bool pinSet = false;
  bool securityQuestionSet = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => loading = true);
    pinEnabled = await SecurityHelper.isPinEnabled();
    pinSet = await SecurityHelper.isPinSet();
    securityQuestionSet = await SecurityHelper.isSecurityQuestionSet();
    setState(() => loading = false);
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Enable PIN - check if PIN is set, if not, create one
      if (!pinSet) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PinEntryScreen(isSetup: true),
          ),
        );
        if (result == true) {
          await _loadSettings();
        }
      } else {
        await SecurityHelper.enablePin();
        await _loadSettings();
      }
    } else {
      // Disable PIN - verify first
      if (pinSet) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const PinEntryScreen(title: 'Verifikasi untuk Menonaktifkan'),
          ),
        );
        if (result == true) {
          await SecurityHelper.disablePin();
          await _loadSettings();
        }
      }
    }
  }

  Future<void> _changePin() async {
    // Verify current PIN first
    final verified = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PinEntryScreen(title: 'Verifikasi PIN Lama'),
      ),
    );

    if (verified == true && mounted) {
      // Create new PIN
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const PinEntryScreen(isSetup: true, title: 'Buat PIN Baru'),
        ),
      );
      if (result == true && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN berhasil diubah')));
        await _loadSettings();
      }
    }
  }

  Future<void> _resetPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus PIN? Anda perlu mengatur ulang PIN dan pertanyaan keamanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecurityHelper.deletePin();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN telah dihapus')));
      }
    }
  }

  Future<void> _setupSecurityQuestion() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const SecurityQuestionDialog(),
    );

    if (result != null) {
      await SecurityHelper.saveSecurityQA(
        result['question']!,
        result['answer']!,
      );
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pertanyaan keamanan disimpan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Keamanan')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Keamanan PIN'),
                  subtitle: Text(
                    pinEnabled
                        ? 'PIN aktif - Aplikasi terlindungi'
                        : 'PIN nonaktif',
                  ),
                  value: pinEnabled,
                  onChanged: _togglePin,
                ),
                const Divider(),
                if (pinSet) ...[
                  ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('Ubah PIN'),
                    subtitle: const Text('Ganti PIN keamanan Anda'),
                    onTap: _changePin,
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: Text(
                      securityQuestionSet
                          ? 'Ubah Pertanyaan Keamanan'
                          : 'Atur Pertanyaan Keamanan',
                    ),
                    subtitle: Text(
                      securityQuestionSet
                          ? 'Untuk pemulihan PIN yang lupa'
                          : 'Diperlukan untuk reset PIN',
                    ),
                    onTap: _setupSecurityQuestion,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Reset PIN',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Hapus PIN dan pengaturan keamanan'),
                    onTap: _resetPin,
                  ),
                ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Catatan: PIN 6 angka diperlukan untuk membuka aplikasi. Pastikan Anda mengatur pertanyaan keamanan untuk pemulihan jika lupa PIN.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
    );
  }
}

class SecurityQuestionDialog extends StatefulWidget {
  const SecurityQuestionDialog({super.key});

  @override
  State<SecurityQuestionDialog> createState() => _SecurityQuestionDialogState();
}

class _SecurityQuestionDialogState extends State<SecurityQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  String? selectedQuestion;
  final _customQuestionController = TextEditingController();
  final _answerController = TextEditingController();
  bool useCustomQuestion = false;

  final List<String> predefinedQuestions = [
    'Siapa nama ibu kandung Anda?',
    'Apa nama hewan peliharaan pertama Anda?',
    'Di kota mana Anda dilahirkan?',
    'Apa nama sekolah dasar Anda?',
    'Siapa nama sahabat masa kecil Anda?',
    'Apa makanan favorit Anda?',
  ];

  @override
  void dispose() {
    _customQuestionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final question = useCustomQuestion
          ? _customQuestionController.text.trim()
          : selectedQuestion!;
      final answer = _answerController.text.trim();
      Navigator.pop(context, {'question': question, 'answer': answer});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pertanyaan Keamanan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih atau buat pertanyaan keamanan:'),
              const SizedBox(height: 16),
              if (!useCustomQuestion) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedQuestion,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: predefinedQuestions
                      .map(
                        (q) => DropdownMenuItem(
                          value: q,
                          child: Text(q, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedQuestion = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih pertanyaan';
                    }
                    return null;
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      useCustomQuestion = true;
                      selectedQuestion = null;
                    });
                  },
                  child: const Text('Buat pertanyaan sendiri'),
                ),
              ] else ...[
                TextFormField(
                  controller: _customQuestionController,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan Anda',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Pertanyaan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      useCustomQuestion = false;
                      _customQuestionController.clear();
                    });
                  },
                  child: const Text('Pilih dari daftar'),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Jawaban',
                  border: OutlineInputBorder(),
                  helperText: 'Jawaban tidak case sensitive',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jawaban tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
