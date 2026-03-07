import 'package:flutter/material.dart';
import '../core/biometric_service.dart';
import '../core/auth_storage.dart';
import '../core/app_config.dart';
import 'home_page.dart';
import 'home_guru_page.dart';

class FingerPage extends StatefulWidget {
  const FingerPage({super.key});

  @override
  State<FingerPage> createState() => _FingerPageState();
}

class _FingerPageState extends State<FingerPage> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _startAuth();
  }

  Future<void> _startAuth() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    final ok = await BiometricService.authenticate();
    _isAuthenticating = false;

    if (!mounted || !ok) return;

    final user = await AuthStorage.getUser();
    final role = user?['role'];

    if (!mounted) return;

    if (role == 'guru') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeGuruPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'BIOMETRIC VERIFICATION',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan scan sidik jari Anda',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _startAuth,
                child: const Text('SCAN ULANG', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
