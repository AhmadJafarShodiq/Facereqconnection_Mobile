import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';

/// ===============================
/// PAGE
/// ===============================
class SubjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> subject;
  final int classId;

  const SubjectDetailPage({
    super.key,
    required this.subject,
    required this.classId,
  });

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

/// ===============================
/// STATE
/// ===============================
class _SubjectDetailPageState extends State<SubjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<Map<String, dynamic>> missing = [];
  List<Map<String, dynamic>> present = [];

  bool loading = true;

  int get subjectId {
    final raw = widget.subject['id'] ?? widget.subject['subject_id'] ?? 0;
    return (raw as num).toInt();
  }

  int get classId => (widget.classId as num).toInt();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  /// ===============================
  /// LOAD DATA
  /// ===============================
  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final res = await ApiService.studentAttendanceBySubject(
        subjectId: subjectId,
        classId: classId,
      );

      present = List<Map<String, dynamic>>.from(res['present'] ?? []);
      missing = List<Map<String, dynamic>>.from(res['missing'] ?? []);
    } catch (e) {
      present = [];
      missing = [];
    }

    if (mounted) setState(() => loading = false);
  }

  /// ===============================
  /// PERCENT
  /// ===============================
  double get percent {
    final total = present.length + missing.length;
    if (total == 0) return 0;
    return (present.length / total) * 100;
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              (widget.subject['name'] ?? 'DETAIL MAPEL').toUpperCase(),
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
            Text(
              'Detail Kehadiran Siswa',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: primaryColor,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'BELUM ABSEN'),
            Tab(text: 'SUDAH ABSEN'),
          ],
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: primaryColor,
              child: Column(
                children: [
                  _statsHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _list(missing, 'Semua siswa sudah absen ✨'),
                        _list(present, 'Belum ada siswa yang absen'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ===============================
  /// HEADER STATISTIK
  /// ===============================
  Widget _statsHeader() {
    final primaryColor = AppConfig.primaryColor;
    final total = present.length + missing.length;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AKTIVITAS KELAS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryColor, letterSpacing: 1.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('HADIR', present.length, Colors.green.shade600),
              _miniStat('BELUM', missing.length, Colors.red.shade600),
              _miniStat('TOTAL', total, primaryColor),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 12,
                width: (MediaQuery.of(context).size.width - 96) * (percent / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// MINI STAT
  /// ===============================
  Widget _miniStat(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
        ),
      ],
    );
  }

  /// ===============================
  /// LIST SISWA
  /// ===============================
  Widget _list(List<Map<String, dynamic>> data, String empty) {
    final primaryColor = AppConfig.primaryColor;
    if (data.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text(empty, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final s = data[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person_outline, color: primaryColor, size: 20),
            ),
            title: Text(
              s['nama'] ?? s['nama_lengkap'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            subtitle: Text(
              s['nis']?.toString() ?? s['nip_nis']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(_tab.index == 1 ? Icons.check_circle_rounded : Icons.pending_outlined, 
              color: _tab.index == 1 ? Colors.green : Colors.orange, size: 20),
          ),
        );
      },
    );
  }
}
