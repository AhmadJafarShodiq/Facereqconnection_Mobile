import 'package:facereq_mobile/pages/location_check_page.dart';
import 'package:facereq_mobile/pages/subject_detail_page.dart';
import 'package:flutter/material.dart';
import '../core/auth_storage.dart';
import '../core/api_service.dart';
import 'profile_page.dart';
import 'history_page.dart';
import '../core/app_config.dart';

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
  Map<int, List<Map<String, dynamic>>> presentStudentsMap = {};

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

    await _reloadData();

    if (mounted) setState(() => loading = false);
  }

  Future<void> _reloadData() async {
    await ApiService.fetchSchoolSettings(); // Refresh branding
    await _loadTeacherAttendance();
    await _loadTodaySubjects();
    
    // Refresh profile in case it changed
    final user = await AuthStorage.getUser();
    if (user != null && mounted) {
      setState(() {
        profile = user['profile'];
      });
    }
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
      
      // Fetch present students for open sessions
      for (var s in todaySubjects) {
        if (s['session_open'] == true) {
          final sid = (s['id'] as num).toInt();
          final cid = (s['class_id'] as num).toInt();
          try {
            final res = await ApiService.studentAttendanceBySubject(
              subjectId: sid,
              classId: cid,
            );
            presentStudentsMap[sid] = List<Map<String, dynamic>>.from(res['present'] ?? []);
          } catch (_) {}
        }
      }
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
    final fotoUrl = profile?['foto_url'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 26,
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
                        'Selamat Datang, Guru',
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
          ),

          const SizedBox(height: 24),

          // PRESENSI GURU CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: AppConfig.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Presensi Harian Guru',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConfig.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: checkedIn ? const Color(0xFFF1F5F9) : AppConfig.primaryColor,
                          foregroundColor: checkedIn ? const Color(0xFF94A3B8) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
                          checkedIn ? 'HADIR' : 'ABSEN MASUK',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (!checkedIn || checkedOut) ? const Color(0xFFF1F5F9) : Colors.red.shade600,
                          foregroundColor: (!checkedIn || checkedOut) ? const Color(0xFF94A3B8) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                        child: Text(
                          checkedOut ? 'PULANG' : 'ABSEN PULANG',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 20, color: AppConfig.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Jadwal Mengajar Hari Ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          todaySubjects.isEmpty
              ? _emptyCard()
              : Column(children: todaySubjects.map(_subjectCard).toList()),
        ],
      ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> subject) {
    final isOpen = subject['session_open'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectDetailPage(
                subject: subject,
                classId: (subject['class_id'] as num).toInt(),
              ),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOpen ? AppConfig.primaryColor.withOpacity(0.1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isOpen ? Icons.door_front_door_outlined : Icons.lock_clock_outlined,
            color: isOpen ? AppConfig.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          subject['name'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelas ${subject['kelas'] ?? '-'}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (isOpen) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: AppConfig.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${subject['present_count'] ?? 0} / ${subject['total_students'] ?? 0} Siswa Hadir',
                      style: TextStyle(
                        color: AppConfig.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (presentStudentsMap.containsKey((subject['id'] as num).toInt()) && presentStudentsMap[(subject['id'] as num).toInt()]!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: presentStudentsMap[(subject['id'] as num).toInt()]!.take(8).map((s) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 10, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                s['nama'] ?? '-',
                                style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList() + [
                        if (presentStudentsMap[(subject['id'] as num).toInt()]!.length > 8)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '+${presentStudentsMap[(subject['id'] as num).toInt()]!.length - 8} lainnya',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailPage(
                          subject: subject,
                          classId: (subject['class_id'] as num).toInt(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppConfig.primaryColor, AppConfig.primaryColor.withOpacity(0.9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.primaryColor.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "DATA KEHADIRAN",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (subject['remaining_seconds'] != null && (subject['remaining_seconds'] as num) > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Berakhir dalam ${_formatDuration((subject['remaining_seconds'] as num).toInt())}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isOpen ? Colors.red.shade600 : AppConfig.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: loadingSessionId == subject['id']
              ? null
              : () async {
                  final scheduleId = (subject['id'] as num).toInt();
                  setState(() => loadingSessionId = scheduleId);
                  if (isOpen) {
                    final sessionId = (subject['session_id'] as num).toInt();
                    await ApiService.closeSession(sessionId);
                  } else {
                    int? duration = await _showDurationPicker();
                    if (duration != null) {
                      await ApiService.openSession(scheduleId, duration: duration);
                    }
                  }
                  await _reloadData();
                  loadingSessionId = null;
                  if (mounted) setState(() {});
                },
          child: Text(
            isOpen ? 'TUTUP' : 'BUKA',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
          ),
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

  Future<int?> _showDurationPicker() async {
    int selected = 15;
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Waktu Absen', style: TextStyle(fontWeight: FontWeight.w900, color: AppConfig.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berapa menit sesi absen ini dibuka?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: selected,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: [15, 30, 45, 60, 90, 120].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value Menit'),
                );
              }).toList(),
              onChanged: (val) => selected = val ?? 15,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('BUKA SESI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada jadwal hari ini',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
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
          onRefresh: _reloadData,
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
        color: AppConfig.primaryColor, // Vibrant Indigo
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
          await _reloadData();
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
}
