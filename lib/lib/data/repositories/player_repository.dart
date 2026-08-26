import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/player.dart';

class PlayerRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;
  Future<Database> get _db async => _helper.database;

  Future<Player?> get() async {
    final db = await _db;
    final rows = await db.query('player', limit: 1);
    return rows.isEmpty ? null : Player.fromMap(rows.first);
  }

  Future<void> save(Player player) async {
    final db = await _db;
    await db.insert('player', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isOnboardingComplete() async {
    final player = await get();
    return player?.onboardingComplete ?? false;
  }
}
