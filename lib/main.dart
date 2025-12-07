// lib/main.dart
import 'package:flutter/material.dart';
import 'assignment.dart';
import 'database_helper.dart';
import 'security_helper.dart';
import 'pin_entry_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Tugas Kuliah',
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
      ),
      home: const AppInitializer(),
    );
  }
}

// App Initializer (PIN checker)
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isVerified) return const HomePage();

    return const Scaffold(body: Center(child: Text('Memverifikasi...')));
  }
}

// Home Page -------------------------------------------------------------------------------------
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Catatan Tugas Kuliah'),
        actions: [
          IconButton(onPressed: _openSearch, icon: const Icon(Icons.search)),
          IconButton(onPressed: _openCourses, icon: const Icon(Icons.book)),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x1A1976D2), Colors.white],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Text('Mata Kuliah:'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: selectedCourse,
                              isExpanded: true,
                              items: courses
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
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
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada tugas. Tekan + untuk menambah.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, idx) {
                                final a = items[idx];
                                final due = DateTime.tryParse(a.dueDate);
                                final dueText = due != null
                                    ? '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}'
                                    : a.dueDate;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () => _openAddEdit(a),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: a.isDone
                                                  ? Colors.green.shade100
                                                  : Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              a.isDone
                                                  ? Icons.check_circle
                                                  : Icons.assignment,
                                              color: a.isDone
                                                  ? Colors.green.shade700
                                                  : Colors.blue.shade700,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  a.title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: a.isDone
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
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
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      dueText,
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
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
                                            onPressed: () => _toggleDone(a),
                                          ),
                                          PopupMenuButton(
                                            icon: const Icon(Icons.more_vert),
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit,
                                                        color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete,
                                                        color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (v) {
                                              if (v == 'edit') {
                                                _openAddEdit(a);
                                              } else if (v == 'delete') {
                                                _delete(a);
                                              }
                                            },
                                          ),
                                        ],
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
}

// Add / Edit Page -------------------------------------------------------------------------------
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
    _courseC = TextEditingController(text: a?.course ?? 'Umum');
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
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
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
        ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
        : 'Pilih tanggal';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Tambah Tugas' : 'Edit Tugas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(labelText: 'Judul Tugas'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Judul wajib' : null,
              ),
              TextFormField(
                controller: _descC,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                ),
              ),
              TextFormField(
                controller: _courseC,
                decoration: const InputDecoration(
                  labelText: 'Mata Kuliah / Kategori',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Deadline: $dueText')),
                  TextButton(
                    onPressed: _pickDueDate,
                    child: const Text('Pilih Tanggal'),
                  ),
                ],
              ),
              SwitchListTile(
                value: _isDone,
                onChanged: (v) => setState(() => _isDone = v),
                title: const Text('Selesai'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Courses Page -----------------------------------------------------------------------------------
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

    return Scaffold(
      appBar: AppBar(title: const Text('Mata Kuliah')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('Semua'),
                  subtitle: Text(
                    'Total: ${counts.values.fold<int>(0, (p, c) => p + c)}',
                  ),
                  onTap: () => widget.onSelect('All'),
                ),
                ...keys.map(
                  (k) => ListTile(
                    title: Text(k),
                    trailing: Text('${counts[k]}'),
                    onTap: () => widget.onSelect(k),
                  ),
                ),
              ],
            ),
    );
  }
}

// Search Delegate (PERBAIKAN COMPLETE) -----------------------------------------------------------
class AssignmentSearchDelegate extends SearchDelegate<Assignment?> {
  final String currentCourse;
  AssignmentSearchDelegate({this.currentCourse = 'All'});

  @override
  String get searchFieldLabel => 'Cari tugas atau mata kuliah...';

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
        if (data.isEmpty) return const Center(child: Text('Tidak ada hasil.'));

        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = data[i];
            final due = DateTime.tryParse(a.dueDate);
            final dueText = due != null
                ? '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}'
                : a.dueDate;

            return ListTile(
              leading: Icon(
                a.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
              title: Text(
                a.title,
                style: TextStyle(
                  decoration: a.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('${a.course} • Deadline: $dueText'),
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
      return const Center(child: Text('Ketik untuk mencari...'));
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
          return const Center(child: Text('Tidak ada saran.'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final a = items[idx];
            return ListTile(
              title: Text(a.title),
              subtitle: Text(a.course),
              leading: Icon(
                a.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
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
