import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'tennis_player.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE player (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT '',
        birth_date TEXT,
        phone TEXT,
        coach_name TEXT NOT NULL DEFAULT '',
        coach_phone TEXT,
        coach_instagram TEXT,
        coach_card_number TEXT,
        club_name TEXT,
        training_days TEXT NOT NULL DEFAULT '[]',
        training_time TEXT NOT NULL DEFAULT '17:00',
        session_duration INTEGER NOT NULL DEFAULT 60,
        class_participants INTEGER NOT NULL DEFAULT 1,
        onboarding_complete INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE packages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        total_sessions INTEGER NOT NULL,
        price INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduled_date TEXT NOT NULL,
        jalali_year INTEGER NOT NULL,
        jalali_month INTEGER NOT NULL,
        time TEXT,
        duration INTEGER NOT NULL DEFAULT 60,
        status TEXT NOT NULL DEFAULT 'upcoming',
        notes TEXT,
        package_id INTEGER REFERENCES packages(id),
        is_makeup INTEGER NOT NULL DEFAULT 0,
        makeup_for_session_id INTEGER REFERENCES sessions(id),
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        payment_date TEXT NOT NULL,
        package_id INTEGER REFERENCES packages(id),
        notes TEXT,
        receipt_image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new player fields
      try { await db.execute('ALTER TABLE player ADD COLUMN coach_phone TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE player ADD COLUMN coach_instagram TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE player ADD COLUMN coach_card_number TEXT'); } catch (_) {}
      // Add receipt field to payments
      try { await db.execute('ALTER TABLE payments ADD COLUMN receipt_image_path TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE player ADD COLUMN class_participants INTEGER NOT NULL DEFAULT 1'); } catch (_) {}
    }
  }
}
