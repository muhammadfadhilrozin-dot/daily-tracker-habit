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
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT DEFAULT '',
            icon_code INTEGER,
            created_at TEXT NOT NULL,
            target_per_week INTEGER NOT NULL DEFAULT 7,
            reminder_hour INTEGER,
            reminder_minute INTEGER
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
        if (oldVersion < 2)
          await db.execute('ALTER TABLE habits ADD COLUMN icon_code INTEGER');
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE habits ADD COLUMN target_per_week INTEGER NOT NULL DEFAULT 7',
          );
          await db.execute(
            'ALTER TABLE habits ADD COLUMN reminder_hour INTEGER',
          );
          await db.execute(
            'ALTER TABLE habits ADD COLUMN reminder_minute INTEGER',
          );
        }
        if (oldVersion < 4)
          await db.execute(
            "ALTER TABLE habits ADD COLUMN description TEXT DEFAULT ''",
          );
      },
    );
  }

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitLogModel>> getLogsForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((e) => HabitLogModel.fromMap(e)).toList();
  }

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

  Future<int> getStreak(int habitId) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND is_completed = 1',
      whereArgs: [habitId],
    );
    if (result.isEmpty) return 0;
    final completedDates = result
        .map((e) => DateTime.parse(e['date'] as String))
        .toList();
    int streak = 0;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isTodayCompleted = completedDates.any((d) => _isSameDay(d, today));
    var cursor = isTodayCompleted
        ? today
        : today.subtract(const Duration(days: 1));
    while (completedDates.any((d) => _isSameDay(d, cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<Map<String, bool>> getCompletionMapForHabit(int habitId) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    final map = <String, bool>{};
    for (final row in result) {
      map[row['date'] as String] = (row['is_completed'] as int) == 1;
    }
    return map;
  }

  Future<int> getCompletionsThisWeek(int habitId) async {
    final db = await database;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayKey = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(monday.year, monday.month, monday.day));
    final result = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND is_completed = 1 AND date >= ?',
      whereArgs: [habitId, mondayKey],
    );
    return result.length;
  }
}
