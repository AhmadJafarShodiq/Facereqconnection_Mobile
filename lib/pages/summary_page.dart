import 'dart:io';
import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const SummaryPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String time = data['check_in_time'] ?? '-';
    final String late = data['late_minutes'] != null
        ? '${data['late_minutes']} menit'
        : '0 menit';
    final String location = data['location'] ?? '-';
    final double? lat = data['latitude'];
    final double? lng = data['longitude'];
    final String? imagePath = data['image_path']; // ⬅️ FOTO DARI ABSEN

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('summary page', style: TextStyle(fontSize: 15)),
        actions: const [Icon(Icons.more_horiz), SizedBox(width: 12)],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // FOTO
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: (imagePath != null && File(imagePath).existsSync())
                          ? AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 80),
                            ),
                    ),
                  ),

                  _title('Jam Kehadiran'),
                  _value('$time WIB'),

                  const SizedBox(height: 10),

                  _title('Waktu Terlambat'),
                  _value(late),

                  const SizedBox(height: 10),

                  _title('Lokasi'),
                  _value(location),

                  const SizedBox(height: 10),

                  _title('Koordinat Posisi'),
                  _value(
                    lat != null && lng != null
                        ? 'Longitude : $lng\nLatitude : $lat'
                        : '-',
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ======================
          // BOTTOM BAR
          // ======================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              color: Colors.blue,
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================
  // HELPER
  // ======================
  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _value(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
