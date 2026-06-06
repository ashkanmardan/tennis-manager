import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/session.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/app_repository.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Map<int, bool> _attendance = {};
  List<Student> _students = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<AppRepository>();
    final students = repo.activeStudents;
    final savedAttendance = await repo.getAttendanceForSession(widget.session.id!);

    // Initialize all students as present by default
    final attendanceMap = <int, bool>{};
    for (final s in students) {
      attendanceMap[s.id!] = true;
    }
    // Override with saved data
    for (final a in savedAttendance) {
      attendanceMap[a.studentId] = a.present;
    }

    if (mounted) {
      setState(() {
        _students = students;
        _attendance = attendanceMap;
        _loading = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    try {
      await context.read<AppRepository>().saveAttendance(
            widget.session.id!,
            _attendance,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حضور و غیاب ذخیره شد'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    Color statusColor;
    String statusLabel;
    if (session.coachCancelled) {
      statusColor = Colors.red;
      statusLabel = 'لغو شده توسط مربی';
    } else if (session.isMakeup) {
      statusColor = Colors.orange;
      statusLabel = 'جلسه جبرانی';
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'جلسه عادی';
    }

    final presentCount = _attendance.values.where((v) => v).length;
    final absentCount = _attendance.values.where((v) => !v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(JalaliHelper.formatDateLong(session.date)),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _saveAttendance,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ذخیره', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Session info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: statusColor.withOpacity(0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          if (session.venue != null)
                            Text('📍 ${session.venue}',
                                style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _AttendanceStat(
                              label: 'حاضر', value: presentCount, color: Colors.green),
                          _AttendanceStat(
                              label: 'غایب', value: absentCount, color: Colors.red),
                          _AttendanceStat(
                              label: 'کل', value: _students.length, color: Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),

                // Attendance list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text('حضور و غیاب',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          for (final id in _attendance.keys) {
                            _attendance[id] = true;
                          }
                        }),
                        child: const Text('همه حاضر'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Text('شاگردی ثبت نشده', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _students.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (ctx, i) {
                            final student = _students[i];
                            final isPresent = _attendance[student.id!] ?? true;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPresent
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  child: Text(
                                    student.name.substring(0, 1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPresent ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                                title: Text(student.name),
                                trailing: Switch(
                                  value: isPresent,
                                  activeColor: Colors.green,
                                  inactiveTrackColor: Colors.red.shade100,
                                  onChanged: (v) =>
                                      setState(() => _attendance[student.id!] = v),
                                ),
                                onTap: () =>
                                    setState(() => _attendance[student.id!] = !isPresent),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          JalaliHelper.toPersianDigits(value.toString()),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
