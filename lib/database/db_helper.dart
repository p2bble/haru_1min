import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/supplement.dart';
import '../models/water_log.dart';
import '../services/image_store.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'haru1min.db'),
      version: 1,
      // sqflite는 FK가 기본 OFF — 켜야 supplement_logs CASCADE가 동작한다
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE supplements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            imagePath TEXT,
            mealTime TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE supplement_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplementId INTEGER NOT NULL,
            takenAt TEXT NOT NULL,
            FOREIGN KEY (supplementId) REFERENCES supplements(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE water_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount INTEGER NOT NULL,
            loggedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // --- Supplement ---

  Future<int> insertSupplement(Supplement s) async {
    final database = await db;
    return database.insert('supplements', s.toMap());
  }

  Future<List<Supplement>> getActiveSupplements() async {
    final database = await db;
    final rows = await database.query(
      'supplements',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'mealTime, createdAt',
    );
    return rows.map(Supplement.fromMap).toList();
  }

  Future<void> updateSupplement(Supplement s) async {
    final database = await db;
    await database.update(
      'supplements',
      s.toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<void> deleteSupplement(int id) async {
    final database = await db;
    final rows = await database.query('supplements',
        columns: ['imagePath'], where: 'id = ?', whereArgs: [id]);
    // FK ON 상태이므로 supplement_logs는 CASCADE로 함께 삭제됨
    await database.delete('supplements', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      await ImageStore.deleteIfExists(rows.first['imagePath'] as String?);
    }
  }

  // --- Supplement Log ---

  Future<void> logSupplement(int supplementId) async {
    final database = await db;
    await database.insert('supplement_logs', {
      'supplementId': supplementId,
      'takenAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeSupplementLog(int supplementId, String dateKey) async {
    final database = await db;
    await database.delete(
      'supplement_logs',
      where: "supplementId = ? AND takenAt LIKE ?",
      whereArgs: [supplementId, '$dateKey%'],
    );
  }

  Future<List<int>> getTakenSupplementIds(String dateKey) async {
    final database = await db;
    final rows = await database.query(
      'supplement_logs',
      columns: ['supplementId'],
      where: "takenAt LIKE ?",
      whereArgs: ['$dateKey%'],
    );
    return rows.map((r) => r['supplementId'] as int).toList();
  }

  // --- Water Log ---

  Future<void> logWater(int amount) async {
    final database = await db;
    await database.insert('water_logs', {
      'amount': amount,
      'loggedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<WaterLog>> getWaterLogs(String dateKey) async {
    final database = await db;
    final rows = await database.query(
      'water_logs',
      where: "loggedAt LIKE ?",
      whereArgs: ['$dateKey%'],
      orderBy: 'loggedAt DESC',
    );
    return rows.map(WaterLog.fromMap).toList();
  }

  Future<int> getTodayWaterTotal(String dateKey) async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT SUM(amount) as total FROM water_logs WHERE loggedAt LIKE ?",
      ['$dateKey%'],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> deleteLastWaterLog(String dateKey) async {
    final database = await db;
    final rows = await database.query(
      'water_logs',
      where: "loggedAt LIKE ?",
      whereArgs: ['$dateKey%'],
      orderBy: 'loggedAt DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await database.delete(
        'water_logs',
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
    }
  }

  // --- 마이그레이션 ---

  /// v1.1.0 이전에 캐시 경로로 저장된 영양제 사진을 앱 문서 폴더로 구출.
  /// 캐시에서 이미 지워진 사진은 NULL 처리. FK OFF 시절 생긴 고아 로그도 정리.
  /// 멱등적이므로 앱 시작 시마다 호출해도 안전하다.
  Future<int> migrateLegacyImages() async {
    final database = await db;
    final dirPath = await ImageStore.imagesDirPath();
    var migrated = 0;
    final rows = await database.query('supplements',
        columns: ['id', 'imagePath'], where: 'imagePath IS NOT NULL');
    for (final row in rows) {
      final path = row['imagePath'] as String;
      if (isWithin(dirPath, path)) continue;
      final newPath = await ImageStore.persistPath(path);
      await database.update('supplements', {'imagePath': newPath},
          where: 'id = ?', whereArgs: [row['id']]);
      migrated++;
    }
    await database.delete(
      'supplement_logs',
      where: 'supplementId NOT IN (SELECT id FROM supplements)',
    );
    return migrated;
  }
}
