import 'package:flutter/material.dart';
import '../core/auth_storage.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';
import 'home_page.dart';
import 'home_guru_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _spinnerFade;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    // Logo scale dengan efek masuk dan sedikit bounce
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Teks fade in sedikit terlambat
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.6, curve: Curves.easeIn)),
    );

    // Spinner fade in setelah teks muncul
    _spinnerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // LOAD CACHED CONFIG
    await AppConfig.load();
    // FETCH LATEST CONFIG FROM NETWORK
    await ApiService.fetchSchoolSettings();

    // Pastikan animasi logo sudah sempat tampil (tunggu minimal 2 detik)
    // dan tunggu sampai controller animasi mendekati selesai
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)),
      _controller.forward().then((value) => null), // Tunggu sampai animasi selesai
    ]);

    final token = await AuthStorage.getToken();
    if (!mounted) return;

    if (token == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    try {
      await ApiService.profile();
      final user = await AuthStorage.getUser();
      final role = user?['role'];
      if (!mounted) return;
      
      Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => role == 'guru' ? const HomeGuruPage() : const HomePage())
      );
    } catch (e) {
      await AuthStorage.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
              primaryColor.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // DECORATIVE BACKGROUND PARTICLES
            _decorativeCircle(top: -100, left: -50, size: 300, opacity: 0.1),
            _decorativeCircle(bottom: -50, right: -50, size: 250, opacity: 0.08),
            _decorativeCircle(top: 200, right: -80, size: 150, opacity: 0.05),

            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO WITH RIPPLE EFFECT
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_controller.value > 0.3)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 1.8),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Container(
                                width: 100 * value,
                                height: 100 * value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity((1.8 - value).clamp(0.0, 0.4)),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                                    child: Image.asset(
                                      'assets/images/logosmk.png',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.contain,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // TEXT WITH CLEANER LOOK
                    Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SISTEM ABSENSI DIGITAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppConfig.schoolName.replaceFirst('SMK Negeri 1 ', 'SMK Negeri 1\n'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // LOADING SPINNER
                    Opacity(
                      opacity: _spinnerFade.value,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // COPYRIGHT TEXT AT BOTTOM
            Positioned(
              bottom: 40,
              child: Opacity(
                opacity: 0.5,
                child: const Text(
                  'DESIGNED FOR EXCELLENCE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle({double? top, double? bottom, double? left, double? right, required double size, required double opacity}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
