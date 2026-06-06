import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/coach.dart';
import '../../../data/repositories/app_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        children: [
          // Coach section
          _SectionTile(title: 'مربی فعال'),
          if (repo.activeCoach != null)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(repo.activeCoach!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'از ${JalaliHelper.formatDateLong(repo.activeCoach!.startDate)}',
              ),
              trailing: TextButton(
                onPressed: () => _changeCoach(context),
                child: const Text('تغییر'),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.grey),
              title: const Text('مربی تعریف نشده', style: TextStyle(color: Colors.grey)),
              trailing: ElevatedButton(
                onPressed: () => _addCoach(context),
                child: const Text('افزودن مربی'),
              ),
            ),

          const Divider(),

          // Coaches history
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF2E7D32)),
            title: const Text('تاریخچه مربیان'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showCoachHistory(context, repo),
          ),

          const Divider(),

          // Backup section
          _SectionTile(title: 'پشتیبان‌گیری'),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('تهیه بکاپ'),
            subtitle: const Text('صادرکردن تمام داده‌ها'),
            onTap: () => _exportBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text('بازگردانی بکاپ'),
            subtitle: const Text('هشدار: داده‌های فعلی جایگزین می‌شوند'),
            onTap: () => _importBackup(context),
          ),

          const Divider(),

          // About section
          _SectionTile(title: 'درباره اپ'),
          ListTile(
            leading: const Icon(Icons.sports_tennis, color: Color(0xFF2E7D32)),
            title: const Text('مدیریت تنیس'),
            subtitle: const Text('نسخه ۱.۰.۰'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(AppConstants.ownerName),
            subtitle: Text(AppConstants.ownerPhone),
          ),
        ],
      ),
    );
  }

  void _addCoach(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddCoachSheet(),
    );
  }

  void _changeCoach(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغییر مربی'),
        content: const Text(
            'با افزودن مربی جدید، مربی فعلی غیرفعال می‌شود. ادامه می‌دهید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addCoach(context);
            },
            child: const Text('بله، مربی جدید'),
          ),
        ],
      ),
    );
  }

  void _showCoachHistory(BuildContext context, AppRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, ctrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('تاریخچه مربیان',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: repo.coaches.length,
                itemBuilder: (c, i) {
                  final coach = repo.coaches[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          coach.isActive ? const Color(0xFF2E7D32) : Colors.grey,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(coach.name),
                    subtitle: Text(
                      coach.isActive
                          ? 'فعال از ${JalaliHelper.formatDateLong(coach.startDate)}'
                          : 'از ${JalaliHelper.formatDateLong(coach.startDate)} تا ${coach.endDate != null ? JalaliHelper.formatDateLong(coach.endDate!) : '...'}',
                    ),
                    trailing: coach.isActive
                        ? const Chip(
                            label: Text('فعال', style: TextStyle(fontSize: 12)),
                            backgroundColor: Color(0xFF2E7D32),
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final repo = context.read<AppRepository>();
      final data = await repo.exportBackup();
      final json = jsonEncode(data);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'tennis_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'بکاپ اپ تنیس');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هشدار'),
        content: const Text(
            'تمام داده‌های فعلی پاک شده و با فایل بکاپ جایگزین می‌شوند. مطمئنید؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('بله، بازگردانی کن'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;
      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      await context.read<AppRepository>().importBackup(data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('بازگردانی با موفقیت انجام شد'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بازگردانی: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _SectionTile extends StatelessWidget {
  final String title;

  const _SectionTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _AddCoachSheet extends StatefulWidget {
  const _AddCoachSheet();

  @override
  State<_AddCoachSheet> createState() => _AddCoachSheetState();
}

class _AddCoachSheetState extends State<_AddCoachSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final coach = Coach(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        startDate: DateTime.now(),
      );
      await context.read<AppRepository>().addCoach(coach);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('افزودن مربی جدید',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام مربی *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'نام الزامی است' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'شماره تماس',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ذخیره'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
