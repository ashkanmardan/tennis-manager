import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';

class FinanceRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;
  Future<Database> get _db async => _helper.database;

  Future<List<Payment>> getAll() async {
    final db = await _db;
    final rows = await db.query('payments', orderBy: 'payment_date DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getByPackage(int packageId) async {
    final db = await _db;
    final rows = await db.query('payments',
        where: 'package_id = ?', whereArgs: [packageId],
        orderBy: 'payment_date DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<int> getTotalPaid({int? packageId}) async {
    final db = await _db;
    String where = '';
    List<dynamic> args = [];
    if (packageId != null) {
      where = 'WHERE package_id = ?';
      args = [packageId];
    }
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) AS total FROM payments $where', args);
    return (rows.first['total'] as num? ?? 0).toInt();
  }

  Future<int> insert(Payment payment) async {
    final db = await _db;
    return db.insert('payments', payment.toMap());
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
}
