import 'package:flutter/material.dart';
import '../core/biometric_service.dart';
import 'home_page.dart';

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

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    // ❌ JANGAN pop / keluar
    // kalau gagal → tetap di halaman fingerprint
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B5ED7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 90, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Scan fingerprint untuk melanjutkan',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startAuth,
              child: const Text('Scan Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
