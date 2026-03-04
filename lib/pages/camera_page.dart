import 'dart:typed_data';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:facereq_mobile/core/api_service.dart';
import 'confirm_face_page.dart';

class CameraPage extends StatefulWidget {
  final String role;
  final int? subjectId;
  final String type;

  const CameraPage({
    super.key,
    required this.role,
    required this.type,
    this.subjectId,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('face_recognition');

  late final Ticker _ticker;
  double _t = 0;

  CameraController? _controller;
  bool _processing = false;
  bool _captured = false;
  bool _takingPicture = false;
  bool _disposed = false;

  String _hint = "Arahkan wajah ke kamera";
  List<Map<String, double>> _landmarks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();

    _ticker = Ticker((elapsed) {
      _t = elapsed.inMilliseconds / 1000;
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
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
    await _controller!.startImageStream(_onFrame);

    if (mounted) setState(() {});
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_disposed || _processing || _captured || _takingPicture) return;

    _processing = true;
    try {
      final res = await _channel.invokeMethod('processFrame', {
        'image': image.planes[0].bytes,
        'mirror': true,
      });

      final landmarksRaw = res['landmarks'];
      if (landmarksRaw == null || landmarksRaw.isEmpty) {
        _landmarks.clear();
        _hint = "Arahkan wajah ke kamera";
        setState(() {});
        return;
      }

      _landmarks = List<Map<String, double>>.from(
        landmarksRaw.map((e) => {
              'x': (e['x'] as num).toDouble(),
              'y': (e['y'] as num).toDouble(),
            }),
      );

      _captured = true;
      _hint = "Memverifikasi wajah...";
      setState(() {});

      await Future.delayed(const Duration(milliseconds: 400));
      await _captureAndVerify();
    } finally {
      _processing = false;
    }
  }

  Future<void> _captureAndVerify() async {
    if (_takingPicture || _controller == null) return;
    _takingPicture = true;

    try {
      await _controller!.stopImageStream();

      final photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      final result = Map<String, dynamic>.from(
        await _channel.invokeMethod('getEmbedding', {'image': bytes}),
      );

      final embedding = (result['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      final verify = await ApiService.verifyFace(embedding);

      if (!mounted || verify == null || verify['status'] != true) {
        _captured = false;
        _hint = "Wajah tidak dikenali";
        await _controller!.startImageStream(_onFrame);
        setState(() {});
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmFacePage(
            photoBytes: bytes,
            name: verify['name'] ?? 'Pengguna',
            similarity: double.parse(verify['similarity'].toString()),
            role: widget.role,
            subjectId: widget.subjectId,
            type: widget.type,
          ),
        ),
      );
    } finally {
      _takingPicture = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final cameraRatio = _controller!.value.aspectRatio;
    final screenRatio = size.width / size.height;
    final scale = (cameraRatio / screenRatio).clamp(1.0, 1.25);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(_controller!)),
          ),
          Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: FaceLandmarkPainter(
                _landmarks,
                mirror: true,
                t: _t,
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _hint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= LANDMARK PAINTER (AI SCAN FINAL) =================

// ================= LANDMARK PAINTER (AI SCAN FINAL) =================
class FaceLandmarkPainter extends CustomPainter {
  final List<Map<String, double>> landmarks;
  final bool mirror;
  final bool active;
  final double t; // tambahkan ini

  FaceLandmarkPainter(
    this.landmarks, {
    this.mirror = false,
    this.active = true,
    this.t = 0, // default value
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // ===== FACE CENTER (DIHALUSKAN KE TENGAH LAYAR) =====
    final faceCenter = _faceCenter(size);
    final screenCenter = Offset(size.width / 2, size.height / 2);

    // blend biar ga terlalu ngikut landmark (lebih stabil)
    final center = Offset(
      lerpDouble(faceCenter.dx, screenCenter.dx, 0.35)!,
      lerpDouble(faceCenter.dy, screenCenter.dy, 0.35)!,
    );

    // ===== SOFT MASK =====
    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.25);

    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(
        Rect.fromCenter(
          center: center,
          width: 260,
          height: 340,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    // ===== LANDMARK MINIMAL =====
    final dotPaint = Paint()
      ..color = active
          ? Colors.cyanAccent.withOpacity(0.7)
          : Colors.greenAccent.withOpacity(0.9);

    // opsional: bisa pakai t untuk animasi alpha atau blink
    final alpha = ((sin(t * 2 * pi) + 1) / 2 * 0.7 + 0.3).clamp(0.3, 1.0);

    for (int i = 0; i < landmarks.length; i += 16) {
      final lm = landmarks[i];
      final x = mirror ? (1 - (lm['x'] ?? 0)) : (lm['x'] ?? 0);
      final y = lm['y'] ?? 0;
      final p = Offset(x * size.width, y * size.height);

      canvas.drawCircle(p, 2, dotPaint..color = dotPaint.color.withOpacity(alpha));
    }
  }

  Offset _faceCenter(Size size) {
    double x = 0, y = 0;
    for (final lm in landmarks) {
      x += mirror ? (1 - (lm['x'] ?? 0)) : (lm['x'] ?? 0);
      y += lm['y'] ?? 0;
    }
    return Offset(
      (x / landmarks.length) * size.width,
      (y / landmarks.length) * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
