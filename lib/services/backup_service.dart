import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import 'image_store.dart';

/// DB + 사진을 ZIP 하나로 백업/복원.
/// 설정값(목표량·알림)은 백업에 포함되지 않는다.
class BackupService {
  static const _appId = 'haru_1min';
  static const _dbName = 'haru1min.db';

  static Future<String> _dbPath() async =>
      p.join(await getDatabasesPath(), _dbName);

  /// ZIP 생성 후 공유 시트 표시. 성공 시 null, 실패 시 사용자용 메시지 반환
  static Future<String?> exportBackup() async {
    try {
      await DbHelper().close(); // 닫아서 WAL 내용까지 파일에 반영
      final dbFile = File(await _dbPath());
      if (!await dbFile.exists()) return '백업할 데이터가 없어요.';

      final tmp = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .substring(0, 16)
          .replaceAll(':', '-');
      final zipPath = p.join(tmp.path, '${_appId}_backup_$stamp.zip');

      final manifest = File(p.join(tmp.path, 'manifest.json'));
      await manifest.writeAsString(jsonEncode({
        'app': _appId,
        'created_at': DateTime.now().toIso8601String(),
      }));

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addFile(manifest);
      await encoder.addFile(dbFile, _dbName);
      final imagesDir = Directory(await ImageStore.imagesDirPath());
      if (await imagesDir.exists()) {
        for (final f in imagesDir.listSync().whereType<File>()) {
          await encoder.addFile(f, 'images/${p.basename(f.path)}');
        }
      }
      await encoder.close();

      await Share.shareXFiles([XFile(zipPath)], text: '하루 1분 백업');
      return null;
    } catch (e) {
      return '백업 생성에 실패했어요. ($e)';
    }
  }

  /// ZIP 선택 → 검증 → DB·사진 교체. 원자적으로 동작한다:
  /// 임시 경로에 먼저 풀어 스키마를 검증하고, 통과한 경우에만 현재 DB를
  /// .bak로 백업한 뒤 교체한다. 교체 중 실패하면 원본으로 롤백한다.
  /// 성공 시 null, 사용자가 선택을 취소하면 'cancelled', 실패 시 메시지 반환
  static Future<String?> importBackup() async {
    String? rollbackPath; // 교체 중 실패 시 복구할 원본 DB 사본
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final path = picked?.files.single.path;
      if (path == null) return 'cancelled';

      final archive =
          ZipDecoder().decodeBytes(await File(path).readAsBytes());

      ArchiveFile? manifestEntry;
      ArchiveFile? dbEntry;
      for (final f in archive.files) {
        if (!f.isFile) continue;
        if (f.name == 'manifest.json') manifestEntry = f;
        if (f.name == _dbName) dbEntry = f;
      }
      if (manifestEntry == null || dbEntry == null) {
        return '올바른 백업 파일이 아니에요.';
      }
      final manifest =
          jsonDecode(utf8.decode(manifestEntry.content)) as Map<String, dynamic>;
      if (manifest['app'] != _appId) return '다른 앱의 백업 파일이에요.';

      // 1) 임시 파일에 먼저 풀고 sqlite로 열어 스키마 검증 (현재 DB는 아직 건드리지 않음)
      final tmpDir = await getTemporaryDirectory();
      final stagedPath = p.join(tmpDir.path, 'restore_staged.db');
      await File(stagedPath).writeAsBytes(dbEntry.content, flush: true);
      final validationError = await _validateDb(stagedPath);
      if (validationError != null) {
        await _safeDelete(stagedPath);
        return validationError;
      }

      // 2) 검증 통과 — 현재 DB를 .bak로 백업하고 원자적으로 교체
      final db = DbHelper();
      await db.close();
      final livePath = await _dbPath();
      final liveFile = File(livePath);
      if (await liveFile.exists()) {
        rollbackPath = '$livePath.bak';
        await liveFile.copy(rollbackPath);
      }
      try {
        await File(stagedPath).copy(livePath);
        // 교체된 DB와 충돌하지 않도록 이전 연결의 WAL/SHM 사이드카 제거
        await _safeDelete('$livePath-wal');
        await _safeDelete('$livePath-shm');
      } catch (e) {
        // 교체 실패 → 원본 복구 후 중단
        if (rollbackPath != null) await File(rollbackPath).copy(livePath);
        rethrow;
      }
      await _safeDelete(stagedPath);

      // 3) DB 교체가 확정된 뒤에만 사진 폴더 교체 (파괴적 작업)
      final imagesDirPath = await ImageStore.imagesDirPath();
      final imagesDir = Directory(imagesDirPath);
      if (await imagesDir.exists()) await imagesDir.delete(recursive: true);
      await imagesDir.create(recursive: true);
      for (final f in archive.files) {
        if (f.isFile && f.name.startsWith('images/')) {
          await File(p.join(imagesDirPath, p.basename(f.name)))
              .writeAsBytes(f.content);
        }
      }

      // 다른 기기 백업 대비: DB의 사진 절대경로를 현재 기기 경로로 재작성
      await _rewriteImagePaths(imagesDirPath);

      await _safeDelete(rollbackPath); // 성공 — 롤백 사본 정리
      return null;
    } catch (e) {
      // 예외 발생 시 원본 DB 복구 시도
      if (rollbackPath != null) {
        try {
          await File(rollbackPath).copy(await _dbPath());
          await _safeDelete(rollbackPath);
        } catch (_) {}
      }
      return '복원에 실패했어요. 파일을 확인해주세요. ($e)';
    }
  }

  /// 스테이징된 DB 파일을 읽기 전용으로 열어 필수 테이블이 모두 있는지 확인한다.
  /// 정상이면 null, 손상·형식 불일치면 사용자용 메시지를 반환한다.
  static Future<String?> _validateDb(String path) async {
    Database? test;
    try {
      test = await openReadOnlyDatabase(path);
      final rows = await test.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name IN ('supplements','supplement_logs','water_logs')",
      );
      if (rows.length < 3) {
        return '백업 파일의 데이터 형식이 올바르지 않아요.';
      }
      return null;
    } catch (_) {
      return '백업 파일이 손상되었거나 올바른 형식이 아니에요.';
    } finally {
      await test?.close();
    }
  }

  /// 존재할 때만 조용히 삭제 (정리/롤백용). 실패는 무시한다.
  static Future<void> _safeDelete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<void> _rewriteImagePaths(String imagesDirPath) async {
    final d = await DbHelper().db;
    final rows = await d.query('supplements',
        columns: ['id', 'imagePath'], where: 'imagePath IS NOT NULL');
    for (final row in rows) {
      final newPath =
          p.join(imagesDirPath, p.basename(row['imagePath'] as String));
      await d.update(
        'supplements',
        {'imagePath': await File(newPath).exists() ? newPath : null},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }
}
