import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/models/player.dart';
import '../../../data/repositories/app_repository.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _exporting = false;
  bool _importing = false;

  // ── پوشه ذخیره پشتیبان ─────────────────────────────────────────────────────
  Future<Directory> _backupDir() async {
    // External app-specific storage: /sdcard/Android/data/com.ashkan.tennis_manager/files/backups
    // این پوشه بدون نیاز به permission قابل دسترس است
    final ext = await getExternalStorageDirectory();
    final dir = Directory('${ext!.path}/backups');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  // ── خروجی گرفتن ────────────────────────────────────────────────────────────
  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final repo = context.read<AppRepository>();
      final sessions = await repo.sessionRepo.getAll();
      final player  = repo.player;
      final pkg     = repo.activePackage;
      final payments = pkg != null
          ? await repo.financeRepo.getByPackage(pkg.id!)
          : await repo.financeRepo.getAll();

      final data = {
        'backup_date': DateTime.now().toIso8601String(),
        'app': 'دستیار تنیس v1.0',
        'player': player != null ? {
          'name': player.name,
          'phone': player.phone,
          'coach_name': player.coachName,
          'coach_phone': player.coachPhone,
          'coach_instagram': player.coachInstagram,
          'coach_card_number': player.coachCardNumber,
          'club_name': player.clubName,
          'training_time': player.trainingTime,
          'training_days': player.trainingDays,
          'session_duration': player.sessionDuration,
          'class_participants': player.classParticipants,
        } : null,
        'package': pkg != null ? {
          'name': pkg.name,
          'total_sessions': pkg.totalSessions,
          'price': pkg.price,
          'start_date': pkg.startDate,
          'completed_sessions': pkg.completedSessions,
          'paid_amount': pkg.paidAmount,
        } : null,
        'sessions_count': sessions.length,
        'sessions': sessions.map((s) => {
          'date': s.scheduledDate,
          'status': s.status.name,
          'is_makeup': s.isMakeup,
          'duration': s.duration,
          'time': s.time,
          'notes': s.notes,
        }).toList(),
        'payments': payments.map((p) => {
          'amount': p.amount,
          'date': p.paymentDate,
          'notes': p.notes,
        }).toList(),
      };

      final json    = const JsonEncoder.withIndent('  ').convert(data);
      final j       = JalaliHelper.today;
      final dateStr = '${j.year}-${j.month.toString().padLeft(2,'0')}-${j.day.toString().padLeft(2,'0')}';
      final fileName = 'tennis_backup_$dateStr.json';

      // ذخیره در پوشه پشتیبان
      final backupDir  = await _backupDir();
      final backupFile = File('${backupDir.path}/$fileName');
      await backupFile.writeAsString(json);

      // share برای ارسال به تلگرام، گوگل درایو و ...
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'پشتیبان دستیار تنیس — $dateStr',
        text: 'فایل پشتیبان اپلیکیشن دستیار تنیس',
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── لیست فایل‌های پشتیبان ──────────────────────────────────────────────────
  Future<List<File>> _listBackups() async {
    try {
      final dir = await _backupDir();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (_) {
      return [];
    }
  }

  // ── انتخاب فایل برای بازیابی ───────────────────────────────────────────────
  Future<void> _showImportPicker() async {
    final files = await _listBackups();

    if (!mounted) return;

    if (files.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('فایل پشتیبان یافت نشد'),
          content: const Text(
            'ابتدا یه پشتیبان بگیر، یا فایل JSON پشتیبان رو از طریق اشتراک‌گذاری باز کن تا در اینجا ذخیره بشه.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('باشه'),
            ),
          ],
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<File>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('انتخاب فایل پشتیبان',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          ...files.map((f) {
            final name = f.path.split('/').last;
            final size = (f.lengthSync() / 1024).toStringAsFixed(1);
            final mod  = f.lastModifiedSync();
            final timeStr = '${mod.year}/${mod.month.toString().padLeft(2,'0')}/${mod.day.toString().padLeft(2,'0')}';
            return ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.backup_outlined,
                    color: AppColors.accent, size: 20),
              ),
              title: Text(name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text('$timeStr  •  $size KB',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () => Navigator.pop(ctx, f),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (selected != null) {
      await _doImport(selected);
    }
  }

  // ── انجام بازیابی ──────────────────────────────────────────────────────────
  Future<void> _doImport(File file) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Text('⚠️', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('بازیابی اطلاعات'),
        ]),
        content: const Text(
          'اطلاعات فعلی حذف می‌شن و با فایل پشتیبان جایگزین می‌شن.\n\nادامه می‌دی؟',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بازیابی کن'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _importing = true);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (!data.containsKey('backup_date')) {
        throw Exception('فایل پشتیبان معتبر نیست');
      }

      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        await txn.delete('payments');
        await txn.delete('sessions');
        await txn.delete('packages');
        await txn.delete('player');

        final playerData = data['player'] as Map<String, dynamic>?;
        if (playerData != null) {
          final player = Player(
            name: (playerData['name'] as String?) ?? '',
            phone: playerData['phone'] as String?,
            coachName: (playerData['coach_name'] as String?) ?? '',
            coachPhone: playerData['coach_phone'] as String?,
            coachInstagram: playerData['coach_instagram'] as String?,
            coachCardNumber: playerData['coach_card_number'] as String?,
            clubName: playerData['club_name'] as String?,
            trainingTime: (playerData['training_time'] as String?) ?? '17:00',
            trainingDays: (playerData['training_days'] as String?) ?? '[]',
            sessionDuration: (playerData['session_duration'] as int?) ?? 60,
            classParticipants: (playerData['class_participants'] as int?) ?? 1,
            onboardingComplete: true,
          );
          await txn.insert('player', player.toMap());
        }

        int? newPackageId;
        final pkgData = data['package'] as Map<String, dynamic>?;
        if (pkgData != null) {
          newPackageId = await txn.insert('packages', {
            'name': pkgData['name'] ?? 'دوره آموزشی',
            'total_sessions': pkgData['total_sessions'] ?? 0,
            'price': pkgData['price'] ?? 0,
            'start_date': pkgData['start_date'] ??
                DateTime.now().toIso8601String().substring(0, 10),
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        final sessionsList = data['sessions'] as List<dynamic>? ?? [];
        for (final s in sessionsList) {
          final sMap    = s as Map<String, dynamic>;
          final dateStr = sMap['date'] as String? ?? '';
          int jalaliYear = 1403, jalaliMonth = 1;
          try {
            final dt = DateTime.parse(dateStr);
            final j  = JalaliHelper.toJalali(dt);
            jalaliYear  = j.year;
            jalaliMonth = j.month;
          } catch (_) {}

          await txn.insert('sessions', {
            'scheduled_date': dateStr,
            'jalali_year': jalaliYear,
            'jalali_month': jalaliMonth,
            'time': sMap['time'],
            'duration': sMap['duration'] ?? 60,
            'status': sMap['status'] ?? 'upcoming',
            'notes': sMap['notes'],
            'package_id': newPackageId,
            'is_makeup': (sMap['is_makeup'] == true || sMap['is_makeup'] == 1) ? 1 : 0,
            'makeup_for_session_id': null,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        final paymentsList = data['payments'] as List<dynamic>? ?? [];
        for (final p in paymentsList) {
          final pMap = p as Map<String, dynamic>;
          await txn.insert('payments', {
            'amount': pMap['amount'] ?? 0,
            'payment_date': pMap['date'] ??
                DateTime.now().toIso8601String().substring(0, 10),
            'notes': pMap['notes'],
            'package_id': newPackageId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      });

      if (mounted) {
        final repo = context.read<AppRepository>();
        await repo.loadAll();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ بازیابی موفق بود!'),
          backgroundColor: AppColors.accent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('پشتیبان‌گیری',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        children: [
          Center(child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: Text('💾',
                style: TextStyle(fontSize: 44))),
          )),
          const SizedBox(height: 20),
          const Center(child: Text('پشتیبان‌گیری از اطلاعات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark))),
          const SizedBox(height: 6),
          const Center(child: Text('تمام داده‌هات ذخیره و قابل انتقال می‌شه',
              style: TextStyle(fontSize: 13, color: Colors.grey))),
          const SizedBox(height: 32),

          // خروجی
          _ActionCard(
            icon: Icons.upload_outlined,
            iconColor: AppColors.primary,
            title: 'خروجی گرفتن (Export)',
            subtitle: 'تمام جلسات، پرداخت‌ها و اطلاعات رو به فایل JSON ذخیره کن',
            child: _exporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2)))
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                    label: const Text('خروجی و اشتراک‌گذاری',
                        style: TextStyle(color: Colors.white)),
                    onPressed: _export,
                  ),
          ),
          const SizedBox(height: 14),

          // بازیابی
          _ActionCard(
            icon: Icons.download_outlined,
            iconColor: AppColors.accent,
            title: 'بازیابی (Import)',
            subtitle: 'از لیست پشتیبان‌های ذخیره‌شده انتخاب کن',
            child: _importing
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2)))
                : Column(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade400, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(child: Text(
                          'بازیابی اطلاعات فعلی رو پاک می‌کنه',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.folder_open_outlined,
                          color: Colors.white, size: 18),
                      label: const Text('انتخاب از پشتیبان‌ها',
                          style: TextStyle(color: Colors.white)),
                      onPressed: _showImportPicker,
                    ),
                  ]),
          ),
          const SizedBox(height: 24),

          // راهنما
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('راهنما', style: TextStyle(fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              for (final tip in [
                'بعد از خروجی گرفتن، فایل رو در گوگل درایو یا تلگرام ذخیره کن',
                'فایل‌های پشتیبان در حافظه گوشی ذخیره می‌شن و در همین صفحه نشون داده می‌شن',
                'اگر گوشی عوض کردی، فایل رو در گوشی جدید دریافت و بازیابی کن',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('• ', style: TextStyle(
                        color: Colors.amber, fontSize: 13)),
                    Expanded(child: Text(tip,
                        style: const TextStyle(fontSize: 12,
                            color: Colors.black87, height: 1.4))),
                  ]),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Widget child;
  const _ActionCard({required this.icon, required this.iconColor,
      required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withAlpha(18),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold,
              fontSize: 14)),
          Text(subtitle, style: const TextStyle(fontSize: 11,
              color: Colors.grey, height: 1.4)),
        ])),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}
