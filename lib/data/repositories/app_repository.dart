import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/player.dart';
import '../models/session.dart';
import '../models/training_package.dart';
import '../models/payment.dart';
import 'player_repository.dart';
import 'session_repository.dart';
import 'package_repository.dart';
import 'finance_repository.dart';

class AppRepository extends ChangeNotifier {
  final _playerRepo  = PlayerRepository();
  final _sessionRepo = SessionRepository();
  final _pkgRepo     = PackageRepository();
  final _finRepo     = FinanceRepository();

  // ── state ──────────────────────────────────────────────────────────────────
  Player?          player;
  Session?         nextSession;
  Session?         lastSession;
  Session?         unresolvedPastSession;
  TrainingPackage? activePackage;
  int              makeupCount    = 0;
  int              coachDebtCount = 0;
  bool             isLoading      = true;

  // ── sub-repo accessors ─────────────────────────────────────────────────────
  PlayerRepository  get playerRepo  => _playerRepo;
  SessionRepository get sessionRepo => _sessionRepo;
  PackageRepository get packageRepo => _pkgRepo;
  FinanceRepository get financeRepo => _finRepo;

  // ── load all ───────────────────────────────────────────────────────────────
  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    try {
      player         = await _playerRepo.get();
      nextSession              = await _sessionRepo.getNextUpcoming();
      lastSession              = await _sessionRepo.getLastCompleted();
      unresolvedPastSession    = await _sessionRepo.getUnresolvedPastSession();
      activePackage  = await _pkgRepo.getActive();
      makeupCount    = await _sessionRepo.getMakeupCount();
      coachDebtCount = await _sessionRepo.getCoachDebtCount();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── convenience ────────────────────────────────────────────────────────────
  Future<void> completeOnboarding({
    required Player player,
    required TrainingPackage package,
    required List<Session> sessions,
  }) async {
    final db = await DatabaseHelper.instance.database;
    // Publish completion only after the profile, package and sessions all exist.
    await db.transaction((txn) async {
      await txn.update('packages', {'is_active': 0}, where: 'is_active = 1');
      final packageId = await txn.insert('packages', package.toMap());
      for (final session in sessions) {
        await txn.insert('sessions', session.copyWith(packageId: packageId).toMap());
      }
      await txn.insert('player', player.copyWith(onboardingComplete: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await loadAll();
  }

  Future<void> savePlayer(Player p) async {
    await _playerRepo.save(p);
    player = p;
    notifyListeners();
  }

  Future<void> addSession(Session s) async {
    await _sessionRepo.insert(s);
    await loadAll();
  }

  Future<void> updateSessionStatus(int id, SessionStatus status,
      {String? notes}) async {
    await _sessionRepo.updateStatus(id, status, notes: notes);
    await loadAll();
  }

  Future<void> addPackage(TrainingPackage pkg) async {
    await _pkgRepo.insert(pkg);
    await loadAll();
  }

  Future<void> addPayment(Payment payment) async {
    await _finRepo.insert(payment);
    await loadAll();
  }

  bool get isOnboarded => player?.onboardingComplete == true;
}
