import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/player.dart';
import '../../../data/repositories/app_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final player = repo.player;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('مربی', style: TextStyle(color: Colors.white)),
        actions: [
          if (player != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => _showEditSheet(context, repo, player),
            ),
        ],
      ),
      body: player == null
          ? const _EmptyState()
          : _ProfileBody(player: player, repo: repo),
    );
  }

  void _showEditSheet(BuildContext context, AppRepository repo, Player player) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(repo: repo, player: player),
    );
  }
}

// ── Profile Body ──────────────────────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  final Player player;
  final AppRepository repo;
  const _ProfileBody({required this.player, required this.repo});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // avatar
        Center(child: Column(children: [
          Container(
            width: 84, height: 84,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              player.name.isNotEmpty ? player.name.substring(0, 1) : '؟',
              style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(player.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (player.phone != null) ...[
            const SizedBox(height: 4),
            Text(player.phone!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ])),
        const SizedBox(height: 24),

        _Section(title: 'اطلاعات تمرین', children: [
          _InfoRow(Icons.person_outline, 'مربی', player.coachName),
          if (player.clubName != null && player.clubName!.isNotEmpty)
            _InfoRow(Icons.sports_tennis, 'باشگاه', player.clubName!),
          _InfoRow(Icons.schedule_outlined, 'ساعت تمرین', player.trainingTime),
          _InfoRow(Icons.timer_outlined, 'مدت جلسه', '${player.sessionDuration} دقیقه'),
          _InfoRow(Icons.calendar_today_outlined, 'روزهای تمرین', player.trainingDaysLabel),
        ]),
        const SizedBox(height: 14),

        // اطلاعات تماس مربی
        if (player.coachPhone != null || player.coachInstagram != null || player.coachCardNumber != null)
          _Section(title: 'تماس با مربی', children: [
            if (player.coachPhone != null)
              _TapRow(
                icon: Icons.phone_outlined,
                label: 'تلفن مربی',
                value: player.coachPhone!,
                color: AppColors.accent,
                onTap: (_) => _launchUrl('tel:${player.coachPhone}'),
                trailingIcon: Icons.call,
              ),
            if (player.coachInstagram != null)
              _TapRow(
                icon: Icons.camera_alt_outlined,
                label: 'اینستاگرام',
                value: '@${player.coachInstagram!.replaceAll('@', '')}',
                color: const Color(0xFFE91E8C),
                onTap: (_) {
                  final handle = player.coachInstagram!.replaceAll('@', '');
                  _launchUrl('instagram://user?username=$handle').catchError((_) =>
                      _launchUrl('https://instagram.com/$handle'));
                },
                trailingIcon: Icons.open_in_new,
              ),
            if (player.coachCardNumber != null)
              _TapRow(
                icon: Icons.credit_card_outlined,
                label: 'شماره کارت',
                value: player.coachCardNumber!,
                color: AppColors.primary,
                onTap: (ctx) {
                  Clipboard.setData(ClipboardData(text: player.coachCardNumber!));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('شماره کارت کپی شد'),
                        duration: Duration(seconds: 2)));
                },
                trailingIcon: Icons.copy,
              ),
          ]),
        if (player.birthDate != null && player.birthDate!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Section(title: 'اطلاعات شخصی', children: [
            _InfoRow(Icons.cake_outlined, 'تاریخ تولد', player.birthDate!),
          ]),
        ],
      ],
    );
  }

  

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
        ]),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
    ]),
  );
}

class _TapRow extends StatelessWidget {
  final IconData icon, trailingIcon;
  final String label, value;
  final Color color;
  final void Function(BuildContext) onTap;
  const _TapRow({required this.icon, required this.label, required this.value,
      required this.color, required this.onTap, required this.trailingIcon});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onTap(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
        const SizedBox(width: 8),
        Icon(trailingIcon, size: 16, color: color),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.person_outline, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      const Text('اطلاعات پروفایل موجود نیست', style: TextStyle(color: Colors.grey)),
    ]),
  );
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final AppRepository repo;
  final Player player;
  const _EditProfileSheet({required this.repo, required this.player});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl, _phoneCtrl, _coachCtrl,
      _clubCtrl, _timeCtrl, _coachPhoneCtrl, _instagramCtrl, _cardCtrl;
  late int _duration;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameCtrl       = TextEditingController(text: p.name);
    _phoneCtrl      = TextEditingController(text: p.phone ?? '');
    _coachCtrl      = TextEditingController(text: p.coachName);
    _clubCtrl       = TextEditingController(text: p.clubName ?? '');
    _timeCtrl       = TextEditingController(text: p.trainingTime);
    _coachPhoneCtrl = TextEditingController(text: p.coachPhone ?? '');
    _instagramCtrl  = TextEditingController(text: p.coachInstagram ?? '');
    _cardCtrl       = TextEditingController(text: p.coachCardNumber ?? '');
    _duration       = p.sessionDuration;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _coachCtrl, _clubCtrl,
        _timeCtrl, _coachPhoneCtrl, _instagramCtrl, _cardCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.savePlayer(widget.player.copyWith(
        name:            _nameCtrl.text.trim(),
        phone:           _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        coachName:       _coachCtrl.text.trim(),
        clubName:        _clubCtrl.text.trim().isEmpty ? null : _clubCtrl.text.trim(),
        trainingTime:    _timeCtrl.text.trim(),
        sessionDuration: _duration,
        coachPhone:      _coachPhoneCtrl.text.trim().isEmpty ? null : _coachPhoneCtrl.text.trim(),
        coachInstagram:  _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
        coachCardNumber: _cardCtrl.text.trim().isEmpty ? null : _cardCtrl.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8, left: 16, right: 16),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const Text('ویرایش پروفایل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _field(_nameCtrl, 'نام', Icons.person_outline),
        const SizedBox(height: 10),
        _field(_phoneCtrl, 'شماره تلفن', Icons.phone_outlined, inputType: TextInputType.phone),
        const SizedBox(height: 10),
        _field(_coachCtrl, 'نام مربی', Icons.sports),
        const SizedBox(height: 10),
        _field(_coachPhoneCtrl, 'تلفن مربی', Icons.phone_in_talk_outlined, inputType: TextInputType.phone),
        const SizedBox(height: 10),
        _field(_instagramCtrl, 'اینستاگرام مربی', Icons.camera_alt_outlined),
        const SizedBox(height: 10),
        _field(_cardCtrl, 'شماره کارت مربی', Icons.credit_card_outlined, inputType: TextInputType.number),
        const SizedBox(height: 10),
        _field(_clubCtrl, 'نام باشگاه', Icons.sports_tennis),
        const SizedBox(height: 10),
        _field(_timeCtrl, 'ساعت تمرین (HH:MM)', Icons.access_time_outlined),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.timer_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Text('مدت جلسه:', style: TextStyle(fontSize: 15)),
          const Spacer(),
          DropdownButton<int>(
            value: _duration,
            underline: const SizedBox(),
            items: [30, 45, 60, 90, 120]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v دقیقه')))
                .toList(),
            onChanged: (v) => setState(() => _duration = v!),
          ),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ذخیره تغییرات', style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? inputType}) =>
      TextField(
        controller: ctrl, keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          filled: true, fillColor: const Color(0xFFF5F5F5),
        ),
      );
}
