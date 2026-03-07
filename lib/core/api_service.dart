import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';
import 'app_config.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.105:8000/api';

  static Future<void> fetchSchoolSettings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/school'));
      final data = jsonDecode(res.body);
      if (data['status'] == true) {
        final school = data['data'];
        await AppConfig.update(
          name: school['nama_sekolah'] ?? 'SMK Negeri 1 Tamanan',
          color: school['primary_color'] ?? '#5E5CE6',
          logo: school['logo_url'] ?? '',
        );
      }
    } catch (e) {
      // Keep defaults
    }
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static Future<void> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data['status'] == true) {
      await AuthStorage.saveToken(data['token']);
      await AuthStorage.saveUser(data['data']);
      return;
    }

    throw Exception(data['message'] ?? 'Login gagal');
  }

  static Future<void> logout() async {
    final res = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Logout gagal');
    }

    await AuthStorage.logout();
  }

  static Future<Map<String, dynamic>> profile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Token tidak valid');
    }

    final data = jsonDecode(res.body);
    // Endpoint /me di backend mengembalikan object User langsung (sudah termasuk 'profile')
    await AuthStorage.saveUser(data);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> dashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat dashboard');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> faceStatus() async {
    final res = await http.get(
      Uri.parse('$baseUrl/face/status'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal cek status wajah');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> registerFace(List<double> embedding) async {
    final res = await http.post(
      Uri.parse('$baseUrl/face/register'),
      headers: await _headers(),
      body: jsonEncode({'embedding': embedding}),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Register wajah gagal');
    }
  }

  static Future<Map<String, dynamic>> verifyFace(List<double> embedding) async {
    final res = await http.post(
      Uri.parse('$baseUrl/face/verify'),
      headers: await _headers(),
      body: jsonEncode({'embedding': embedding}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 403) {
      throw Exception(data['code']);
    }

    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Verifikasi gagal');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> school() async {
    final res = await http.get(
      Uri.parse('$baseUrl/school'),
      headers: await _headers(),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat sekolah');
    }

    return Map<String, dynamic>.from(body['data']);
  }

  static Future<Map<String, dynamic>> todayAttendance() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/today'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) return {};
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> studentHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/history'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Gagal memuat riwayat absensi');
    }

    if (data is Map && data.containsKey('data')) {
      return List<Map<String, dynamic>>.from(data['data']);
    }

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> studentCheckIn({
    required int scheduleId, // sebelumnya subjectId
    required double latitude,
    required double longitude,
    Uint8List? photoBytes,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attendance/student'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields.addAll({
      'schedule_id': scheduleId.toString(), // wajib sesuai backend
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    });

    if (photoBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('foto', photoBytes, filename: 'absen.jpg'),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    if (response.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Presensi gagal');
    }

    return Map<String, dynamic>.from(data['data'] ?? data);
  }

  static Future<Map<String, dynamic>> teacherCheckIn({
    required double latitude,
    required double longitude,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/teacher/check-in'),
      headers: await _headers(),
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Presensi masuk gagal');
    }

    return Map<String, dynamic>.from(data['data'] ?? data);
  }

  static Future<Map<String, dynamic>> teacherCheckOut() async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/teacher/check-out'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Presensi pulang gagal');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> missingStudents({
    required int subjectId,
    required int classId,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/subject/$subjectId/$classId/missing'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal memuat siswa belum absen');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> studentAttendanceBySubject({
    required int subjectId,
    required int classId,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/subject/$subjectId/$classId/today'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal memuat absensi siswa');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> attendanceReport({
    required int subjectId,
    required int classId,
    required String startDate,
    required String endDate,
  }) async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/attendance/subject/$subjectId/$classId/report',
      ).replace(
        queryParameters: {'start_date': startDate, 'end_date': endDate},
      ),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal memuat laporan absensi');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> studentTodaySchedule() async {
    final res = await http.get(
      Uri.parse('$baseUrl/schedules/today'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat jadwal siswa');
    }

    final body = jsonDecode(res.body);
    if (body is Map && body.containsKey('data')) {
      return List<Map<String, dynamic>>.from(body['data']);
    }

    return List<Map<String, dynamic>>.from(body);
  }

  static Future<List<Map<String, dynamic>>> guruTodaySchedule() async {
    final res = await http.get(
      Uri.parse('$baseUrl/schedules/today'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat jadwal guru');
    }

    final body = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(body['data']);
  }

  static Future<Map<String, dynamic>> openSession(int scheduleId, {int? duration}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/guru/attendance/open'),
      headers: await _headers(),
      body: jsonEncode({
        'schedule_id': scheduleId,
        'duration': duration,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal membuka sesi absen');
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<void> closeSession(int sessionId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/guru/attendance/$sessionId/close'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal menutup sesi absen');
    }
  }

  static Future<bool> cekface() async {
    final res = await http.get(
      Uri.parse('$baseUrl/face/status/'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data['registered'] == false) {
      return false;
    } else {
      return true;
    }
  }

  static Future<Map<String, dynamic>> todaySchedule() async {
    final res = await http.get(
      Uri.parse('$baseUrl/schedules/today'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat jadwal hari ini');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // UPDATE PROFIL
  static Future<void> updateProfile({
    required String name,
    required String nip,
    String? jabatan,
    String? instansi,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/profile/update'),
      headers: await _headers(),
      body: jsonEncode({
        'nama_lengkap': name,
        'nip_nis': nip,
        'jabatan_kelas': jabatan,
        'instansi': instansi,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal memperbarui profil');
    }
  }

  // UBAH PASSWORD
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/profile/password'),
      headers: await _headers(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengubah password');
    }
  }

  // UPDATE FOTO
  static Future<String> updatePhoto(Uint8List bytes) async {
    final token = await AuthStorage.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile/photo'));
    
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes('foto', bytes, filename: 'profile.jpg'),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    if (response.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengupload foto');
    }

    return data['foto'];
  }
}
