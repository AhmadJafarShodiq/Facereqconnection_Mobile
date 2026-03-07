import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String schoolName = 'SMK Negeri 1 Tamanan';
  static final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(const Color(0xFF5E5CE6));
  static Color get primaryColor => primaryColorNotifier.value;
  static String logoUrl = '';
  static bool useNetworkLogo = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    schoolName = prefs.getString('school_name') ?? 'SMK Negeri 1 Tamanan';
    final colorHex = prefs.getString('primary_color') ?? '#5E5CE6';
    primaryColorNotifier.value = _parseColor(colorHex);
    logoUrl = prefs.getString('logo_url') ?? '';
    useNetworkLogo = logoUrl.isNotEmpty;
  }

  static Future<void> update({
    required String name,
    required String color,
    required String logo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('school_name', name);
    await prefs.setString('primary_color', color);
    await prefs.setString('logo_url', logo);

    schoolName = name;
    primaryColorNotifier.value = _parseColor(color);
    logoUrl = logo;
    useNetworkLogo = logo.isNotEmpty;
  }

  static Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF5E5CE6);
    }
  }
}
