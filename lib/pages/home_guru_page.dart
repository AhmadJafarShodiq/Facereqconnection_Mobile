import 'package:facereq_mobile/pages/location_check_page.dart';
import 'package:facereq_mobile/pages/subject_detail_page';
import 'package:flutter/material.dart';
import '../core/auth_storage.dart';
import '../core/api_service.dart';
import 'profile_page.dart';
import 'history_page.dart';

class HomeGuruPage extends StatefulWidget {
  const HomeGuruPage({super.key});

  @override
  State<HomeGuruPage> createState() => _HomeGuruPageState();
}

class _HomeGuruPageState extends State<HomeGuruPage> {
  int tabIndex = 1;

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> todaySubjects = [];

  bool loading = true;

  bool checkedIn = false;
  bool checkedOut = false;

  int? loadingSessionId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await AuthStorage.getUser();
    if (!mounted || user == null) return;

    if (user['role'] != 'guru') {
      Navigator.pop(context);
      return;
    }

    profile = user['profile'];

    await _loadTeacherAttendance();
    await _loadTodaySubjects();

    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadTeacherAttendance() async {
    try {
      final res = await ApiService.todayAttendance();
      checkedIn =
          res['check_in'] != null && res['check_in'].toString().isNotEmpty;
      checkedOut =
          res['check_out'] != null && res['check_out'].toString().isNotEmpty;
    } catch (_) {
      checkedIn = false;
      checkedOut = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTodaySubjects() async {
    try {
      todaySubjects = await ApiService.guruTodaySchedule();
    } catch (_) {
      todaySubjects = [];
    }
    if (mounted) setState(() {});
  }

  Widget _body() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (tabIndex) {
      case 0:
        return const ProfilePage();
      case 2:
        return const HistoryPage();
      default:
        return _dashboardGuru();
    }
  }

  Widget _dashboardGuru() {
    final name = profile?['nama_lengkap'] ?? '-';
    final nip = profile?['nip_nis'] ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue),
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
                        'NIP: $nip',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PRESENSI
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presensi Guru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: checkedIn
                          ? null
                          : () async {
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationPage(
                                    role: 'guru',
                                    type: 'check_in',
                                  ),
                                ),
                              );
                              if (ok == true) {
                                setState(() => loading = true);
                                await _loadTeacherAttendance();
                                await _loadTodaySubjects();
                                setState(() => loading = false);
                              }
                            },
                      child: Text(
                        checkedIn ? 'Sudah Absen Masuk' : 'Absen Masuk',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: (!checkedIn || checkedOut)
                          ? null
                          : () async {
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationPage(
                                    role: 'guru',
                                    type: 'check_out',
                                  ),
                                ),
                              );
                              if (ok == true) {
                                await _loadTeacherAttendance();
                              }
                            },
                      child: Text(checkedOut ? 'Sudah Pulang' : 'Absen Pulang'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          const Text(
            'Jadwal Mengajar Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          todaySubjects.isEmpty
              ? _emptyCard()
              : Column(children: todaySubjects.map(_subjectCard).toList()),
        ],
      ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> subject) {
    final isOpen = subject['session_open'] == true;

    return InkWell(
      onTap: isOpen
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectDetailPage(
                    subject: subject,
                    classId: subject['class_id'],
                  ),
                ),
              );
            }
          : null,
      child: Container(
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
              backgroundColor: isOpen ? Colors.blue : Colors.orange,
              child: Icon(
                isOpen ? Icons.check_circle : Icons.schedule,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelas ${subject['kelas'] ?? '-'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOpen ? Colors.red : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: loadingSessionId == subject['id']
                  ? null
                  : () async {
                      setState(() => loadingSessionId = subject['id']);
                      if (isOpen) {
                        await ApiService.closeSession(subject['session_id']);
                      } else {
                        await ApiService.openSession(subject['id']);
                      }
                      await _loadTodaySubjects();
                      loadingSessionId = null;
                      if (mounted) setState(() {});
                    },
              child: Text(isOpen ? 'Tutup' : 'Buka'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: Text('Tidak ada jadwal mengajar hari ini')),
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
      onTap: () => setState(() => tabIndex = index),
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
