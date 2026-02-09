import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:math';
import 'camera_page.dart';
import '../core/api_service.dart';

class LocationPage extends StatefulWidget {
  final String role;
  final int? subjectId;
  final String type;

  const LocationPage({
    super.key,
    required this.role,
    required this.type,
    this.subjectId,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  bool readyToCamera = false;

  double? schoolLat;
  double? schoolLng;
  double schoolRadius = 100;
  double? distanceMeter;

  late AnimationController _radarController;

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color softBlue = Color(0xFF42A5F5);
  static const Color darkText = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _radarController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _checkLocation();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    try {
      setState(() {
        loading = true;
        readyToCamera = false;
      });

      final schoolData = await ApiService.school();
      schoolLat = double.parse(schoolData['latitude'].toString());
      schoolLng = double.parse(schoolData['longitude'].toString());
      schoolRadius =
          double.tryParse(schoolData['radius'].toString()) ?? 100;

      final location = Location();
      if (!await location.serviceEnabled()) {
        if (!await location.requestService()) return;
      }
      if (await location.hasPermission() == PermissionStatus.denied) {
        if (await location.requestPermission() != PermissionStatus.granted) {
          return;
        }
      }

      final loc = await location.getLocation();

      distanceMeter = _calculateDistance(
        loc.latitude!,
        loc.longitude!,
        schoolLat!,
        schoolLng!,
      );

      setState(() {
        loading = false;
        readyToCamera = distanceMeter! <= schoolRadius;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  void _goToCamera() async {
    // 👉 jeda halus sebelum camera
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
final ok = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CameraPage(
      role: widget.role,
      type: widget.type,
      subjectId: widget.subjectId,
    ),
  ),
);
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    final isInside =
        distanceMeter != null && distanceMeter! <= schoolRadius;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F6FA), Color(0xFFE9ECF3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: loading
                ? const CircularProgressIndicator()
                : Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Validasi Lokasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 18),

                          /// RADAR
                          SizedBox(
                            width: 230,
                            height: 230,
                            child: AnimatedBuilder(
                              animation: _radarController,
                              builder: (_, __) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _radarCircle(),
                                    _radarCircle(scale: 0.7),
                                    _radarCircle(scale: 0.4),
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primaryBlue,
                                      ),
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            '${distanceMeter?.toStringAsFixed(1) ?? '-'} meter',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isInside
                                  ? 'Lokasi valid, siap absensi'
                                  : 'Di luar area sekolah',
                              style: const TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          if (readyToCamera)
                            ElevatedButton(
                              onPressed: _goToCamera,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Lanjut ke Kamera'),
                            )
                          else
                            ElevatedButton(
                              onPressed: _checkLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _radarCircle({double scale = 1}) {
    return Transform.scale(
      scale: scale + _radarController.value,
      child: Opacity(
        opacity: (1 - _radarController.value).clamp(0.0, 1.0),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: softBlue.withOpacity(0.45),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
