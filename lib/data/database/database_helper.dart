import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';
import '../models/student.dart';
import '../models/coach.dart';
import '../models/session.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/ball_cost.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE coaches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        fee_type TEXT NOT NULL DEFAULT 'monthly',
        fee_amount INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        session_type TEXT NOT NULL DEFAULT 'regular',
        coach_id INTEGER,
        venue TEXT,
        coach_cancelled INTEGER NOT NULL DEFAULT 0,
        requires_makeup INTEGER NOT NULL DEFAULT 0,
        original_session_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (coach_id) REFERENCES coaches(id),
        FOREIGN KEY (original_session_id) REFERENCES sessions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        present INTEGER NOT NULL DEFAULT 1,
        is_makeup_for INTEGER NOT NULL DEFAULT 0,
        makeup_for_session_id INTEGER,
        notes TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id),
        UNIQUE(session_id, student_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        receipt_note TEXT,
        session_id INTEGER,
        payment_for TEXT NOT NULL DEFAULT 'tuition',
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students(id),
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ball_costs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_cost INTEGER NOT NULL,
        session_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    ''');

    // Index for performance
    await db.execute('CREATE INDEX idx_attendance_session ON attendance(session_id)');
    await db.execute('CREATE INDEX idx_attendance_student ON attendance(student_id)');
    await db.execute('CREATE INDEX idx_payments_student ON payments(student_id)');
    await db.execute('CREATE INDEX idx_sessions_date ON sessions(date)');
  }

  // ─── COACHES ─────────────────────────────────────────────────────────────

  Future<int> insertCoach(Coach coach) async {
    final db = await database;
    // Deactivate all existing active coaches before inserting new one
    await db.update('coaches', {'is_active': 0}, where: 'is_active = 1');
    return db.insert('coaches', coach.toMap());
  }

  Future<Coach?> getActiveCoach() async {
    final db = await database;
    final maps = await db.query('coaches', where: 'is_active = 1', limit: 1);
    return maps.isEmpty ? null : Coach.fromMap(maps.first);
  }

  Future<List<Coach>> getAllCoaches() async {
    final db = await database;
    final maps = await db.query('coaches', orderBy: 'start_date DESC');
    return maps.map(Coach.fromMap).toList();
  }

  Future<int> updateCoach(Coach coach) async {
    final db = await database;
    return db.update('coaches', coach.toMap(), where: 'id = ?', whereArgs: [coach.id]);
  }

  Future<void> deactivateCoach(int id) async {
    final db = await database;
    await db.update(
      'coaches',
      {'is_active': 0, 'end_date': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── STUDENTS ─────────────────────────────────────────────────────────────

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return db.insert('students', student.toMap());
  }

  Future<List<Student>> getActiveStudents() async {
    final db = await database;
    final maps = await db.query('students', where: 'is_active = 1', orderBy: 'name ASC');
    return maps.map(Student.fromMap).toList();
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final maps = await db.query('students', orderBy: 'is_active DESC, name ASC');
    return maps.map(Student.fromMap).toList();
  }

  Future<Student?> getStudent(int id) async {
    final db = await database;
    final maps = await db.query('students', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Student.fromMap(maps.first);
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return db.update('students', student.toMap(), where: 'id = ?', whereArgs: [student.id]);
  }

  // ─── SESSIONS ─────────────────────────────────────────────────────────────

  Future<int> insertSession(Session session) async {
    final db = await database;
    return db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    return maps.map(Session.fromMap).toList();
  }

  Future<List<Session>> getSessionsInMonth(int year, int month) async {
    // Get Jalali month range as Gregorian
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    final sessions = maps.map(Session.fromMap).toList();
    // Filter by Jalali month (done in app layer for simplicity)
    return sessions;
  }

  Future<Session?> getSession(int id) async {
    final db = await database;
    final maps = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Session.fromMap(maps.first);
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return db.update('sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────

  Future<void> setAttendance(List<Attendance> attendanceList) async {
    final db = await database;
    final batch = db.batch();
    for (final a in attendanceList) {
      batch.insert(
        'attendance',
        a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Attendance>> getAttendanceForSession(int sessionId) async {
    final db = await database;
    final maps = await db.query('attendance', where: 'session_id = ?', whereArgs: [sessionId]);
    return maps.map(Attendance.fromMap).toList();
  }

  Future<List<Attendance>> getAttendanceForStudent(int studentId) async {
    final db = await database;
    final maps = await db.query('attendance', where: 'student_id = ?', whereArgs: [studentId]);
    return maps.map(Attendance.fromMap).toList();
  }

  /// Count sessions a student attended (excluding makeup sessions they owe)
  Future<int> getStudentSessionCount(int studentId, {DateTime? from, DateTime? to}) async {
    final db = await database;
    String where = 'a.student_id = ? AND a.present = 1';
    final args = <dynamic>[studentId];
    if (from != null) {
      where += ' AND s.date >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where += ' AND s.date <= ?';
      args.add(to.toIso8601String());
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance a JOIN sessions s ON a.session_id = s.id WHERE $where',
      args,
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ─── PAYMENTS ────────────────────────────────────────────────────────────

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsForStudent(int studentId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
    return maps.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getAllPayments({DateTime? from, DateTime? to}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (from != null || to != null) {
      final conditions = <String>[];
      args = [];
      if (from != null) {
        conditions.add('date >= ?');
        args.add(from.toIso8601String());
      }
      if (to != null) {
        conditions.add('date <= ?');
        args.add(to.toIso8601String());
      }
      where = conditions.join(' AND ');
    }
    final maps = await db.query('payments', where: where, whereArgs: args, orderBy: 'date DESC');
    return maps.map(Payment.fromMap).toList();
  }

  Future<int> getTotalPaidByStudent(int studentId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM payments WHERE student_id = ? AND payment_for = 'tuition'",
      [studentId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return db.update('payments', payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
  }

  Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── BALL COSTS ───────────────────────────────────────────────────────────

  Future<int> insertBallCost(BallCost cost) async {
    final db = await database;
    return db.insert('ball_costs', cost.toMap());
  }

  Future<List<BallCost>> getAllBallCosts() async {
    final db = await database;
    final maps = await db.query('ball_costs', orderBy: 'date DESC');
    return maps.map(BallCost.fromMap).toList();
  }

  Future<int> getTotalBallCosts({DateTime? from, DateTime? to}) async {
    final db = await database;
    String query = 'SELECT SUM(total_cost) as total FROM ball_costs';
    final args = <dynamic>[];
    if (from != null || to != null) {
      final conditions = <String>[];
      if (from != null) { conditions.add('date >= ?'); args.add(from.toIso8601String()); }
      if (to != null) { conditions.add('date <= ?'); args.add(to.toIso8601String()); }
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    final result = await db.rawQuery(query, args);
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> deleteBallCost(int id) async {
    final db = await database;
    await db.delete('ball_costs', where: 'id = ?', whereArgs: [id]);
  }

  // ─── BACKUP ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    return {
      'coaches': await db.query('coaches'),
      'students': await db.query('students'),
      'sessions': await db.query('sessions'),
      'attendance': await db.query('attendance'),
      'payments': await db.query('payments'),
      'ball_costs': await db.query('ball_costs'),
      'version': AppConstants.dbVersion,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear all tables
      await txn.delete('attendance');
      await txn.delete('payments');
      await txn.delete('ball_costs');
      await txn.delete('sessions');
      await txn.delete('students');
      await txn.delete('coaches');

      // Re-insert
      for (final row in (data['coaches'] as List)) {
        await txn.insert('coaches', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['students'] as List)) {
        await txn.insert('students', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['sessions'] as List)) {
        await txn.insert('sessions', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['attendance'] as List)) {
        await txn.insert('attendance', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['payments'] as List)) {
        await txn.insert('payments', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['ball_costs'] as List)) {
        await txn.insert('ball_costs', Map<String, dynamic>.from(row as Map));
      }
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
