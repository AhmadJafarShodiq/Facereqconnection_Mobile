// // confirm_photo_page.dart
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:facereq_mobile/core/api_service.dart';
// import 'package:flutter/material.dart';

// class ConfirmPhotoPage extends StatefulWidget {
//   final String photoPath;

//   const ConfirmPhotoPage({super.key, required this.photoPath});

//   @override
//   State<ConfirmPhotoPage> createState() => _ConfirmPhotoPageState();
// }

// class _ConfirmPhotoPageState extends State<ConfirmPhotoPage> {
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _checkIn();
//   }

//   Future<void> _checkIn() async {
//     try {
//       final Uint8List bytes = await File(widget.photoPath).readAsBytes();

//       await ApiService.checkIn(
//         latitude: 0.0,
//         longitude: 0.0,
//         photoBytes: bytes,
//       );

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Check-in berhasil ✅')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(e.toString())));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: _loading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : Image.file(File(widget.photoPath)),
//       ),
//     );
//   }
// }
