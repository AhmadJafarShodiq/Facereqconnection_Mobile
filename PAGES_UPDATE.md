# Pages Update - Sesuai dengan Backend API

## Ringkasan Perubahan Per Page

### 1. **login_page.dart** ✅
**Status**: Sudah benar, tidak perlu update
- Login endpoint: `/login` (sudah benar)
- Register face check: `faceStatus()` (sudah ada)
- Navigation ke FingerPage untuk lanjut ke verifikasi

### 2. **home_page.dart** ✅
**Status**: Sudah benar, tidak perlu update
- Dashboard endpoint: `ApiService.dashboard()`
  - Ambil attendance hari ini dari response
  - Ambil history dari dashboard (max 5 items)
- Today attendance: `ApiService.todayAttendance()`
  - Check status presensi hari ini
  - Status: check_in_time, is_late, late_minutes, subject

**Response Dashboard (Siswa)**:
```json
{
  "role": "siswa",
  "nama": "Nama Siswa",
  "summary": {
    "hadir": 0,
    "terlambat": 0
  },
  "history": [
    {
      "mapel": "Matematika",
      "jam": "08:00",
      "status": "hadir"
    }
  ]
}
```

### 3. **profile_page.dart** ✅
**Status**: UPDATED
- **Logout flow**:
  1. Call `ApiService.logout()` (DELETE token ke backend)
  2. Fallback ke `AuthStorage.logout()` jika API error
  3. Navigate ke LoginPage dengan removeUntil
  
```dart
try {
  await ApiService.logout();  // NEW
} catch (e) {
  print('Logout API error: $e');
  await AuthStorage.logout();
}
```

### 4. **history_page.dart** ✅
**Status**: UPDATED
- **Perubahan**: `ApiService.getHistory()` sudah dihapus, gunakan dashboard
- **Solusi**: 
  - Call `ApiService.dashboard()` 
  - Extract `history` dari response
  - Loop history untuk display riwayat

```dart
// OLD:
_historyFuture = ApiService.getHistory();

// NEW:
_dashboardFuture = ApiService.dashboard();
// Get history from dashboard response
history = dashboard['history'];
```

**History Item Format**:
```json
{
  "mapel": "Matematika",
  "jam": "08:00",     // jam_masuk format H:i
  "status": "hadir"   // atau "terlambat"
}
```

### 5. **subject_select_page.dart** ✅
**Status**: Sudah benar, tidak perlu update
- Get subjects: `ApiService.subjects()`
- Response: List dengan `id` dan `nama_mapel`
- Kirim ke PresensiGatePage dengan role dan subjectId

```json
[
  {
    "id": 1,
    "nama_mapel": "Matematika"
  }
]
```

### 6. **location_check_page.dart** ✅
**Status**: Sudah benar, tidak perlu update
- Get school data: `ApiService.school()`
- Hitung jarak: menggunakan Haversine formula
- Validasi: jika distance > radius → reject
- Navigate ke CameraPage jika valid

**School Response**:
```json
{
  "id": 1,
  "nama_sekolah": "SMKN 1 Tamananan",
  "latitude": "-6.xxx",
  "longitude": "106.xxx",
  "radius": 100  // meter
}
```

### 7. **presensi_gate_page.dart** ✅
**Status**: Sudah benar, tidak perlu update
- Transit page ke LocationPage
- Pass role dan subjectId
- Handle result dari LocationPage (true = berhasil)

### 8. **autocheckIn_page.dart** ✅
**Status**: Sudah benar, sudah menggunakan API yang benar
- Face verification: `ApiService.verifyFace(embedding)`
- Student check-in: `ApiService.studentCheckIn(subjectId, lat, lng, foto)`
- Teacher check-in: `ApiService.teacherCheckIn(lat, lng)`
- Handle success → pop dengan success message

**Student Check-in Response**:
```json
{
  "status": true,
  "message": "Presensi berhasil",
  "data": {
    "nama": "Nama Siswa",
    "kelas": 1,
    "mapel": "Matematika",
    "jam": "08:00",
    "status": "hadir",
    "foto": "path/foto.jpg",
    "lat": -6.xxx,
    "lng": 106.xxx
  }
}
```

**Teacher Check-in Response**:
```json
{
  "status": true,
  "message": "Presensi masuk berhasil",
  "data": {
    "user_id": 1,
    "role": "guru",
    "tanggal": "2024-01-28",
    "jam_masuk": "2024-01-28 08:00:00",
    "status": "hadir"
  }
}
```

### 9. **camera_page.dart** 
**Status**: Perlu dicek (biasanya untuk register face)
- Lokasi: lib/pages/camera_page.dart

### 10. **register_face_page.dart**
**Status**: Face registration
- Register embedding: `ApiService.registerFace(embedding)`
- Verify face: `ApiService.verifyFace(embedding)`
- Navigate sesuai hasil

### 11. **finger_page.dart**
**Status**: Transit/gatekeeper page (biasanya ke subject select)

### 12. **scan_gate_page.dart**
**Status**: QR/Scanner page (jika ada)

### 13. **confirm_face_page.dart**
**Status**: Confirm/retry face page

### 14. **splash_page.dart**
**Status**: Init page (biasanya check token)

### 15. **summary_page.dart**
**Status**: Summary setelah absen berhasil

---

## API Endpoints Summary

| Method | Endpoint | Page |
|--------|----------|------|
| POST | `/login` | login_page.dart |
| POST | `/logout` | profile_page.dart |
| GET | `/me` | - |
| GET | `/dashboard` | home_page.dart, history_page.dart |
| GET | `/attendance/today` | home_page.dart |
| GET | `/subjects` | subject_select_page.dart |
| GET | `/school` | location_check_page.dart |
| GET | `/face/status` | login_page.dart, home_page.dart |
| POST | `/face/register` | register_face_page.dart |
| POST | `/face/verify` | autocheckIn_page.dart |
| POST | `/attendance/student` | autocheckIn_page.dart |
| POST | `/attendance/teacher/check-in` | autocheckIn_page.dart |
| POST | `/attendance/teacher/check-out` | - |
| GET | `/attendance/subject/{id}/missing` | - (guru feature) |
| GET | `/attendance/subject/{id}/today` | - (guru feature) |
| GET | `/attendance/subject/{id}/report` | - (guru feature) |
| GET | `/schedules` | - (future feature) |
| GET | `/schedules/teacher` | - (future feature) |
| GET | `/schedules/today` | - (future feature) |

---

## Testing Checklist

- [ ] Login dengan credentials yang valid
- [ ] Face registration & verification flow
- [ ] Student check-in dengan foto & lokasi
- [ ] Teacher check-in/check-out
- [ ] Dashboard loading dengan history
- [ ] Profile page & logout flow
- [ ] Location validation (dalam/luar radius)
- [ ] Error handling untuk offline/network issues

---

## Notes

1. **Dashboard Response Structure**:
   - Siswa: `role`, `nama`, `summary`, `history`
   - Guru: `role`, `nama`, `presensi`

2. **Status Codes**:
   - 200: Success
   - 401: Unauthorized (token invalid)
   - 403: Forbidden (no permission / outside area)
   - 409: Conflict (sudah absen)
   - 422: Unprocessable (data tidak lengkap)

3. **Error Messages** (dari backend):
   - Ambil dari `data['message']`
   - Custom error handling di catch block

4. **Future Features** (belum diimplementasikan UI):
   - Schedule endpoints (siswa/guru)
   - Attendance report (guru)
   - Missing students (guru)
   - Teacher check-out page
