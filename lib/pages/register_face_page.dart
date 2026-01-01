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
  bool _processing = false;
  bool _livenessOk = false;
  String _hint = "Kedipkan mata & gerakkan kepala";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    await _channel.invokeMethod('resetLiveness');

    // 🔥 STREAM FRAME UNTUK LIVENESS
    await _controller!.startImageStream(_onFrame);

    if (mounted) setState(() {});
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _livenessOk) return;
    _processing = true;

    try {
      final Uint8List bytes = image.planes[0].bytes;

      final result = await _channel.invokeMethod('processFrame', {
        'image': bytes,
      });

      if (result['liveness'] == true) {
        setState(() {
          _livenessOk = true;
          _hint = "Liveness OK, klik daftar";
        });

        await _controller!.stopImageStream();
      }
    } catch (_) {}

    _processing = false;
  }

  Future<void> _registerFace() async {
    if (!_livenessOk || _processing) return;
    _processing = true;

    try {
      // 🔥 WAJIB STOP STREAM
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      final XFile photo = await _controller!.takePicture();
      final Uint8List bytes = await File(photo.path).readAsBytes();

      final result = await _channel.invokeMethod('getEmbedding', {
        'image': bytes,
      });

      final List<double> embedding = List<double>.from(result['embedding']);

      await ApiService.registerFace(embedding);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajah berhasil didaftarkan ✅')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      _processing = false;
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),

          Positioned(
            top: 80,
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
                  onPressed: _processing ? null : _registerFace,
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
