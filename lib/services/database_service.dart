import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_record.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'snapcal.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE food_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          meal_type TEXT NOT NULL,
          food_name TEXT NOT NULL,
          calories INTEGER NOT NULL,
          carbs INTEGER NOT NULL,
          protein INTEGER NOT NULL,
          fat INTEGER NOT NULL,
          image_path TEXT,
          description TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    });
  }

  static Future<int> insert(FoodRecord record) async {
    final db = await database;
    return db.insert('food_records', record.toMap()..remove('id'));
  }

  static Future<List<FoodRecord>> getByDate(String date) async {
    final db = await database;
    final maps = await db.query('food_records', where: 'date = ?', whereArgs: [date], orderBy: 'created_at');
    return maps.map(FoodRecord.fromMap).toList();
  }

  static Future<Map<String, int>> getCaloriesByDateRange(String from, String to) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT date, SUM(calories) as total FROM food_records WHERE date >= ? AND date <= ? GROUP BY date',
      [from, to],
    );
    return {for (var m in maps) m['date'] as String: (m['total'] as num).toInt()};
  }

  static Future<List<FoodRecord>> getByDateRange(String from, String to) async {
    final db = await database;
    final maps = await db.query('food_records', where: 'date >= ? AND date <= ?', whereArgs: [from, to], orderBy: 'date, created_at');
    return maps.map(FoodRecord.fromMap).toList();
  }

  static Future<int> delete(int id) async {
    final db = await database;
    return db.delete('food_records', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> topFoods(int limit) async {
    final db = await database;
    return db.rawQuery(
      'SELECT food_name, COUNT(*) as count, AVG(calories) as avg_cal FROM food_records GROUP BY food_name ORDER BY count DESC LIMIT ?',
      [limit],
    );
  }
}
