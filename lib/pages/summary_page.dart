import 'package:flutter/material.dart';

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
    final title = role == 'guru'
        ? (type == 'check_out'
              ? 'Absen Pulang Berhasil'
              : 'Absen Masuk Berhasil')
        : 'Absen Mapel Berhasil';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 96, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(name),
            Text('Similarity: ${similarity.toStringAsFixed(2)}%'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Kembali ke Home'),
            ),
          ],
        ),
      ),
    );
  }
}
