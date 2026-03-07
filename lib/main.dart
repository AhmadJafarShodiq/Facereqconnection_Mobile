import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:facereq_mobile/pages/splash_page.dart';
import 'package:facereq_mobile/core/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load cached configuration
  await AppConfig.load();

  // Locale Indonesia (WAJIB untuk tanggal)
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppConfig.primaryColorNotifier,
      builder: (context, color, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Absensi Wajah',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: color,
            colorScheme: ColorScheme.fromSeed(
              seedColor: color,
              primary: color,
              secondary: color,
              surface: const Color(0xFFF8FAFC),
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
            fontFamily: 'SourceSans3',
          ),
          home: const SplashPage(),
        );
      },
    );
  }
}
