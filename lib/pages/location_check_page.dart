import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:math';
import 'camera_page.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';

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

  static const Color darkText = Color(0xFF1E293B);

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
if (ok == true && mounted) {
  Navigator.pop(context, true);
}
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
    final isInside = distanceMeter != null && distanceMeter! <= schoolRadius;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppConfig.primaryColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Validasi Lokasi',
          style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // RADAR BOX
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppConfig.primaryColor.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (_, __) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _radarCircle(),
                              _radarCircle(scale: 0.6),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppConfig.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConfig.primaryColor.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.my_location, color: Colors.white, size: 24),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (loading)
                      const Text('Mendeteksi lokasi...', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))
                    else ...[
                      Text(
                        '${distanceMeter?.toStringAsFixed(1) ?? '-'} meter',
                        style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isInside ? 'Kamu ada di area sekolah' : 'Kamu terlalu jauh dari sekolah',
                        style: TextStyle(
                          color: isInside ? Colors.green.shade700 : Colors.red.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 48),

              if (!loading)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isInside ? _goToCamera : _checkLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInside ? AppConfig.primaryColor : Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      isInside ? 'LANJUT KE KAMERA' : 'COBA LAGI',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              const Text(
                'Pastikan GPS aktif dan akurat sebelum absen',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
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
              color: AppConfig.primaryColor.withOpacity(0.45),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
