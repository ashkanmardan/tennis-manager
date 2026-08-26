import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CopyrightScreen extends StatefulWidget {
  final VoidCallback onStart;
  const CopyrightScreen({super.key, required this.onStart});

  @override
  State<CopyrightScreen> createState() => _CopyrightScreenState();
}

class _CopyrightScreenState extends State<CopyrightScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // آیکون اپ
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                    ),
                    child: const Center(
                      child: Text('🎾', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // نام برنامه
              FadeTransition(
                opacity: _fade,
                child: const Column(children: [
                  Text('دستیار تنیس',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold,
                          color: Colors.white, letterSpacing: 1)),
                  SizedBox(height: 6),
                  Text('Tennis Assistant',
                      style: TextStyle(fontSize: 14, color: Colors.white60,
                          letterSpacing: 2)),
                ]),
              ),

              const Spacer(flex: 2),

              // متن copyright
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                      ),
                      child: const Column(children: [
                        Text('این برنامه یک دستیار حسابرسی شخصی برای بازیکنان تنیس جهت محاسبه کلاسهای تنیس و یا خرج و مخارج جانبی آن میباشد.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
                        SizedBox(height: 10),
                        Divider(color: Colors.white24, height: 1),
                        SizedBox(height: 10),
                        Text('طراح و توسعه‌دهنده',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                        SizedBox(height: 6),
                        Text('اشکان مردان‌پور',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.phone_outlined, color: Colors.white54, size: 13),
                          SizedBox(width: 4),
                          Text('09182777765', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ]),
                        SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 13),
                          SizedBox(width: 4),
                          Text('Ashkan.Mardanpour', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ]),
                        SizedBox(height: 6),
                        Text('نسخه ۱.۰.۰',
                            style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ]),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 40),

              // دکمه شروع
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('شروع کنید', style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_back, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
