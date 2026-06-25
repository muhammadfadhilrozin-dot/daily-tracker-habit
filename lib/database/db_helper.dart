import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'habit_tracker.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon_code INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE habit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
            UNIQUE (habit_id, date)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrasi dari versi 1 (belum ada kolom icon_code) ke versi 2
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE habits ADD COLUMN icon_code INTEGER');
        }
      },
    );
  }

  /// Tanggal hari ini dalam format yyyy-MM-dd, dipakai sebagai key tracking harian
  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ---------- HABITS ----------
  Future<int> insertHabit(HabitModel habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<HabitModel>> getHabits() async {
    final db = await database;
    final result = await db.query('habits', orderBy: 'id DESC');
    return result.map((e) => HabitModel.fromMap(e)).toList();
  }

  Future<int> updateHabit(HabitModel habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    // Hapus juga semua riwayat penyelesaian habit ini
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- HABIT LOGS (Tracking Aktivitas) ----------

  /// Ambil semua log untuk tanggal tertentu (dipakai dashboard & list hari ini)
  Future<List<HabitLogModel>> getLogsForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((e) => HabitLogModel.fromMap(e)).toList();
  }

  /// Tandai habit sebagai selesai / belum selesai pada tanggal tertentu
  Future<void> toggleHabitCompletion(
    int habitId,
    String date,
    bool isCompleted,
  ) async {
    final db = await database;
    final existing = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );

    if (existing.isEmpty) {
      await db.insert('habit_logs', {
        'habit_id': habitId,
        'date': date,
        'is_completed': isCompleted ? 1 : 0,
      });
    } else {
      await db.update(
        'habit_logs',
        {'is_completed': isCompleted ? 1 : 0},
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, date],
      );
    }
  }

  /// Riwayat penyelesaian satu habit (untuk fitur riwayat / statistik lanjutan)
  Future<List<HabitLogModel>> getHistoryForHabit(int habitId) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return result.map((e) => HabitLogModel.fromMap(e)).toList();
  }
}
