import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';
import 'presensi_gate_page.dart';

class SubjectSelectPage extends StatefulWidget {
  final String role;

  const SubjectSelectPage({super.key, required this.role});

  @override
  State<SubjectSelectPage> createState() => _SubjectSelectPageState();
}

class _SubjectSelectPageState extends State<SubjectSelectPage> {
  bool loading = true;

  // ✅ TYPE SAFE (WAJIB)
  List<Map<String, dynamic>> schedules = [];

  final List<Color> colors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
  try {
    schedules = widget.role == 'guru'
    ? await ApiService.guruTodaySchedule()
    : await ApiService.studentTodaySchedule();
  } catch (_) {
    schedules = [];
  }

  if (mounted) setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('JADWAL HARI INI', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadTodaySchedule,
              color: primaryColor,
              child: schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Tidak ada jadwal aktif hari ini', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: schedules.length,
                      itemBuilder: (_, i) {
                        final s = schedules[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PresensiGatePage(
                                    role: widget.role,
                                    subjectId: s['id'],
                                  ),
                                ),
                              );

                              if (result == true && mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.book_outlined, color: primaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['mapel'] ?? '-',
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${s['jam_mulai']} - ${s['jam_selesai']}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
