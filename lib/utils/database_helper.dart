// lib/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/assignment.dart';

class DatabaseHelper {
  static const _dbName = 'assignments_db.db';
  static const _dbVersion = 2;
  static const assignmentTable = 'assignments';
  static const securityTable = 'security';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $assignmentTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        course TEXT,
        dueDate TEXT,
        isDone INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $securityTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $securityTable(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  Future<int> insertAssignment(Assignment a) async {
    final db = await database;
    return await db.insert(assignmentTable, a.toMap());
  }

  Future<List<Assignment>> getAssignments({String? course}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (course == null || course == 'All') {
      maps = await db.query(assignmentTable, orderBy: 'dueDate ASC');
    } else {
      maps = await db.query(
        assignmentTable,
        where: 'course = ?',
        whereArgs: [course],
        orderBy: 'dueDate ASC',
      );
    }
    return maps.map((m) => Assignment.fromMap(m)).toList();
  }

  Future<List<Assignment>> searchAssignments(String q, {String? course}) async {
    final db = await database;
    final pattern = '%${q.trim()}%';
    if (course == null || course == 'All') {
      final maps = await db.query(
        assignmentTable,
        where: 'title LIKE ? OR description LIKE ? OR course LIKE ?',
        whereArgs: [pattern, pattern, pattern],
        orderBy: 'dueDate ASC',
      );
      return maps.map((m) => Assignment.fromMap(m)).toList();
    } else {
      final maps = await db.query(
        assignmentTable,
        where: '(title LIKE ? OR description LIKE ?) AND course = ?',
        whereArgs: [pattern, pattern, course],
        orderBy: 'dueDate ASC',
      );
      return maps.map((m) => Assignment.fromMap(m)).toList();
    }
  }

  Future<int> updateAssignment(Assignment a) async {
    final db = await database;
    return await db.update(
      assignmentTable,
      a.toMap(),
      where: 'id = ?',
      whereArgs: [a.id],
    );
  }

  Future<int> deleteAssignment(int id) async {
    final db = await database;
    return await db.delete(assignmentTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getCourses() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT DISTINCT course FROM $assignmentTable',
    );
    List<String> courses = res
        .map((r) => r['course'] as String? ?? 'Umum')
        .toList();
    courses.removeWhere((c) => c.trim().isEmpty);
    courses.sort();
    return ['All', ...courses];
  }
}
