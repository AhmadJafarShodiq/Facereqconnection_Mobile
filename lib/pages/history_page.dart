import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });
      history = await ApiService.studentHistory();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
          .format(DateTime.parse(date));
    } catch (_) {
      return '-';
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'hadir':
        return const Color(0xFF2563EB);
      case 'terlambat':
        return Colors.red;
      case 'pulang':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'hadir':
        return Icons.check_circle;
      case 'terlambat':
        return Icons.warning_amber_rounded;
      case 'pulang':
        return Icons.logout;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFEFF3FB),
        foregroundColor: Colors.black,
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(error!)),
        ],
      );
    }

    if (history.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.event_busy, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('Belum ada riwayat absensi')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final color = _statusColor(item['status']);

        // Mapel hanya tidak ditampilkan untuk guru
        final isGuru = item['subject'] == null || item['subject'] == '-';
        final subject = !isGuru ? item['subject'] ?? '-' : null;

        return _HistoryCard(
          date: _formatDate(item['tanggal']?.toString()),
          subject: subject,
          timeIn: item['jam']?.toString() ?? '-',
          timeOut: item['time_out']?.toString() ?? '-',
          status: item['status'] ?? '-',
          color: color,
          icon: _statusIcon(item['status']),
          photoUrl: item['foto'],
          latitude: (item['latitude'] != null)
              ? double.tryParse(item['latitude'].toString())
              : null,
          longitude: (item['longitude'] != null)
              ? double.tryParse(item['longitude'].toString())
              : null,
          isGuru: isGuru,
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String date;
  final String? subject; // bisa null kalau guru
  final String timeIn;
  final String timeOut;
  final String status;
  final Color color;
  final IconData icon;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final bool isGuru;

  const _HistoryCard({
    required this.date,
    this.subject,
    required this.timeIn,
    required this.timeOut,
    required this.status,
    required this.color,
    required this.icon,
    this.photoUrl,
    this.latitude,
    this.longitude,
    required this.isGuru,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          if (!isGuru && subject != null) ...[
            const SizedBox(height: 10),
            Text(
              'Mapel: $subject',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 60),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _timeBox('Masuk', timeIn, Icons.login),
                        if (timeOut.isNotEmpty && timeOut != '-') ...[
                          const SizedBox(width: 16),
                          _timeBox('Pulang', timeOut, Icons.logout),
                        ],
                      ],
                    ),
                    if (latitude != null && longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lokasi: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String label, String time, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                Text(time,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
