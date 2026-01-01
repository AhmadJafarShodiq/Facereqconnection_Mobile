import 'package:facereq_mobile/pages/history_page.dart';
import 'package:facereq_mobile/pages/profile_page.dart';
import 'package:facereq_mobile/widgets/attendance_status.dart';
import 'package:flutter/material.dart';
import 'camera_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../core/auth_storage.dart';
import '../core/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showWelcome = true;
  int tabIndex = 1;

  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;

  GoogleMapController? _mapController;
  final Location location = Location();
  Set<Marker> _markers = {};
  BitmapDescriptor? _profileIcon;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfileMarker();
    _checkAttendanceStatus();
  }

  // ================= USER =================
  Future<void> _loadUser() async {
    final data = await AuthStorage.getUser();
    if (!mounted || data == null) return;

    setState(() {
      user = data;
      profile = data['profile'];
    });
  }

  // ================= MARKER =================
  Future<void> _loadProfileMarker() async {
    _profileIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(100, 100)),
      'assets/images/profile.png',
    );
    _checkPermissionAndTrackLocation();
  }

  Future<void> _checkPermissionAndTrackLocation() async {
    final permission = await ph.Permission.location.request();
    if (!permission.isGranted) return;

    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) return;
    }

    location.onLocationChanged.listen((locData) {
      if (!mounted ||
          locData.latitude == null ||
          locData.longitude == null ||
          _mapController == null ||
          _profileIcon == null) return;

      final pos = LatLng(locData.latitude!, locData.longitude!);

      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('user_marker'),
            position: pos,
            icon: _profileIcon!,
            infoWindow: const InfoWindow(title: 'Posisi Saya'),
          ),
        };
      });

      _mapController!.animateCamera(
        CameraUpdate.newLatLng(pos),
      );
    });
  }

  // ================= ABSENSI =================
  Future<void> _checkAttendanceStatus() async {
    try {
      final history = await ApiService.getHistory();
      if (!mounted) return;

      if (history.isEmpty) {
        _showAttendancePopupCustom(
          AttendanceStatus.notCheckedIn,
          "Silakan lakukan absen masuk.",
        );
      } else {
        final last = history.last;
        if (last['type'] == 'checkin') {
          _showAttendancePopupCustom(
            AttendanceStatus.checkedIn,
            "Anda bisa absen pulang nanti.",
          );
        } else {
          _showAttendancePopupCustom(
            AttendanceStatus.checkedOut,
            "Terima kasih sudah melakukan absensi.",
          );
        }
      }
    } catch (_) {}
  }

  void _showAttendancePopupCustom(
      AttendanceStatus status, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) =>
          AttendancePopup(status: status, message: message),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CameraPage()),
          );
        },
        child: const Icon(Icons.camera_alt,
            color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _bottomBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _appBar(),
                Expanded(child: _map()),
              ],
            ),

            // ✅ FIX UTAMA — JANGAN CEK profile != null
            if (showWelcome) _welcomeCard(),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage:
                AssetImage('assets/images/profile.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['nama_lengkap'] ?? '-',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  profile?['nip_nis'] ?? '-',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _map() {
    return GoogleMap(
      onMapCreated: (c) => _mapController = c,
      initialCameraPosition: const CameraPosition(
        target: LatLng(-7.983908, 112.621391),
        zoom: 16,
      ),
      markers: _markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
    );
  }

  Widget _bottomBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bottomItem(Icons.person_outline, 'Profile', 0),
            const SizedBox(width: 56),
            _bottomItem(Icons.history, 'History', 2),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(
      IconData icon, String label, int index) {
    final active = tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => tabIndex = index);
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfilePage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HistoryPage()),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    active ? Colors.blue : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color:
                    active ? Colors.blue : Colors.grey,
                fontWeight: active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WELCOME =================
  Widget _welcomeCard() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selamat Datang',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 36,
                backgroundImage:
                    AssetImage('assets/images/profile.png'),
              ),
              const SizedBox(height: 12),
              Text(
                profile?['nama_lengkap'] ?? 'Memuat...',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                profile?['nip_nis'] ?? '',
                style:
                    const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                '${profile?['jabatan_kelas'] ?? ''}\n${profile?['instansi'] ?? ''}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    setState(() => showWelcome = false),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
