import 'package:flutter/material.dart';
import 'camera_page.dart';

class ScanGatePage extends StatefulWidget {
  final String role;        // 'student' | 'teacher'
  final int? subjectId;   
  final type;
    // WAJIB untuk student

  const ScanGatePage({
    super.key,
    required this.role,
    this.subjectId,
    this.type,
  });

  @override
  State<ScanGatePage> createState() => _ScanGatePageState();
}

class _ScanGatePageState extends State<ScanGatePage> {
  @override
  void initState() {
    super.initState();

    // validasi student wajib pilih mapel
    if (widget.role == 'student' && widget.subjectId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapel belum dipilih'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
      return;
    }

    _goCamera();
  }

  Future<void> _goCamera() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CameraPage(
          role: widget.role,
          subjectId: widget.subjectId,
          type: widget.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
