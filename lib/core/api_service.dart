// api_service.dart (FINAL – FIXED, TANPA DUPLIKAT)
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.108:8000/api';

  
  static Future<bool> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data['status'] == true) {
      await AuthStorage.saveToken(data['token']);
      await AuthStorage.saveUser(data['data']);
      return true;
    }

    throw Exception(data['message'] ?? 'Login gagal');
  }

  // =======================
  // FACE VERIFY
  // =======================
  static Future<Map<String, dynamic>> verifyFace(List<double> embedding) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final res = await http.post(
      Uri.parse('$baseUrl/face/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'embedding': embedding}),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }

  // =======================
  // REGISTER FACE
  // =======================
  static Future<void> registerFace(List<double> embedding) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final res = await http.post(
      Uri.parse('$baseUrl/face/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'embedding': embedding}),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  // =======================
  // FACE STATUS
  // =======================
  static Future<bool> faceStatus() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final res = await http.get(
      Uri.parse('$baseUrl/face/status'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body);
    return data['registered'] == true;
  }

  // =======================
  // HISTORY
  // =======================
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final decoded = jsonDecode(res.body);

    final List listData = decoded is Map && decoded['data'] is List
        ? decoded['data']
        : [];

    return listData
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(e),
        )
        .toList();
  }

  // =======================
  // CHECK-IN
  // =======================
  static Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    Uint8List? photoBytes,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attendance/check-in'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    if (photoBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('foto', photoBytes, filename: 'photo.jpg'),
      );
    }

    final response = await request.send();
    final resStr = await response.stream.bytesToString();
    final data = jsonDecode(resStr);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Check-in gagal');
    }

    // 🔥 kembalikan data lengkap dari backend
    return {
      'message': data['message'] ?? 'Check-in berhasil',
      'is_late': data['is_late'] ?? false,
      'late_minutes': data['late_minutes'] ?? 0,
    };
  }

  // =======================
  // CHECK-OUT
  // =======================
  static Future<Map<String, dynamic>> checkOut() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Check-out gagal');
    }

    return {
      'message': data['message'] ?? 'Check-out berhasil',
      'is_early': data['is_early'] ?? false,
      'early_minutes': data['early_minutes'] ?? 0,
    };
  }
}
