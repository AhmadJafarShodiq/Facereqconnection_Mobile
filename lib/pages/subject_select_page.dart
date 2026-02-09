import 'package:flutter/material.dart';
import '../core/api_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Hari Ini'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : schedules.isEmpty
              ? const Center(child: Text('Tidak ada jadwal hari ini'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (_, i) {
                    final s = schedules[i];
                    final color = colors[i % colors.length];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
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
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.8), color],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.book,
                                color: Colors.white, size: 30),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['mapel'] ?? '-',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${s['jam_mulai']} - ${s['jam_selesai']}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
