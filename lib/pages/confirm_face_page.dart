import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:facereq_mobile/core/api_service.dart';
import 'summary_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ConfirmFacePage extends StatefulWidget {
  final String photoPath;
  final String name;
  final double similarity;

  const ConfirmFacePage({
    super.key,
    required this.photoPath,
    required this.name,
    required this.similarity,
  });

  @override
  State<ConfirmFacePage> createState() => _ConfirmFacePageState();
}

class _ConfirmFacePageState extends State<ConfirmFacePage> {
  bool _loading = false;

  // ================= LOCATION =================
  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS tidak aktif');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan di pengaturan.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ================= ATTENDANCE =================
  Future<void> _handleAttendance({
    required bool isCheckIn,
  }) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final position = await _getLocation();

      // simpan foto ke storage aplikasi
      final dir = await getApplicationDocumentsDirectory();
      final savedPath =
          path.join(dir.path, path.basename(widget.photoPath));

      if (!File(savedPath).existsSync()) {
        await File(widget.photoPath).copy(savedPath);
      }

      final Uint8List photoBytes =
          await File(savedPath).readAsBytes();

      Map<String, dynamic> response;

      if (isCheckIn) {
        response = await ApiService.checkIn(
          latitude: position.latitude,
          longitude: position.longitude,
          photoBytes: photoBytes,
        );
      } else {
        response = await ApiService.checkOut();
      }

      if (!mounted) return;

      final now = DateTime.now();

      final summaryData = {
        'name': widget.name,
        'check_in_time': DateFormat('HH:mm').format(now),
        'date': DateFormat('dd MMM yyyy').format(now),
        'location': 'Sekolah',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'type': isCheckIn ? 'checkin' : 'checkout',
        'image_path': savedPath,
        'is_late': response['is_late'] == true,
        'late_minutes':
            int.tryParse(response['late_minutes']?.toString() ?? '0') ?? 0,
        'is_early': response['is_early'] == true,
        'early_minutes':
            int.tryParse(response['early_minutes']?.toString() ?? '0') ?? 0,
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryPage(data: summaryData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final timeText =
        DateFormat('HH:mm:ss • dd-MM-yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Konfirmasi'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 32,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Konfirmasi Foto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // FOTO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.photoPath),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.name}\n${(widget.similarity * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Text(
                            timeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CHECK-IN
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _handleAttendance(isCheckIn: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5D94C),
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : const Text(
                              'ABSEN MASUK',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // CHECK-OUT
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _handleAttendance(isCheckIn: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'ABSEN PULANG',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
