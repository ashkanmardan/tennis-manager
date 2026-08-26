import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/session.dart';

class SessionRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;
  Future<Database> get _db async => _helper.database;

  Future<List<Session>> getAll() async {
    final db = await _db;
    final rows = await db.query('sessions', orderBy: 'scheduled_date DESC');
    return rows.map(Session.fromMap).toList();
  }

  Future<List<Session>> getByMonth(int year, int month) async {
    final db = await _db;
    final rows = await db.query('sessions',
        where: 'jalali_year = ? AND jalali_month = ?',
        whereArgs: [year, month],
        orderBy: 'scheduled_date ASC');
    return rows.map(Session.fromMap).toList();
  }

  Future<Session?> getNextUpcoming() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query('sessions',
        where: "status = 'upcoming' AND scheduled_date >= ?",
        whereArgs: [today],
        orderBy: 'scheduled_date ASC',
        limit: 1);
    return rows.isEmpty ? null : Session.fromMap(rows.first);
  }

  Future<Session?> getLastCompleted() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query('sessions',
        where: "status != 'upcoming' AND scheduled_date <= ?",
        whereArgs: [today],
        orderBy: 'scheduled_date DESC',
        limit: 1);
    return rows.isEmpty ? null : Session.fromMap(rows.first);
  }

  Future<List<Session>> getMakeupSessions() async {
    final db = await _db;
    final rows = await db.query('sessions',
        where: "is_makeup = 1 AND status = 'upcoming'",
        orderBy: 'scheduled_date ASC');
    return rows.map(Session.fromMap).toList();
  }

  Future<int> getMakeupCount() async {
    final db = await _db;
    // جلسات لغو‌شده‌ای که هنوز جبرانی برایشان ثبت نشده
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM sessions
      WHERE status IN ('cancelledByCoach','weather')
        AND id NOT IN (
          SELECT COALESCE(makeup_for_session_id, -1) FROM sessions
          WHERE is_makeup = 1
        )
    ''');
    return (rows.first['cnt'] as int? ?? 0);
  }

  /// تعداد جلساتی که استاد به تنیسور بدهکار است (لغو مربی + آب‌وهوا + تعطیل غیررسمی)
  Future<int> getCoachDebtCount() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM sessions
      WHERE status IN ('cancelledByCoach','weather','holiday')
        AND is_makeup = 0
    ''');
    return (rows.first['cnt'] as int? ?? 0);
  }

  /// لیست جلساتی که استاد به تنیسور بدهکار است
  Future<List<Session>> getCoachDebtSessions() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT * FROM sessions
      WHERE status IN ('cancelledByCoach','weather','holiday')
        AND is_makeup = 0
      ORDER BY scheduled_date DESC
    ''');
    return rows.map(Session.fromMap).toList();
  }

  Future<int> insert(Session session) async {
    final db = await _db;
    return db.insert('sessions', session.toMap());
  }

  Future<void> updateStatus(int id, SessionStatus status, {String? notes}) async {
    final db = await _db;
    final map = <String, dynamic>{'status': status.toDb()};
    if (notes != null) map['notes'] = notes;
    await db.update('sessions', map, where: 'id = ?', whereArgs: [id]);

    // اگر باید جبرانی ایجاد شود
    if (status.createsMakeup) {
      final rows = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final original = Session.fromMap(rows.first);
        // ثبت جلسه جبرانی بدون تاریخ (تاریخ بعداً تعیین می‌شود)
        await db.insert('sessions', {
          'scheduled_date': '9999-01-01', // placeholder
          'jalali_year': 9999,
          'jalali_month': 1,
          'duration': original.duration,
          'status': SessionStatus.upcoming.toDb(),
          'package_id': original.packageId,
          'is_makeup': 1,
          'makeup_for_session_id': id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> update(Session session) async {
    final db = await _db;
    await db.update('sessions', session.toMap(),
        where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countCompleted({int? packageId}) async {
    final db = await _db;
    String where = "status = 'completed' AND is_makeup = 0";
    List<dynamic> args = [];
    if (packageId != null) {
      where += ' AND package_id = ?';
      args.add(packageId);
    }
    final rows = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM sessions WHERE $where', args);
    return (rows.first['cnt'] as int? ?? 0);
  }
}
