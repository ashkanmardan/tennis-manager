import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/app_repository.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final allStudents = repo.students;

    final activeStudents = allStudents
        .where((s) => s.isActive && s.name.contains(_searchQuery))
        .toList();
    final inactiveStudents = allStudents
        .where((s) => !s.isActive && s.name.contains(_searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('شاگردان'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'فعال (${activeStudents.length})'),
            Tab(text: 'غیرفعال (${inactiveStudents.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'جستجوی شاگرد...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _StudentList(students: activeStudents),
                _StudentList(students: inactiveStudents),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('شاگرد جدید'),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddStudentSheet(),
    );
  }
}

class _StudentList extends StatelessWidget {
  final List<Student> students;

  const _StudentList({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('شاگردی یافت نشد', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: students.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, i) {
        final student = students[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                student.name.substring(0, 1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              student.feeType == AppConstants.feeTypeMonthly
                  ? '${JalaliHelper.formatAmount(student.feeAmount)} تومان/ماه'
                  : '${JalaliHelper.formatAmount(student.feeAmount)} تومان/جلسه',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: student.phone != null
                ? Text(student.phone!, style: const TextStyle(fontSize: 12, color: Colors.grey))
                : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentDetailScreen(student: student),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddStudentSheet extends StatefulWidget {
  const _AddStudentSheet();

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _feeAmountCtrl = TextEditingController();
  String _feeType = AppConstants.feeTypeMonthly;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _feeAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final student = Student(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        feeType: _feeType,
        feeAmount: int.parse(_feeAmountCtrl.text.replaceAll(',', '')),
        createdAt: DateTime.now(),
      );
      await context.read<AppRepository>().addStudent(student);
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
            Row(
              children: [
                const Text('افزودن شاگرد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام و نام‌خانوادگی *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'نام الزامی است' : null,
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
            const SizedBox(height: 12),
            const Text('نوع شهریه', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: AppConstants.feeTypeMonthly,
                    groupValue: _feeType,
                    onChanged: (v) => setState(() => _feeType = v!),
                    title: const Text('ماهانه'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: AppConstants.feeTypeSession,
                    groupValue: _feeType,
                    onChanged: (v) => setState(() => _feeType = v!),
                    title: const Text('جلسه‌ای'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _feeAmountCtrl,
              decoration: InputDecoration(
                labelText: _feeType == AppConstants.feeTypeMonthly
                    ? 'مبلغ ماهانه (تومان) *'
                    : 'مبلغ هر جلسه (تومان) *',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مبلغ الزامی است';
                if (int.tryParse(v.replaceAll(',', '')) == null) return 'عدد وارد کنید';
                return null;
              },
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
