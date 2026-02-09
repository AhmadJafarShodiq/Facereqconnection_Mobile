import 'dart:typed_data';
import 'package:facereq_mobile/pages/summary_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:facereq_mobile/core/api_service.dart';

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
    final timeText = DateFormat('HH:mm:ss • dd-MM-yyyy').format(DateTime.now());

    final buttonText = widget.role == 'guru'
        ? (widget.type == 'check_out' ? 'ABSEN PULANG' : 'ABSEN MASUK')
        : 'ABSEN MAPEL';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: const SizedBox.shrink(),
          title: const Text('Konfirmasi'),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Konfirmasi Foto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.memory(widget.photoBytes),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            color: Colors.black54,
                            child: Text(
                              '${widget.name}\n${(widget.similarity * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5D94C),
                        foregroundColor: Colors.black,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
