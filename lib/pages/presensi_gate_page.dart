import 'package:flutter/material.dart';
import 'location_check_page.dart';

class PresensiGatePage extends StatefulWidget {
  final String role;
  final int? subjectId;

  const PresensiGatePage({
    super.key,
    required this.role,
    this.subjectId,
  });

  @override
  State<PresensiGatePage> createState() => _PresensiGatePageState();
}

class _PresensiGatePageState extends State<PresensiGatePage> {
  @override
  void initState() {
    super.initState();
    _goLocation();
  }

  Future<void> _goLocation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPage(
          role: widget.role,
          subjectId: widget.subjectId,
          type: 'check_in',
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context, true); // ← kirim true ke HomePage supaya refresh
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
