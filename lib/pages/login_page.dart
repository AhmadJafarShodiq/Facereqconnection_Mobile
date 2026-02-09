import 'package:facereq_mobile/pages/finger_page.dart';
import 'package:facereq_mobile/pages/register_face_page.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/biometric_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passController = TextEditingController();

  bool obscure = true;
  bool loading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passController.dispose();
    super.dispose();
  }
Future<void> handleLogin() async {
  if (usernameController.text.isEmpty || passController.text.isEmpty) return;

  setState(() => loading = true);

  try {
    // 1️⃣ LOGIN
    await ApiService.login(
      usernameController.text.trim(),
      passController.text.trim(),
    );

    if (!mounted) return;

    // 2️⃣ CEK STATUS WAJAH (FINAL)
    final face = await ApiService.faceStatus();
    final bool registered = face['registered'] == true;
    final bool verified = face['verified'] == true;

    if (!mounted) return;

    // 3️⃣ FLOW SESUAI BACKEND
    if (!registered) {
      // ❌ BELUM DAFTAR WAJAH
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterFacePage()),
      );

      if (result == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FingerPage()),
        );
      }
      return;
    }

    if (!verified) {
      // ❌ SUDAH DAFTAR, BELUM VERIFY
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FingerPage()),
      );
      return;
    }

    // ✅ SUDAH VERIFIED
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B5ED7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 110),

              const SizedBox(height: 20),

              const Text(
                'Presensi Online SMKN 1\nTAMANAN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              // USERNAME
              TextField(
                controller: usernameController,
                keyboardType: TextInputType.text, // ⬅️ PAKSA TEXT
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // PASSWORD
              TextField(
                controller: passController,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => obscure = !obscure);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7D046),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: loading ? null : handleLogin,
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
