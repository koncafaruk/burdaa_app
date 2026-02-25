import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('burdaa_vibe.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onConfigure: _onConfigure,
      onCreate: createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future createDB(Database db, int version) async {
    // 1. courses
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        location TEXT,
        dayOfWeek INTEGER NOT NULL, -- 1-7
        startTime TEXT NOT NULL, -- HH:mm
        endTime TEXT NOT NULL, -- HH:mm
        startDate TEXT NOT NULL, -- ISO8601
        endDate TEXT NOT NULL, -- ISO8601
        frequency INTEGER NOT NULL DEFAULT 31, -- Keeping structure but unused for MVP logic if not needed
        interval INTEGER NOT NULL DEFAULT 1,
        
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // 2. attendance
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId TEXT NOT NULL,
        date TEXT NOT NULL, -- YYYY-MM-DD
        status INTEGER NOT NULL, -- 1=present, 2=absent, 0=none
        notes TEXT,
        recordedAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Simple destructive migration for MVP
    await db.execute('DROP TABLE IF EXISTS attendance');
    await db.execute('DROP TABLE IF EXISTS courses');

    // Drop old tables too in case they exist from previous install
    await db.execute('DROP TABLE IF EXISTS sessionAnnotations');
    await db.execute('DROP TABLE IF EXISTS sessionAttendanceRecords');
    await db.execute('DROP TABLE IF EXISTS sessions');
    await db.execute('DROP TABLE IF EXISTS sessionTemplates');
    await db.execute('DROP TABLE IF EXISTS onceSeriesDetails');
    await db.execute('DROP TABLE IF EXISTS monthlyByDaySeriesDetails');
    await db.execute('DROP TABLE IF EXISTS monthlyByWeekdaySeriesDetails');
    await db.execute('DROP TABLE IF EXISTS weeklySeriesDetails');
    await db.execute('DROP TABLE IF EXISTS sessionSeries');
    await db.execute('DROP TABLE IF EXISTS metadata');

    await createDB(db, newVersion);
  }

  Future<List<int>> getDatabaseBytes() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'burdaa_vibe.db');
      final sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        return await sourceFile.readAsBytes();
      } else {
        throw Exception('Veritabanı dosyası bulunamadı.');
      }
    } catch (e) {
      throw Exception('Veritabanı okuma hatası: $e');
    }
  }

  static Future<void> markAttendance(String courseId, int status) async {
    final db = await instance.database;
    final now = DateTime.now();
    final dateString =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final existingRecords = await db.query(
      'attendance',
      where: 'courseId = ? AND date = ?',
      whereArgs: [courseId, dateString],
    );

    final map = {
      'courseId': courseId,
      'date': dateString,
      'status': status,
      'recordedAt': now.toIso8601String(),
    };

    if (existingRecords.isNotEmpty) {
      await db.update(
        'attendance',
        map,
        where: 'id = ?',
        whereArgs: [existingRecords.first['id']],
      );
    } else {
      await db.insert('attendance', map);
    }
  }

  Future<void> backupDatabase(String targetPath) async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'burdaa_vibe.db');
      final sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
      } else {
        throw Exception('Veritabanı dosyası bulunamadı.');
      }
    } catch (e) {
      throw Exception('Yedekleme hatası: $e');
    }
  }

  Future<void> restoreDatabase(String sourcePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final targetPath = join(dbPath, 'burdaa_vibe.db');
      final sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        if (_database != null) {
          await _database!.close();
          _database = null;
        }
        await sourceFile.copy(targetPath);
      } else {
        throw Exception('Yedek dosyası bulunamadı.');
      }
    } catch (e) {
      throw Exception('Geri yükleme hatası: $e');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
