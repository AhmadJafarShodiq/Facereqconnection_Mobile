import 'package:flutter/material.dart';
import '../core/biometric_service.dart';
import '../core/auth_storage.dart';
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
