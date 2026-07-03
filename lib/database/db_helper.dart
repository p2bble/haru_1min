import 'dart:io';

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

  /// DB 연결을 닫는다 (백업 전 WAL 반영, 복원 시 파일 교체용). 다음 접근 시 자동 재오픈.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'haru1min.db'),
      version: 3,
      // sqflite는 FK가 기본 OFF — 켜야 supplement_logs CASCADE가 동작한다
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE supplements ADD COLUMN memo TEXT');
        }
        if (oldVersion < 3) {
          // 라벨 성분(JSON). 기존 영양제는 NULL → "다시 분석" 시 채워진다.
          await db.execute('ALTER TABLE supplements ADD COLUMN nutrients TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE supplements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            imagePath TEXT,
            mealTime TEXT NOT NULL,
            memo TEXT,
            nutrients TEXT,
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

  // --- 통계 ---

  /// [fromKey]('yyyy-MM-dd') 이후의 일별 물 섭취 합계 (날짜키 → ml)
  Future<Map<String, int>> getDailyWaterTotals(String fromKey) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT substr(loggedAt, 1, 10) AS day, SUM(amount) AS total
      FROM water_logs
      WHERE substr(loggedAt, 1, 10) >= ?
      GROUP BY day
    ''', [fromKey]);
    return {
      for (final r in rows) r['day'] as String: (r['total'] as int?) ?? 0,
    };
  }

  /// [fromKey] 이후의 일별 복용한 영양제 종류 수 (날짜키 → distinct 수)
  Future<Map<String, int>> getDailySupplementCounts(String fromKey) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT substr(takenAt, 1, 10) AS day,
             COUNT(DISTINCT supplementId) AS cnt
      FROM supplement_logs
      WHERE substr(takenAt, 1, 10) >= ?
      GROUP BY day
    ''', [fromKey]);
    return {
      for (final r in rows) r['day'] as String: (r['cnt'] as int?) ?? 0,
    };
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
    await _sweepOrphanImages(database, dirPath);
    return migrated;
  }

  /// 어떤 영양제도 참조하지 않는 이미지 파일 삭제.
  /// 사진을 고른 뒤 저장하지 않고 나가면 파일이 남는데, 그대로 두면
  /// 문서 폴더에 계속 쌓인다. 등록 진행 중인 사진을 지우지 않도록
  /// 하루 이상 지난 파일만 대상으로 한다. 실패는 치명적이지 않으므로 무시.
  Future<void> _sweepOrphanImages(Database database, String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      final rows = await database.query('supplements',
          columns: ['imagePath'], where: 'imagePath IS NOT NULL');
      final referenced = rows.map((r) => r['imagePath'] as String).toSet();
      final cutoff = DateTime.now().subtract(const Duration(days: 1));
      for (final f in dir.listSync().whereType<File>()) {
        if (referenced.contains(f.path)) continue;
        try {
          if ((await f.lastModified()).isBefore(cutoff)) await f.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
