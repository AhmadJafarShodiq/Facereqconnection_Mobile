import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facereq_mobile/core/api_service.dart';
import 'package:facereq_mobile/pages/confirm_face_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const MethodChannel _channel =
      MethodChannel('face_recognition');

  CameraController? _controller;
  bool _processing = false;
  bool _done = false;
  String _hint = "Kedip & gerakkan kepala";

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
    await _channel.invokeMethod('resetLiveness');

    await _controller!.startImageStream(_onFrame);

    if (mounted) setState(() {});
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _done) return;
    _processing = true;

    try {
      final bytes = image.planes[0].bytes;

      final res = await _channel.invokeMethod(
        'processFrame',
        {'image': bytes},
      );

      if (res['liveness'] == true) {
        _done = true;
        _hint = "Liveness OK";
        setState(() {});
        await _capture();
      }
    } catch (_) {}

    _processing = false;
  }

  Future<void> _capture() async {
    try {
      await _controller!.stopImageStream();

      final photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      final result = await _channel.invokeMethod(
        'getEmbedding',
        {'image': bytes},
      );

      final embedding = (result['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      final verify = await ApiService.verifyFace(embedding);

      if (verify['status'] != true) {
        throw Exception('Wajah tidak cocok');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmFacePage(
            photoPath: photo.path,
            name: verify['name'] ?? 'Pengguna',
            similarity: double.parse(
              verify['similarity'].toString(),
            ),
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null ||
              !_controller!.value.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
