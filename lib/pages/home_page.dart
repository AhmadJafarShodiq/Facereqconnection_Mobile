// LOGIKA TIDAK DIUBAH — HANYA TAMPILAN + AUTO REFRESH
import 'dart:math';

import 'package:facereq_mobile/pages/home_guru_page.dart';
import 'package:facereq_mobile/pages/location_check_page.dart';
import 'package:flutter/material.dart';
import '../core/auth_storage.dart';
import '../core/api_service.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'register_face_page.dart';
import 'finger_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tabIndex = 1;

  Map<String, dynamic>? profile;
  Map<String, dynamic>? attendanceToday;
  List<Map<String, dynamic>> todaySubjects = [];
  bool _absenLocked = false;

  bool faceVerified = false;
  bool loading = true;
  final Set<int> _lockedSubjects = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;

      if (user['role'] == 'guru') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeGuruPage()),
        );
        return;
      }

      profile = user['profile'];

      await _checkFace();
      await _loadAttendance();
      final res = await ApiService.todaySchedule();
      todaySubjects = List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      todaySubjects = [];
    }

    if (mounted) setState(() => loading = false);
  }

Future<void> _checkFace() async {
  if (!mounted) return;

  try {
    final res = await ApiService.faceStatus();
    print('FACE STATUS: $res');

    final registered = res['registered'] == true;
    faceVerified = registered;

    if (mounted) setState(() {});
    await _openCamp(registered);
  } catch (e) {
    if (mounted) await _openCamp(false);
  }
}
Future<void> _openCamp(bool registered) async {
  if (!mounted) return;

  if (!registered) {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterFacePage()),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FingerPage()),
      );
    }
    return;
  }


}
 
  Future<void> _loadAttendance() async {
    try {
      attendanceToday = await ApiService.todayAttendance();
    } catch (_) {
      attendanceToday = null;
    }
  }

  Future<void> _reload() async {
    await _checkFace();
    await _loadAttendance();

    final res = await ApiService.todaySchedule();
    print("RELOAD RESPONSE: ${res['data']}"); // 🔥 TAMBAH INI

    todaySubjects = List<Map<String, dynamic>>.from(res['data'] ?? []);

    if (mounted) setState(() {});
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());

    switch (tabIndex) {
      case 0:
        return const ProfilePage();
      case 2:
        return const HistoryPage();
      default:
        return _dashboardSiswa();
    }
  }

  Widget _dashboardSiswa() {
    final name = profile?['nama_lengkap'] ?? '-';
    final nis = profile?['nip_nis'] ?? '-';
    final bool sudahAbsenMapel = todaySubjects.any(
      (e) => e['attended'] == true,
    );

    final belumAbsen = !sudahAbsenMapel;

    final checkIn = sudahAbsenMapel ? "Sudah Absen Mapel" : null;
    final late = false;
    final lateMin = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(name, nis, belumAbsen),
          const SizedBox(height: 20),
          _statusCard(belumAbsen, checkIn, late, lateMin),
          const SizedBox(height: 28),
          const Text(
            'Mapel Hari Ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          todaySubjects.isNotEmpty
              ? Column(children: todaySubjects.map(_subjectCard).toList())
              : _emptySubjectCard(),
        ],
      ),
    );
  }

  Widget _header(String name, String nis, bool belumAbsen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, color: Colors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'NIS: $nis',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: belumAbsen ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              belumAbsen ? 'Belum Absen' : 'Hadir',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(bool belumAbsen, String? checkIn, bool late, int lateMin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(
            belumAbsen ? Icons.warning : Icons.check_circle,
            size: 36,
            color: belumAbsen ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              belumAbsen
                  ? 'Kamu belum presensi hari ini'
                  : 'Masuk $checkIn${late ? ' • Terlambat $lateMin menit' : ''}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> subject) {
    final int scheduleId = subject['schedule_id'];

    final attended =
        subject['attended'] == true ||
        subject['already_attended'] == true ||
        subject['is_attended'] == true ||
        subject['attendance_id'] != null;

    final sessionOpen = subject['session_open'] == true;
    final isLocked = _lockedSubjects.contains(scheduleId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: attended ? Colors.green : Colors.orange,
            child: Icon(
              attended ? Icons.check : Icons.schedule,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject['name'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // ================== TOMBOL ==================
          // ================== AKSI / STATUS ==================
          if (attended)
            _statusChip(
              icon: Icons.check_circle,
              text: 'Sudah Absen',
              color: Colors.green,
            )
          else if (!sessionOpen)
            _statusChip(
              icon: Icons.lock,
              text: 'Mapel Belum Dibuka',
              color: Colors.red,
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text(
                'Absen Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLocked
                  ? null
                  : () async {
                      setState(() {
                        _lockedSubjects.add(scheduleId);
                      });

                      final ok = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPage(
                            role: 'siswa',
                            subjectId: scheduleId,
                            type: 'check_in',
                          ),
                        ),
                      );
                      print("ABSEN RESULT: $ok");
                      if (ok == true) {
                        await _reload();
                      }

                      if (mounted) {
                        setState(() {
                          _lockedSubjects.remove(scheduleId);
                        });
                      }
                    },
            ),
        ],
      ),
    );
  }

  Widget _emptySubjectCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: Text('Tidak ada jadwal hari ini')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(child: _body()),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _nav(Icons.person, 0),
          _nav(Icons.home, 1),
          _nav(Icons.history, 2),
        ],
      ),
    );
  }

 Widget _nav(IconData icon, int index) {
  final active = tabIndex == index;

  return InkWell(
    onTap: () async {
      if (tabIndex != index) {
        setState(() => tabIndex = index);

        // 🔥 AUTO REFRESH saat balik ke HOME
        if (index == 1) {
          await _reload();
        }
      }
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: active ? Colors.white : Colors.grey),
    ),
  );
}
}

Widget _statusChip({
  required IconData icon,
  required String text,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
