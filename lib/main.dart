import 'package:flutter/material.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/assignment.dart';
import 'utils/database_helper.dart';
import 'utils/security_helper.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  // await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Tugas Kuliah + AI Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF2196F3),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================================
// APP INITIALIZER (PIN CHECKER)
// ============================================================================
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isChecking = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final pinEnabled = await SecurityHelper.isPinEnabled();

    if (!pinEnabled) {
      setState(() {
        _isVerified = true;
        _isChecking = false;
      });
      return;
    }

    setState(() => _isChecking = false);

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) _showPinScreen();
  }

  Future<void> _showPinScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PinEntryScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() => _isVerified = true);
    } else {
      _showPinScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Memuat aplikasi...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isVerified) return const HomePage();

    return const Scaffold(
      body: Center(
        child: Text('Memverifikasi...'),
      ),
    );
  }
}

// ============================================================================
// HOME PAGE
// ============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Assignment> items = [];
  List<String> courses = ['All'];
  String selectedCourse = 'All';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    courses = await DatabaseHelper.instance.getCourses();
    items = await DatabaseHelper.instance.getAssignments(
      course: selectedCourse == 'All' ? null : selectedCourse,
    );

    if (mounted) setState(() => loading = false);
  }

  Future<void> _toggleDone(Assignment a) async {
    a.isDone = !a.isDone;
    await DatabaseHelper.instance.updateAssignment(a);
    if (mounted) await _load();
  }

  Future<void> _delete(Assignment a) async {
    if (a.id != null) await DatabaseHelper.instance.deleteAssignment(a.id!);
    if (mounted) await _load();
  }

  void _openAddEdit([Assignment? a]) async {
    final changed = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditPage(item: a)),
    );
    if (changed == true && mounted) await _load();
  }

  void _openCourses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoursesPage(
          onSelect: (c) {
            selectedCourse = c;
            _load();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: AssignmentSearchDelegate(currentCourse: selectedCourse),
    ).then((_) {
      if (mounted) _load();
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _openChatWithContext(Assignment assignment) {
    final contextMessage = """
Saya sedang mengerjakan tugas kuliah dengan detail berikut:
- Judul: ${assignment.title}
- Mata Kuliah: ${assignment.course}
- Deskripsi: ${assignment.description ?? "Tidak ada deskripsi"}
- Deadline: ${assignment.dueDate}
- Status: ${assignment.isDone ? "Selesai" : "Belum selesai"}

Bantu saya dengan: ide pengembangan, outline lengkap, referensi akademis, atau bantu selesaikan tugas ini.
""";

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialPrompt: contextMessage),
      ),
    );
  }

  void _showDeleteDialog(Assignment a) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Yakin ingin menghapus "${a.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _delete(a);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = items.where((a) => !a.isDone).length;
    final doneCount = items.where((a) => a.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Catatan Tugas Kuliah'),
        actions: [
          IconButton(
            onPressed: _openChat,
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            tooltip: 'AI Assistant',
          ),
          IconButton(
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Cari Tugas',
          ),
          IconButton(
            onPressed: _openCourses,
            icon: const Icon(Icons.book),
            tooltip: 'Mata Kuliah',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x1A1976D2),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Stats Card
                    if (items.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(158, 158, 158, 0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Belum Selesai',
                              pendingCount.toString(),
                              Colors.orange,
                              Icons.pending_actions,
                            ),
                            _buildStatCard(
                              'Selesai',
                              doneCount.toString(),
                              Colors.green,
                              Icons.check_circle,
                            ),
                            _buildStatCard(
                              'Total',
                              items.length.toString(),
                              Colors.blue,
                              Icons.assignment,
                            ),
                          ],
                        ),
                      ),

                    // Course Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 8),
                          const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: selectedCourse,
                              isExpanded: true,
                              underline: Container(),
                              icon: const Icon(Icons.arrow_drop_down),
                              items: courses
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  selectedCourse = v;
                                  _load();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Assignment List
                    Expanded(
                      child: items.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, idx) {
                                final a = items[idx];
                                final due = DateTime.tryParse(a.dueDate);
                                final now = DateTime.now();
                                final isOverdue = due != null &&
                                    due.isBefore(now) &&
                                    !a.isDone;
                                final daysLeft = due?.difference(now).inDays;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Card(
                                    color: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: () => _openAddEdit(a),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Status Icon
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: a.isDone
                                                    ? Colors.green.shade50
                                                    : isOverdue
                                                        ? Colors.red.shade50
                                                        : Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                a.isDone
                                                    ? Icons.check_circle
                                                    : isOverdue
                                                        ? Icons.warning
                                                        : Icons.assignment,
                                                color: a.isDone
                                                    ? Colors.green.shade700
                                                    : isOverdue
                                                        ? Colors.red.shade700
                                                        : Colors.blue.shade700,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Assignment Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: a.isDone
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                      color: a.isDone
                                                          ? Colors.grey
                                                          : isOverdue
                                                              ? Colors.red
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),

                                                  // Course
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.school,
                                                        size: 14,
                                                        color:
                                                            Colors.grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        a.course,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),

                                                  // Due Date with Warning
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 14,
                                                        color: isOverdue
                                                            ? Colors.red
                                                            : Colors
                                                                .grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        due != null
                                                            ? '${due.day}/${due.month}/${due.year}'
                                                            : a.dueDate,
                                                        style: TextStyle(
                                                          color: isOverdue
                                                              ? Colors.red
                                                              : Colors
                                                                  .grey.shade600,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              isOverdue
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                        ),
                                                      ),
                                                      if (daysLeft != null &&
                                                          !a.isDone)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8),
                                                          child: Text(
                                                            isOverdue
                                                                ? 'Terlambat ${-daysLeft} hari'
                                                                : '$daysLeft hari lagi',
                                                            style: TextStyle(
                                                              color: isOverdue
                                                                  ? Colors.red
                                                                  : daysLeft <= 3
                                                                      ? Colors
                                                                          .orange
                                                                      : Colors
                                                                          .green,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Actions
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    a.isDone
                                                        ? Icons.check_circle
                                                        : Icons
                                                            .radio_button_unchecked,
                                                    color: a.isDone
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                  onPressed: () =>
                                                      _toggleDone(a),
                                                  tooltip: a.isDone
                                                      ? 'Tandai belum selesai'
                                                      : 'Tandai selesai',
                                                ),
                                                const SizedBox(height: 8),
                                                PopupMenuButton(
                                                  icon: const Icon(
                                                      Icons.more_vert),
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.edit,
                                                              color:
                                                                  Colors.blue),
                                                          SizedBox(width: 8),
                                                          Text('Edit'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'ai',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.smart_toy,
                                                              color:
                                                                  Colors.purple),
                                                          SizedBox(width: 8),
                                                          Text('AI Assistant'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete,
                                                              color:
                                                                  Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Hapus'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onSelected: (v) {
                                                    if (v == 'edit') {
                                                      _openAddEdit(a);
                                                    } else if (v == 'ai') {
                                                      _openChatWithContext(a);
                                                    } else if (v == 'delete') {
                                                      _showDeleteDialog(a);
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
        // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          ),       
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada tugas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Mulai dengan menambahkan tugas kuliah Anda. Tekan tombol + di bawah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openAddEdit(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tugas Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.smart_toy),
              label: const Text('Tanya AI Assistant'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ADD / EDIT PAGE
// ============================================================================
class AddEditPage extends StatefulWidget {
  final Assignment? item;
  const AddEditPage({super.key, this.item});

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleC;
  late TextEditingController _descC;
  late TextEditingController _courseC;
  DateTime? _dueDate;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    final a = widget.item;
    _titleC = TextEditingController(text: a?.title ?? '');
    _descC = TextEditingController(text: a?.description ?? '');
    _courseC = TextEditingController(text: a?.course ?? '');
    _isDone = a?.isDone ?? false;
    _dueDate = DateTime.tryParse(a?.dueDate ?? '') ??
        DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _courseC.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1976D2),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _getAIHelp() {
    final contextMessage = """
Bantu saya membuat/mengembangkan tugas dengan detail berikut:
- Judul: ${_titleC.text}
- Deskripsi: ${_descC.text}
- Mata Kuliah: ${_courseC.text}
- Deadline: ${_dueDate?.toIso8601String() ?? 'Belum ditentukan'}

Berikan saya: ide, outline lengkap, struktur penulisan, referensi akademis, atau contoh untuk tugas ini.
""";

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialPrompt: contextMessage),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final a = Assignment(
      id: widget.item?.id,
      title: _titleC.text.trim(),
      description: _descC.text.trim().isEmpty ? null : _descC.text.trim(),
      course: _courseC.text.trim().isEmpty ? 'Umum' : _courseC.text.trim(),
      dueDate: (_dueDate ?? DateTime.now()).toIso8601String(),
      isDone: _isDone,
      createdAt: widget.item?.createdAt,
    );

    if (widget.item == null) {
      await DatabaseHelper.instance.insertAssignment(a);
    } else {
      await DatabaseHelper.instance.updateAssignment(a);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dueText = _dueDate != null
        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
        : 'Pilih tanggal';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Tambah Tugas' : 'Edit Tugas'),
        actions: [
          IconButton(
            onPressed: _getAIHelp,
            icon: const Icon(Icons.smart_toy),
            tooltip: 'Minta Bantuan AI',
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Judul
                TextFormField(
                  controller: _titleC,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas *',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Deskripsi
                TextFormField(
                  controller: _descC,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Mata Kuliah
                TextFormField(
                  controller: _courseC,
                  decoration: const InputDecoration(
                    labelText: 'Mata Kuliah / Kategori',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: Algoritma, Basis Data, Matematika',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Deadline
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deadline',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              dueText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickDueDate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                        ),
                        child: const Text('Pilih'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Status Tugas',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _isDone,
                        onChanged: (v) => setState(() => _isDone = v),
                        activeThumbColor: Colors.green,
                      ),
                      Text(
                        _isDone ? 'Selesai' : 'Belum',
                        style: TextStyle(
                          color: _isDone ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Assistant Button
                ElevatedButton.icon(
                  onPressed: _getAIHelp,
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Minta Bantuan AI Assistant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Save Button
                ElevatedButton(
                  onPressed: _save,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Simpan Tugas',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batalkan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COURSES PAGE
// ============================================================================
class CoursesPage extends StatefulWidget {
  final void Function(String) onSelect;
  const CoursesPage({super.key, required this.onSelect});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  Map<String, int> counts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => loading = true);

    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
      'SELECT course, COUNT(*) as cnt FROM ${DatabaseHelper.assignmentTable} GROUP BY course',
    );

    counts = {
      for (var r in res) (r['course'] as String? ?? 'Umum'): (r['cnt'] as int),
    };

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final keys = counts.keys.toList()..sort();
    final total = counts.values.fold<int>(0, (p, c) => p + c);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        actions: [
          IconButton(
            onPressed: _loadCounts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            keys.length.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'Mata Kuliah',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            total.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Total Tugas',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.all_inclusive, color: Colors.blue),
                        ),
                        title: const Text('Semua Tugas'),
                        subtitle: Text('Total: $total tugas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onSelect('All'),
                      ),
                      const Divider(),
                      ...keys.map(
                        (k) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.book, color: Colors.green),
                          ),
                          title: Text(k),
                          subtitle: Text('${counts[k]} tugas'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onSelect(k),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// SEARCH DELEGATE
// ============================================================================
class AssignmentSearchDelegate extends SearchDelegate<Assignment?> {
  final String currentCourse;
  AssignmentSearchDelegate({this.currentCourse = 'All'});

  @override
  String get searchFieldLabel => 'Cari tugas, mata kuliah, atau deskripsi...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Assignment>>(
      future: DatabaseHelper.instance.searchAssignments(
        query,
        course: currentCourse == 'All' ? null : currentCourse,
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tidak ada hasil ditemukan',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = data[i];
            final due = DateTime.tryParse(a.dueDate);
            final dueText = due != null
                ? '${due.day}/${due.month}/${due.year}'
                : a.dueDate;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: a.isDone ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(
                  a.isDone ? Icons.check : Icons.assignment,
                  color: a.isDone ? Colors.green : Colors.blue,
                ),
              ),
              title: Text(
                a.title,
                style: TextStyle(
                  decoration: a.isDone ? TextDecoration.lineThrough : null,
                  color: a.isDone ? Colors.grey : null,
                ),
              ),
              subtitle: Text('${a.course} • Deadline: $dueText'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditPage(item: a),
                  ),
                );

                if (context.mounted) close(context, null);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ketik untuk mencari tugas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Assignment>>(
      future: DatabaseHelper.instance.searchAssignments(
        query,
        course: currentCourse == 'All' ? null : currentCourse,
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text('Tidak ada hasil ditemukan.'),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final a = items[idx];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: a.isDone ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(
                  a.isDone ? Icons.check : Icons.assignment,
                  color: a.isDone ? Colors.green : Colors.blue,
                ),
              ),
              title: Text(a.title),
              subtitle: Text(a.course),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditPage(item: a),
                  ),
                );

                if (context.mounted) close(context, null);
              },
            );
          },
        );
      },
    );
  }
}