import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:facereq_mobile/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale Indonesia (WAJIB untuk tanggal)
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi Wajah',
      theme: ThemeData(
        primaryColor: const Color(0xFF0B5ED7),
        scaffoldBackgroundColor: const Color(0xFF0B5ED7),
      ),
      home: const SplashPage(),
    );
  }
}
