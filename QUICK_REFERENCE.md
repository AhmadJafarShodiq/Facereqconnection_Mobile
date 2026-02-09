# Quick Reference - API Endpoints & Implementation

## 🔐 Authentication

### Login
```dart
// lib/pages/login_page.dart
await ApiService.login(username, password);
// POST /login
// Saves token & user to storage
```

### Logout
```dart
// lib/pages/profile_page.dart
try {
  await ApiService.logout();  // NEW!
} catch (e) {
  await AuthStorage.logout();  // fallback
}
// POST /logout
// Clears token from backend & local storage
```

### Get Profile
```dart
// Rarely used directly, but available
final profile = await ApiService.profile();
// GET /me
```

---

## 📚 Dashboard & Data Loading

### Home Dashboard
```dart
// lib/pages/home_page.dart
final dashboard = await ApiService.dashboard();
// GET /dashboard
// 
// Siswa Response:
// {
//   "role": "siswa",
//   "nama": "Budi",
//   "summary": { "hadir": 15, "terlambat": 2 },
//   "history": [
//     { "mapel": "MTK", "jam": "08:00", "status": "hadir" }
//   ]
// }
//
// Guru Response:
// {
//   "role": "guru",
//   "nama": "Ibu Sri",
//   "presensi": { "masuk": true, "pulang": false }
// }
```

### Today Attendance Status
```dart
// lib/pages/home_page.dart
final status = await ApiService.todayAttendance();
// GET /attendance/today
// {
//   "check_in_time": "08:05",
//   "is_late": false,
//   "late_minutes": 0,
//   "subject": "Matematika"
// }
```

### History (via Dashboard)
```dart
// lib/pages/history_page.dart
final dashboard = await ApiService.dashboard();
List history = dashboard['history'];
// Extract from dashboard response instead of separate endpoint
```

---

## 📍 Subjects & Locations

### Get Subjects
```dart
// lib/pages/subject_select_page.dart
final subjects = await ApiService.subjects();
// GET /subjects
// Returns: [{ "id": 1, "nama_mapel": "Matematika" }, ...]
```

### Get School Location
```dart
// lib/pages/location_check_page.dart
final school = await ApiService.school();
// GET /school
// {
//   "id": 1,
//   "nama_sekolah": "SMKN 1 Tamananan",
//   "latitude": "-6.xxx",
//   "longitude": "106.xxx",
//   "radius": 100  // meters
// }
```

---

## 👤 Face Recognition

### Check Face Status
```dart
// lib/pages/login_page.dart, home_page.dart
final registered = await ApiService.faceStatus();
// GET /face/status
// Returns: boolean or { "registered": true/false }
```

### Register Face
```dart
// lib/pages/register_face_page.dart
await ApiService.registerFace(embedding);
// POST /face/register
// { "embedding": [0.1, 0.2, ..., 0.512] }  // 512-dim vector
```

### Verify Face
```dart
// lib/pages/autocheckIn_page.dart
final verify = await ApiService.verifyFace(embedding);
// POST /face/verify
// { "embedding": [...] }
// Returns: { "status": true, "message": "..." }
```

---

## ✅ Attendance Check-in

### Student Check-in
```dart
// lib/pages/autocheckIn_page.dart
final result = await ApiService.studentCheckIn(
  subjectId: 1,
  latitude: -6.1234,
  longitude: 106.5678,
  photoBytes: imageBytes,  // optional
);
// POST /attendance/student (multipart form)
// Returns:
// {
//   "status": true,
//   "message": "Presensi berhasil",
//   "data": {
//     "nama": "Budi",
//     "kelas": "10-A",
//     "mapel": "Matematika",
//     "jam": "08:00",
//     "status": "hadir",
//     "foto": "path/to/foto.jpg",
//     "lat": -6.1234,
//     "lng": 106.5678
//   }
// }
```

### Teacher Check-in
```dart
// lib/pages/autocheckIn_page.dart
final result = await ApiService.teacherCheckIn(
  latitude: -6.1234,
  longitude: 106.5678,
);
// POST /attendance/teacher/check-in
// Returns:
// {
//   "status": true,
//   "message": "Presensi masuk berhasil",
//   "data": { ... }
// }
```

### Teacher Check-out
```dart
// Future implementation
final result = await ApiService.teacherCheckOut();
// POST /attendance/teacher/check-out
// Returns: { "status": true, "message": "..." }
```

---

## 📊 Attendance Reports (Guru Features)

### Missing Students
```dart
// Future implementation in guru dashboard
final missing = await ApiService.missingStudents(subjectId);
// GET /attendance/subject/{subjectId}/missing
// Returns:
// {
//   "status": true,
//   "subject": "Matematika",
//   "kelas_id": 1,
//   "summary": {
//     "total": 30,
//     "hadir": 28,
//     "belum_absen": 2
//   },
//   "missing_students": [
//     { "id": 1, "nama": "Budi", "nis": "001" }
//   ]
// }
```

### Student Attendance by Subject (Today)
```dart
// Future implementation
final attendance = await ApiService.studentAttendanceBySubject(subjectId);
// GET /attendance/subject/{subjectId}/today
// Returns:
// {
//   "status": true,
//   "subject": "Matematika",
//   "tanggal": "2024-01-28",
//   "total_absen": 28,
//   "summary": {
//     "hadir": 26,
//     "terlambat": 2
//   },
//   "data": [
//     {
//       "id": 1,
//       "nama": "Budi",
//       "nis": "001",
//       "jam_masuk": "08:00",
//       "status": "hadir",
//       "foto": "...",
//       "latitude": -6.xxx,
//       "longitude": 106.xxx
//     }
//   ]
// }
```

