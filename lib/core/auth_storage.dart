import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  // ===== SAVE =====
  static Future<void> saveToken(String token) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_tokenKey, token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_userKey, jsonEncode(user));
  }

  // ===== GET =====
  static Future<String?> getToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final pref = await SharedPreferences.getInstance();
    final json = pref.getString(_userKey);
    if (json == null) return null;
    return jsonDecode(json);
  }

  // ===== CLEAR =====
  static Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_tokenKey);
    await pref.remove(_userKey);
  }

  
  static Future<void> logout() async {
    await clear();
  }
}
