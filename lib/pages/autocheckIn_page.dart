import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:facereq_mobile/core/api_service.dart';
import 'package:facereq_mobile/core/location_service.dart';

class AutoCheckInPage extends StatefulWidget {
  final String role; // 'student' | 'teacher'
  final int? subjectId; // scheduleId untuk student

  const AutoCheckInPage({super.key, required this.role, this.subjectId});

  @override
  State<AutoCheckInPage> createState() => _AutoCheckInPageState();
}

class _AutoCheckInPageState extends State<AutoCheckInPage> {
  static const MethodChannel _channel = MethodChannel('face_recognition');

  CameraController? _controller;
  bool _loading = true;
  bool _processing = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();

      await _channel.invokeMethod('setMode', {'mode': 'absen'});
      await _channel.invokeMethod('resetLiveness');

      if (!mounted) return;
      setState(() => _loading = false);
      await Future.delayed(const Duration(milliseconds: 600));
      _autoCheckIn();
    } catch (_) {
      _error('Gagal membuka kamera');
    }
  }

  Future<void> _autoCheckIn() async {
    if (_processing || _controller == null || !_controller!.value.isInitialized || _disposed) return;

    _processing = true;
    setState(() => _loading = true);

    try {
      final photo = await _controller!.takePicture();
      final Uint8List imageBytes = await File(photo.path).readAsBytes();

      final Map<String, dynamic> embedResult = Map<String, dynamic>.from(
        await _channel.invokeMethod('getEmbedding', {'image': imageBytes}),
      );

      final List<double> embedding = (embedResult['embedding'] as List).map((e) => (e as num).toDouble()).toList();
      final verify = await ApiService.verifyFace(embedding);
      if (verify['status'] != true) throw Exception('Wajah tidak dikenali');

      final position = await LocationService.getCurrentLocation();

      if (widget.role == 'student') {
        if (widget.subjectId == null) throw Exception('scheduleId tidak ditemukan');
        await ApiService.studentCheckIn(
          scheduleId: widget.subjectId!,
          latitude: position.latitude,
          longitude: position.longitude,
          photoBytes: imageBytes,
        );
      } else {
        await ApiService.teacherCheckIn(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presensi berhasil ✅'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      _error(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _processing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _loading ? const CircularProgressIndicator(color: Colors.white) : CameraPreview(_controller!),
      ),
    );
  }
}
