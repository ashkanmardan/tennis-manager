import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/training_package.dart';

class PackageRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;
  Future<Database> get _db async => _helper.database;

  Future<List<TrainingPackage>> getAll() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.*,
        (SELECT COUNT(*) FROM sessions s
         WHERE s.package_id = p.id
           AND s.status = 'completed'
           AND s.is_makeup = 0) AS completed_sessions,
        (SELECT COALESCE(SUM(py.amount), 0) FROM payments py
         WHERE py.package_id = p.id) AS paid_amount
      FROM packages p
      ORDER BY p.is_active DESC, p.created_at DESC
    ''');
    return rows.map(TrainingPackage.fromMap).toList();
  }

  Future<TrainingPackage?> getActive() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.*,
        (SELECT COUNT(*) FROM sessions s
         WHERE s.package_id = p.id
           AND s.status = 'completed'
           AND s.is_makeup = 0) AS completed_sessions,
        (SELECT COALESCE(SUM(py.amount), 0) FROM payments py
         WHERE py.package_id = p.id) AS paid_amount
      FROM packages p
      WHERE p.is_active = 1
      LIMIT 1
    ''');
    return rows.isEmpty ? null : TrainingPackage.fromMap(rows.first);
  }

  Future<int> insert(TrainingPackage pkg) async {
    final db = await _db;
    // غیرفعال کردن پکیج فعلی
    await db.update('packages', {'is_active': 0},
        where: 'is_active = 1');
    return db.insert('packages', pkg.toMap());
  }

  Future<void> update(TrainingPackage pkg) async {
    final db = await _db;
    await db.update('packages', pkg.toMap(),
        where: 'id = ?', whereArgs: [pkg.id]);
  }

  Future<void> deactivate(int id) async {
    final db = await _db;
    await db.update('packages', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
  }
}
