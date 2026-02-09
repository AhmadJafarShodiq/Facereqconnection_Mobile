import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('face_recognition');

  CameraController? _controller;
  bool _captured = false;
  bool _processing = false;
  bool _disposed = false;
  bool _streamStopped = false;
  bool _takingPicture = false;

  String _hint = "Arahkan wajah ke kamera";
  List<Map<String, double>> _landmarks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await _stopStream();
      await _controller?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      await _controller?.resumePreview();
      if (!_disposed) await _startStream();
    }
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
    await _startStream();

    if (mounted) setState(() {});
  }

  Future<void> _startStream() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isStreamingImages ||
        _disposed)
      return;

    _streamStopped = false;
    await _controller!.startImageStream(_onFrame);
  }

  Future<void> _stopStream() async {
    if (_streamStopped) return;
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        _streamStopped = true;
        await _controller!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_disposed || !mounted) return;
    if (_processing || _captured || _takingPicture) return;

    _processing = true;
    try {
      final bytes = image.planes[0].bytes;

      final res = await _channel.invokeMethod('processFrame', {
        'image': bytes,
        'mirror': true,
      });

      if (!mounted || _disposed) return;

      final landmarksRaw = res['landmarks'];
      if (landmarksRaw == null || (landmarksRaw as List).isEmpty) {
        _landmarks.clear();
        _hint = "Arahkan wajah ke kamera";
        setState(() {});
        return;
      }

      _landmarks = List<Map<String, double>>.from(
        landmarksRaw.map(
          (e) => {
            'x': (e['x'] as num).toDouble(),
            'y': (e['y'] as num).toDouble(),
          },
        ),
      );

      setState(() {});

      if (!_captured) {
        _captured = true;
        _hint = "Memverifikasi wajah...";
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_disposed) await _captureAndVerify();
      }
    } finally {
      _processing = false;
    }
  }

 Future<void> _captureAndVerify() async {
  if (_takingPicture) return;
  _takingPicture = true;

  try {
    if (_controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!_controller!.value.isInitialized) return;

    final photo = await _controller!.takePicture();
    final bytes = await photo.readAsBytes();

    final result = Map<String, dynamic>.from(
      await _channel.invokeMethod('getEmbedding', {'image': bytes}),
    );

    final embedding = (result['embedding'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    final verify = await ApiService.verifyFace(embedding);

    if (verify == null || verify['status'] != true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajah tidak dikenali'),
          backgroundColor: Colors.red,
        ),
      );

      _captured = false;
      _takingPicture = false;
      _hint = "Arahkan wajah ke kamera";
      await _startStream(); // restart stream
      return;
    }

    if (!mounted) return;

    // Lanjut ke ConfirmFacePage
    final ok = await Navigator.push(
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

    // Reset untuk absen mapel selanjutnya
    if (mounted) {
      _captured = false;
      _takingPicture = false;
      _hint = "Arahkan wajah ke kamera";
      _landmarks.clear();
      await _startStream();
    }

    if (ok == true && mounted) {
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  } finally {
    _takingPicture = false;
  }
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
              painter: FaceLandmarkPainter(_landmarks, mirror: true),
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
        ],
      ),
    );
  }
}

class FaceLandmarkPainter extends CustomPainter {
  final List<Map<String, double>> landmarks;
  final bool mirror;

  FaceLandmarkPainter(this.landmarks, {this.mirror = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    for (final lm in landmarks) {
      final x = mirror ? (1 - lm['x']!) : lm['x']!;
      canvas.drawCircle(
        Offset(x * size.width, lm['y']! * size.height),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceLandmarkPainter oldDelegate) => true;
}
