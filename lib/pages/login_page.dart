import 'package:facereq_mobile/pages/finger_page.dart';
import 'package:facereq_mobile/pages/register_face_page.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';
import '../core/auth_storage.dart';
import '../core/biometric_service.dart';
import 'home_page.dart';
import 'home_guru_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passController = TextEditingController();

  bool obscure = true;
  bool loading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    usernameController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (usernameController.text.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIP/NIS dan Password tidak boleh kosong')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // LOGIN
      await ApiService.login(
        usernameController.text.trim(),
        passController.text.trim(),
      );

      if (!mounted) return;

      // CEK STATUS WAJAH
      final face = await ApiService.faceStatus();
      final bool registered = face['registered'] == true;
      final bool verified = face['verified'] == true;

      if (!mounted) return;

      final user = await AuthStorage.getUser();
      final role = user?['role'];
      final bool hasBiometric = await BiometricService.canAuthenticate();

      if (!registered) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterFacePage()),
        );

        if (result == true && mounted) {
          if (hasBiometric) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FingerPage()),
            );
          } else {
            _goHome(role);
          }
        }
        return;
      }

      if (!verified && hasBiometric) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FingerPage()),
        );
        return;
      }

      _goHome(role);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _goHome(String? role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => role == 'guru' ? const HomeGuruPage() : const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
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
          children: [
            // DYNAMIC DECORATIVE BACKGROUND
            _floatingCircle(top: -50, left: -50, size: 200, delay: 0),
            _floatingCircle(bottom: 200, right: -100, size: 250, delay: 1),
            _floatingCircle(top: 150, left: -80, size: 150, delay: 2),

            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // BRANDING WITH GLOW
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                Hero(
                                  tag: 'logo',
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(35),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/logosmk.png',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SISTEM ABSENSI DIGITAL',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                AppConfig.schoolName.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // LOGIN CARD
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: TweenAnimationBuilder<Offset>(
                        tween: Tween(begin: const Offset(0, 0.1), end: Offset.zero),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutQuart,
                        builder: (context, offset, child) {
                          return Transform.translate(
                            offset: offset * MediaQuery.of(context).size.height,
                            child: Container(
                              constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height * 0.7,
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(32, 48, 32, 100),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 30,
                                    offset: Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                'Selamat datang kembali di sistem digital',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 40),

                              _input(
                                controller: usernameController,
                                label: 'NIP / NIS',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 24),
                              _input(
                                controller: passController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),

                              const SizedBox(height: 48),

                              // LOGIN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: loading ? null : handleLogin,
                                    child: loading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'MASUK KE SISTEM',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Center(
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Lupa password? Hubungi Admin IT',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppConfig.primaryColor, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _floatingCircle({double? top, double? bottom, double? left, double? right, required double size, int delay = 0}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: _FloatingWidget(
        size: size,
        delay: delay,
      ),
    );
  }
}

class _FloatingWidget extends StatefulWidget {
  final double size;
  final int delay;
  const _FloatingWidget({required this.size, required this.delay});

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4 + widget.delay),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut).value - 10),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
