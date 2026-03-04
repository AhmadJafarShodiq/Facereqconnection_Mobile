import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:facereq_mobile/core/api_service.dart';

class RegisterFacePage extends StatefulWidget {
  const RegisterFacePage({super.key});

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage> {
  static const MethodChannel _channel = MethodChannel('face_recognition');

  CameraController? _controller;

  bool _livenessOk = false;
  bool _capturing = false;

  String _hint = "Hadap kamera, kedip 1x lalu geleng pelan";

  List<Map<String, double>> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
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

    await _channel.invokeMethod('setMode', {'mode': 'register'});
    await _channel.invokeMethod('resetLiveness');

    await _controller!.startImageStream(_onFrame);

    if (mounted) setState(() {});
  }

  // 🔥 JANGAN BLOK FRAME (INI KUNCI)
  Future<void> _onFrame(CameraImage image) async {
    if (_livenessOk) return;

    try {
      final Uint8List bytes = image.planes[0].bytes;

      final dynamic res = await _channel.invokeMethod('processFrame', {
        'image': bytes,
        'mirror': true,
      });

      if (!mounted || res == null || res is! Map) return;

      if (res['landmarks'] != null && res['landmarks'] is List) {
        setState(() {
          _landmarks = List<Map<String, double>>.from(
            (res['landmarks'] as List).map(
              (e) => {
                'x': (e['x'] as num).toDouble(),
                'y': (e['y'] as num).toDouble(),
              },
            ),
          );
        });
      }

      if (res['liveness'] == true) {
        setState(() {
          _livenessOk = true;
          _hint = "Liveness OK, klik Daftarkan";
        });
        await _controller?.stopImageStream();
      }
    } catch (_) {}
  }

  Future<void> _register() async {
    if (_capturing || !_livenessOk) return;
    _capturing = true;

    try {
      // 🔥 DELAY BIAR STABIL
      await Future.delayed(const Duration(seconds: 1));

      final photo = await _controller!.takePicture();
      final bytes = await File(photo.path).readAsBytes();

      final result = await _channel.invokeMethod('getEmbedding', {
        'image': bytes,
      });

      if (result['embedding'] == null) {
        _error("Wajah tidak terdeteksi, silakan ulangi");
        _capturing = false;
        return;
      }

      final embedding = (result['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      await ApiService.registerFace(embedding);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajah berhasil didaftarkan ✅')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _error(e.toString());
    } finally {
      _capturing = false;
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;
    final cameraRatio = _controller!.value.aspectRatio;
    final screenRatio = size.width / size.height;

    double scale = cameraRatio / screenRatio;
    if (scale < 1) scale = 1 / scale;

    // 🔥 BATASI BIAR GA OVER ZOOM
    scale = scale.clamp(1.0, 1.25);

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
                active: !_livenessOk,
              ),
            ),
          ),

          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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

          if (_livenessOk)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _capturing ? null : _register,
                  child: const Text("DAFTARKAN WAJAH"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// ================== PAINTER ==================

class FaceLandmarkPainter extends CustomPainter {
  final List<Map<String, double>> landmarks;
  final bool mirror;
  final bool active;

  FaceLandmarkPainter(
    this.landmarks, {
    this.mirror = false,
    this.active = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // CENTER FIX KE TENGAH LAYAR
    final center = Offset(size.width / 2, size.height / 2);

    // ===== SOFT MASK (FOCUS FACE) =====
    final maskPaint = Paint()..color = Colors.black.withOpacity(0.25);

    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCenter(center: center, width: 260, height: 340))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    if (landmarks.isEmpty) return;

    // ===== LANDMARK MINIMAL (STATUS) =====
    final dotPaint = Paint()
      ..color = active
          ? Colors.cyanAccent.withOpacity(0.7)
          : Colors.greenAccent.withOpacity(0.9);

    for (int i = 0; i < landmarks.length; i += 16) {
      final lm = landmarks[i];
      final x = mirror ? (1 - lm['x']!) : lm['x']!;
      final p = Offset(x * size.width, lm['y']! * size.height);

      canvas.drawCircle(p, 2, dotPaint);
    }
  }

  Offset _faceCenter(Size size) {
    double x = 0, y = 0;
    for (final lm in landmarks) {
      x += mirror ? (1 - lm['x']!) : lm['x']!;
      y += lm['y']!;
    }
    return Offset(
      (x / landmarks.length) * size.width,
      (y / landmarks.length) * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


