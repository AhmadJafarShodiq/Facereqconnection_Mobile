import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:facereq_mobile/core/api_service.dart';
import 'package:facereq_mobile/core/location_service.dart';

class AutoCheckInPage extends StatefulWidget {
  const AutoCheckInPage({super.key});

  @override
  State<AutoCheckInPage> createState() => _AutoCheckInPageState();
}

class _AutoCheckInPageState extends State<AutoCheckInPage> {
  static const MethodChannel _channel =
      MethodChannel('face_recognition');

  CameraController? _cameraController;
  bool _loading = true;
  bool _processing = false;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ================= INIT CAMERA =================
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() => _loading = false);

      // kasih jeda biar kamera stabil
      await Future.delayed(const Duration(milliseconds: 700));
      _autoCheckIn();
    } catch (e) {
      _showError('Gagal membuka kamera');
    }
  }

  // ================= AUTO CHECK IN =================
  Future<void> _autoCheckIn() async {
    if (_processing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    _processing = true;
    setState(() => _loading = true);

    try {
      // 1️⃣ AMBIL FOTO
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List imageBytes =
          await File(photo.path).readAsBytes();

      // 2️⃣ FACE + LIVENESS + EMBEDDING (ANDROID NATIVE)
      final Map result = await _channel.invokeMethod(
        'getEmbedding',
        {'image': imageBytes},
      );

      if (result['liveness'] != true) {
        throw Exception('Liveness check gagal');
      }

      final List<double> embedding =
          List<double>.from(result['embedding']);

      // 3️⃣ VERIFIKASI WAJAH (API)
      final verifyResult =
          await ApiService.verifyFace(embedding);

      if (verifyResult['status'] != true) {
        throw Exception('Wajah tidak cocok');
      }

      // 4️⃣ AMBIL GPS
      final position =
          await LocationService.getCurrentLocation();

      // 5️⃣ CHECK-IN
      await ApiService.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        photoBytes: imageBytes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in berhasil ✅'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on PlatformException catch (e) {
      _showError(e.message ?? 'Face recognition error');
    } catch (e) {
      _showError(e.toString());
    } finally {
      _processing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : CameraPreview(_cameraController!),
      ),
    );
  }

  // ================= ERROR HANDLER =================
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
