import 'dart:typed_data';
import 'package:facereq_mobile/pages/summary_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:facereq_mobile/core/api_service.dart';
import 'package:facereq_mobile/core/app_config.dart';

class ConfirmFacePage extends StatefulWidget {
  final Uint8List photoBytes;
  final String name;
  final double similarity;
  final String role; // siswa | guru
  final int? subjectId;
  final String type; // check_in | check_out | subject

  const ConfirmFacePage({
    super.key,
    required this.photoBytes,
    required this.name,
    required this.similarity,
    required this.role,
    this.subjectId,
    required this.type,
  });

  @override
  State<ConfirmFacePage> createState() => _ConfirmFacePageState();
}

class _ConfirmFacePageState extends State<ConfirmFacePage> {
  bool _loading = false;

  // ======================
  // LOCATION
  // ======================
  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS tidak aktif');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

 Future<void> _submitAttendance() async {
  if (_loading) return;
  setState(() => _loading = true);

  try {
    final pos = await _getLocation();

    if (widget.role == 'siswa') {
      if (widget.subjectId == null) throw Exception('subjectId tidak boleh null!');
      await ApiService.studentCheckIn(
        scheduleId: widget.subjectId!,
        latitude: pos.latitude,
        longitude: pos.longitude,
        photoBytes: widget.photoBytes,
      );
    } else if (widget.role == 'guru') {
      if (widget.type == 'check_in') {
        await ApiService.teacherCheckIn(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } else {
        await ApiService.teacherCheckOut();
      }
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryPage(
          role: widget.role,
          type: widget.type,
          name: widget.name,
          similarity: widget.similarity * 100,
        ),
      ),
    );

    // Jangan pop CameraPage → biarkan tetap aktif untuk absen mapel berikutnya
    setState(() => _loading = false);

  } catch (e) {
    if (mounted) setState(() => _loading = false);
    // Bisa tambahkan snack bar error
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Gagal absen: $e')));
  }
}

 
  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    final timeText = DateFormat('HH:mm:ss • dd-MM-yyyy').format(DateTime.now());

    final buttonText = widget.role == 'guru'
        ? (widget.type == 'check_out' ? 'ABSEN PULANG' : 'ABSEN MASUK')
        : 'ABSEN SEKARANG';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const SizedBox.shrink(),
          title: Text('KONFIRMASI', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
          centerTitle: true,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VALIDASI WAJAH BERHASIL',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: primaryColor),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Image.memory(widget.photoBytes, fit: BoxFit.cover),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.name} • ${(widget.similarity * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Text(
                          timeText,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ULANGI SCAN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
