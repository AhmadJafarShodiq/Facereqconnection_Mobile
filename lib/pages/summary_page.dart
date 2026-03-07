import 'package:facereq_mobile/pages/home_guru_page.dart';
import 'package:facereq_mobile/pages/home_page.dart';
import 'package:flutter/material.dart';
import '../core/app_config.dart';

class SummaryPage extends StatelessWidget {
  final String role;
  final String type;
  final String name;
  final double similarity;

  const SummaryPage({
    super.key,
    required this.role,
    required this.type,
    required this.name,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    final title = role == 'guru'
        ? (type == 'check_out'
              ? 'ABSEN PULANG BERHASIL'
              : 'ABSEN MASUK BERHASIL')
        : 'ABSEN MAPEL BERHASIL';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 100, color: Colors.green),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                name.toUpperCase(),
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                'Tingkat Kecocokan: ${similarity.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => role == 'guru'
                            ? const HomeGuruPage()
                            : const HomePage(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('KEMBALI KE BERANDA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