### Attendance Report (Date Range)
```dart
// Future implementation
final report = await ApiService.attendanceReport(
  subjectId: 1,
  startDate: "2024-01-01",
  endDate: "2024-01-31",
);
// GET /attendance/subject/{subjectId}/report?start_date=...&end_date=...
// Returns:
// {
//   "status": true,
//   "subject": "Matematika",
//   "periode": { "start": "2024-01-01", "end": "2024-01-31" },
//   "total_hari": 20,
//   "total_siswa": 30,
//   "statistik": {
//     "hadir": 550,
//     "terlambat": 50,
//     "belum_absen": 50
//   },
//   "report": [
//     {
//       "id": 1,
//       "nama": "Budi",
//       "nis": "001",
//       "attendance": [
//         { "tanggal": "2024-01-01", "jam_masuk": "08:00", "status": "hadir" }
//       ]
//     }
//   ]
// }
```

---

## 📅 Schedule (Future Features)

### Student Schedule
```dart
// Future implementation
final schedule = await ApiService.studentSchedule();
// GET /schedules
// Returns: { "Senin": [...], "Selasa": [...], ... }
```

### Teacher Schedule
```dart
// Future implementation
final schedule = await ApiService.teacherSchedule();
// GET /schedules/teacher
// Returns: { "Senin": [...], "Selasa": [...], ... }
```

### Today Schedule
```dart
// Future implementation
final schedule = await ApiService.todaySchedule();
// GET /schedules/today
// Returns:
// {
//   "status": true,
//   "hari": "Senin",
//   "data": [
//     {
//       "id": 1,
//       "mapel": "Matematika",
//       "guru": "Ibu Sri",  // or "kelas": "10-A" for guru
//       "jam_mulai": "08:00",
//       "jam_selesai": "09:00",
//       "ruangan": "A101"
//     }
//   ]
// }
```

---

## ⚠️ Error Handling

All API methods throw Exception on error. Catch & handle:

```dart
try {
  await ApiService.someMethod();
} catch (e) {
  String message = e.toString().replaceAll('Exception: ', '');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message))
  );
}
```

### Common Error Responses

```json
// 401 - Unauthorized (invalid token)
{ "status": false, "message": "Unauthorized" }

// 403 - Forbidden (outside area / no permission)
{ "status": false, "message": "Di luar area sekolah" }

// 409 - Conflict (already checked in)
{ "status": false, "message": "Sudah absen mapel ini hari ini" }

// 422 - Unprocessable Entity (missing data)
{ "status": false, "message": "Data kelas siswa tidak lengkap" }
```

---

## 🎯 Implementation Checklist

### Pages Status
- [x] login_page.dart - ✅ Complete
- [x] home_page.dart - ✅ Complete
- [x] subject_select_page.dart - ✅ Complete
- [x] location_check_page.dart - ✅ Complete
- [x] autocheckIn_page.dart - ✅ Complete
- [x] presensi_gate_page.dart - ✅ Transit page OK
- [x] profile_page.dart - ✅ Added logout API
- [x] history_page.dart - ✅ Updated to use dashboard
- [ ] camera_page.dart - ⏳ Face registration
- [ ] register_face_page.dart - ⏳ Face registration
- [ ] finger_page.dart - ⏳ Transit page
- [ ] scan_gate_page.dart - ⏳ QR/Scanner (optional)
- [ ] confirm_face_page.dart - ⏳ Confirmation
- [ ] splash_page.dart - ⏳ Init/Boot

### API Methods Status
- [x] login() - ✅
- [x] logout() - ✅ NEW
- [x] profile() - ✅ /me
- [x] dashboard() - ✅
- [x] todayAttendance() - ✅
- [x] subjects() - ✅
- [x] school() - ✅
- [x] faceStatus() - ✅
- [x] registerFace() - ✅
- [x] verifyFace() - ✅
- [x] studentCheckIn() - ✅
- [x] teacherCheckIn() - ✅
- [x] teacherCheckOut() - ✅
- [x] missingStudents() - ✅ (NEW)
- [x] studentAttendanceBySubject() - ✅ (NEW)
- [x] attendanceReport() - ✅ (NEW)
- [x] studentSchedule() - ✅ (NEW, not UI yet)
- [x] teacherSchedule() - ✅ (NEW, not UI yet)
- [x] todaySchedule() - ✅ (NEW, not UI yet)

---

## 🚀 Next Steps

1. **Verify compilation**: `flutter pub get` && `flutter analyze`
2. **Test on device**: Run all flows
3. **Check logs**: Verify API calls in network tab
4. **Error testing**: Try offline, wrong credentials, etc
5. **Deploy**: When all tests pass

---

## 📌 Important Notes

- Base URL: `http://192.168.0.110:8000/api`
- Token stored in SharedPreferences
- All endpoints require auth except `/login`
- Face routes require `face.verified` middleware
- Status codes: 200 (success), 4xx (client error), 5xx (server error)
- Always check `data['status']` before processing response

