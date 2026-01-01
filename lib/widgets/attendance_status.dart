import 'package:flutter/material.dart';

enum AttendanceStatus { notCheckedIn, checkedIn, checkedOut }

class AttendancePopup extends StatefulWidget {
  final AttendanceStatus status;
  final String message;

  const AttendancePopup({super.key, required this.status, required this.message});

  @override
  State<AttendancePopup> createState() => _AttendancePopupState();
}

class _AttendancePopupState extends State<AttendancePopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.status) {
      case AttendanceStatus.notCheckedIn:
        return Colors.orange;
      case AttendanceStatus.checkedIn:
        return Colors.green;
      case AttendanceStatus.checkedOut:
        return Colors.blueGrey;
    }
  }

  IconData _getIcon() {
    switch (widget.status) {
      case AttendanceStatus.notCheckedIn:
        return Icons.warning_amber_outlined;
      case AttendanceStatus.checkedIn:
        return Icons.check_circle_outline;
      case AttendanceStatus.checkedOut:
        return Icons.done_all_outlined;
    }
  }

  String _getTitle() {
    switch (widget.status) {
      case AttendanceStatus.notCheckedIn:
        return "Belum Absen";
      case AttendanceStatus.checkedIn:
        return "Sudah Absen Masuk";
      case AttendanceStatus.checkedOut:
        return "Sudah Absen Pulang";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: _getColor(),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIcon(), size: 50, color: Colors.white),
                const SizedBox(height: 12),
                Text(_getTitle(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _getColor(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
