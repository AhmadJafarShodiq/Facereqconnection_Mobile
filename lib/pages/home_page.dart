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
import '../core/app_config.dart';

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

  Future<void> _init({bool refreshOnly = false}) async {
    if (!refreshOnly) setState(() => loading = true);
    
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
      await _loadSchedule();
    } catch (_) {
      todaySubjects = [];
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadSchedule() async {
    try {
      final res = await ApiService.todaySchedule();
      todaySubjects = List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      todaySubjects = [];
    }
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
    await ApiService.fetchSchoolSettings(); // Refresh branding
    await _checkFace();
    await _loadAttendance();
    await _loadSchedule();
    
    // Refresh local profile as well
    final user = await AuthStorage.getUser();
    if (user != null && mounted) {
      setState(() {
        profile = user['profile'];
      });
    }
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
    final fotoUrl = profile?['foto_url'];

    final bool hasUrgentSession = todaySubjects.any((s) =>
        s['session_open'] == true &&
        s['attended'] == false &&
        s['remaining_seconds'] != null &&
        (s['remaining_seconds'] as num) > 0 &&
        (s['remaining_seconds'] as num) < 300);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(name, nis, belumAbsen, fotoUrl),
          const SizedBox(height: 24),
          if (hasUrgentSession) ...[
            _urgentNotification(),
            const SizedBox(height: 16),
          ],
          _statusCard(belumAbsen),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_month, size: 20, color: AppConfig.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Jadwal Hari Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          todaySubjects.isNotEmpty
              ? Column(children: todaySubjects.map(_subjectCard).toList())
              : _emptySubjectCard(),
        ],
      ),
    );
  }

  Widget _header(String name, String nis, bool belumAbsen, String? fotoUrl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.primaryColor, AppConfig.primaryColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConfig.primaryColor,
                  backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                  child: (fotoUrl == null || fotoUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID SISWA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(nis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    belumAbsen ? 'BELUM ABSEN' : 'HADIR',
                    style: TextStyle(
                      color: AppConfig.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgentNotification() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEGERA ABSEN!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  'Waktu absen hampir habis (< 5 menit)',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(bool belumAbsen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: belumAbsen ? Colors.orange.withOpacity(0.1) : AppConfig.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              belumAbsen ? Icons.info_outline : Icons.verified,
              color: belumAbsen ? Colors.orange : AppConfig.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  belumAbsen ? 'Status Presensi' : 'Terverifikasi',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppConfig.primaryColor),
                ),
                Text(
                  belumAbsen
                      ? 'Lakukan presensi pada jadwal aktif'
                      : 'Presensi anda telah tercatat sistem',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: attended ? Colors.green.withOpacity(0.1) : AppConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  attended ? Icons.check_circle_outline : Icons.book_outlined,
                  color: attended ? Colors.green : AppConfig.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'Pukul ${subject['jam_mulai'] ?? '--:--'} - ${subject['jam_selesai'] ?? '--:--'}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (sessionOpen && subject['remaining_seconds'] != null && (subject['remaining_seconds'] as num) > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ((subject['remaining_seconds'] as num) < 300) ? Colors.red.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: ((subject['remaining_seconds'] as num) < 300) ? Colors.red : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sisa Waktu: ${_formatDuration((subject['remaining_seconds'] as num).toInt())}',
                              style: TextStyle(
                                color: ((subject['remaining_seconds'] as num) < 300) ? Colors.red : Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (attended)
                _statusChip(
                  icon: Icons.verified_rounded,
                  text: 'Sudah Presensi',
                  color: Colors.green,
                )
              else if (!sessionOpen)
                _statusChip(
                  icon: Icons.lock_clock_outlined,
                  text: 'Belum Dibuka',
                  color: Colors.red,
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text(
                      'PRESENSI SEKARANG',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLocked ? Colors.grey : AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                            if (ok == true) await _reload();

                            if (mounted) {
                              setState(() {
                                _lockedSubjects.remove(scheduleId);
                              });
                            }
                          },
                  ),
                ),
            ],
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: const Center(
        child: Text(
          'Tidak ada jadwal hari ini',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppConfig.primaryColor,
          onRefresh: _reload,
          child: _body(),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        color: AppConfig.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _nav(Icons.person_outline, 0),
          _nav(Icons.dashboard_outlined, 1),
          _nav(Icons.history_outlined, 2),
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
          await _reload(); // Refresh data on every tab switch for real-time feel
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.white54,
          size: active ? 26 : 22,
        ),
      ),
    );
  }
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
}


