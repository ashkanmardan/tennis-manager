import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/coach.dart';
import '../models/session.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/ball_cost.dart';
import '../../core/utils/jalali_helper.dart';

class AppRepository extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ─── State ────────────────────────────────────────────────────────────────
  List<Student> _students = [];
  List<Coach> _coaches = [];
  List<Session> _sessions = [];
  Coach? _activeCoach;
  bool _isLoading = false;

  List<Student> get students => _students;
  List<Coach> get coaches => _coaches;
  List<Session> get sessions => _sessions;
  Coach? get activeCoach => _activeCoach;
  bool get isLoading => _isLoading;

  List<Student> get activeStudents => _students.where((s) => s.isActive).toList();

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadStudents(),
        _loadCoaches(),
        _loadSessions(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Students ─────────────────────────────────────────────────────────────

  Future<void> _loadStudents() async {
    _students = await _db.getAllStudents();
  }

  Future<void> addStudent(Student student) async {
    final id = await _db.insertStudent(student);
    _students.add(student.copyWith(id: id));
    _students.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateStudent(Student student) async {
    await _db.updateStudent(student);
    final idx = _students.indexWhere((s) => s.id == student.id);
    if (idx != -1) _students[idx] = student;
    notifyListeners();
  }

  Future<void> deactivateStudent(Student student) async {
    final updated = student.copyWith(isActive: false);
    await updateStudent(updated);
  }

  // ─── Coaches ──────────────────────────────────────────────────────────────

  Future<void> _loadCoaches() async {
    _coaches = await _db.getAllCoaches();
    final active = _coaches.where((c) => c.isActive).toList();
    _activeCoach = active.isNotEmpty ? active.first : null;
  }

  Future<void> addCoach(Coach coach) async {
    // deactivates previous active coach automatically in DB
    final id = await _db.insertCoach(coach);
    await _loadCoaches();
    notifyListeners();
  }

  Future<void> deactivateCoach(int id) async {
    await _db.deactivateCoach(id);
    await _loadCoaches();
    notifyListeners();
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    _sessions = await _db.getAllSessions();
  }

  Future<Session> addSession(Session session) async {
    final id = await _db.insertSession(session);
    final saved = session.copyWith(id: id);
    _sessions.insert(0, saved);
    notifyListeners();
    return saved;
  }

  Future<void> updateSession(Session session) async {
    await _db.updateSession(session);
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) _sessions[idx] = session;
    notifyListeners();
  }

  Future<void> deleteSession(int id) async {
    await _db.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<Session> getSessionsForJalaliMonth(int year, int month) {
    return _sessions.where((s) {
      final j = JalaliHelper.toJalali(s.date);
      return j.year == year && j.month == month;
    }).toList();
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  Future<void> saveAttendance(int sessionId, Map<int, bool> presentMap) async {
    final attendanceList = presentMap.entries.map((e) => Attendance(
          sessionId: sessionId,
          studentId: e.key,
          present: e.value,
        )).toList();
    await _db.setAttendance(attendanceList);
  }

  Future<List<Attendance>> getAttendanceForSession(int sessionId) =>
      _db.getAttendanceForSession(sessionId);

  Future<List<Attendance>> getAttendanceForStudent(int studentId) =>
      _db.getAttendanceForStudent(studentId);

  // ─── Payments ─────────────────────────────────────────────────────────────

  Future<void> addPayment(Payment payment) async {
    await _db.insertPayment(payment);
    notifyListeners();
  }

  Future<List<Payment>> getPaymentsForStudent(int studentId) =>
      _db.getPaymentsForStudent(studentId);

  Future<List<Payment>> getAllPayments({DateTime? from, DateTime? to}) =>
      _db.getAllPayments(from: from, to: to);

  Future<void> deletePayment(int id) async {
    await _db.deletePayment(id);
    notifyListeners();
  }

  /// Calculate student's debt for session-based fee
  Future<int> getStudentDebt(Student student, {DateTime? from, DateTime? to}) async {
    final totalPaid = await _db.getTotalPaidByStudent(student.id!);

    if (student.feeType == 'monthly') {
      // Monthly: compare months registered vs paid
      // Simplified: total owed = months since joined × fee
      final monthsActive = _monthsSince(student.createdAt);
      final totalOwed = monthsActive * student.feeAmount;
      return (totalOwed - totalPaid).clamp(0, double.maxFinite).toInt();
    } else {
      // Session-based: attended sessions × fee per session
      final sessionCount = await _db.getStudentSessionCount(
        student.id!,
        from: from,
        to: to,
      );
      final totalOwed = sessionCount * student.feeAmount;
      return (totalOwed - totalPaid).clamp(0, double.maxFinite).toInt();
    }
  }

  int _monthsSince(DateTime date) {
    final now = DateTime.now();
    return (now.year - date.year) * 12 + now.month - date.month;
  }

  // ─── Ball Costs ───────────────────────────────────────────────────────────

  Future<void> addBallCost(BallCost cost) async {
    await _db.insertBallCost(cost);
    notifyListeners();
  }

  Future<List<BallCost>> getAllBallCosts() => _db.getAllBallCosts();

  Future<void> deleteBallCost(int id) async {
    await _db.deleteBallCost(id);
    notifyListeners();
  }

  // ─── Backup ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportBackup() => _db.exportAll();

  Future<void> importBackup(Map<String, dynamic> data) async {
    await _db.importAll(data);
    await loadAll();
  }

  // ─── Reports ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMonthlyReport(int jYear, int jMonth) async {
    final monthSessions = getSessionsForJalaliMonth(jYear, jMonth);
    final payments = await getAllPayments();

    // Filter payments for this Jalali month
    final monthPayments = payments.where((p) {
      return JalaliHelper.isSameJalaliMonth(
        p.date,
        JalaliHelper.toDateTime(jYear, jMonth, 1),
      );
    }).toList();

    final totalIncome = monthPayments.fold(0, (sum, p) => sum + p.amount);
    final ballCostTotal = await _db.getTotalBallCosts();

    return {
      'session_count': monthSessions.length,
      'regular_sessions': monthSessions.where((s) => s.isRegular).length,
      'makeup_sessions': monthSessions.where((s) => s.isMakeup).length,
      'cancelled_sessions': monthSessions.where((s) => s.coachCancelled).length,
      'total_income': totalIncome,
      'total_ball_costs': ballCostTotal,
      'payment_count': monthPayments.length,
    };
  }
}
