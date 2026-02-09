# API Service Updates - Sesuai Backend Laravel

## Perubahan yang Dilakukan pada `api_service.dart`

### 1. **Authentication & Profile**
- ✅ **Profile Endpoint**: Diubah dari `/profile` → `/me`
- ✅ **Logout**: Menambahkan method `logout()` dengan clear token & user
- ✅ Response handling untuk status validation

### 2. **Attendance Endpoints**

#### Student Check-in
```dart
studentCheckIn({
  required int subjectId,
  required double latitude,
  required double longitude,
  Uint8List? photoBytes,
})
```
- Upload foto dengan multipart form
- Validasi subject sesuai kelas siswa
- Return attendance data dengan mapel, jam, status

#### Teacher Check-in/Check-out
```dart
teacherCheckIn({
  required double latitude,
  required double longitude,
})

teacherCheckOut()
```
- Location validation
- Status otomatis: hadir/terlambat (jam 8:15)

#### Missing Students (Guru)
```dart
missingStudents(int subjectId)
```
- Endpoint: `/attendance/subject/{subjectId}/missing`
- Return: missing_students list, summary (total, hadir, belum_absen)

#### Student Attendance by Subject
```dart
studentAttendanceBySubject(int subjectId)
```
- Endpoint: `/attendance/subject/{subjectId}/today`
- Return: attendance list per mapel hari ini

#### Attendance Report
```dart
attendanceReport({
  required int subjectId,
  required String startDate,
  required String endDate,
})
```
- Endpoint: `/attendance/subject/{subjectId}/report`
- Query params: start_date, end_date
- Return: report per siswa dengan statistik

### 3. **Schedule Endpoints** (BARU)
```dart
studentSchedule()        // /schedules
teacherSchedule()        // /schedules/teacher
todaySchedule()          // /schedules/today
```
- Grouped by hari (Senin, Selasa, dst)
- Include guru, mapel, jam, ruangan

### 4. **School & Today Attendance**
```dart
school()              // /school (unchanged)
todayAttendance()     // /attendance/today (unchanged)
```

### 5. **Subject**
```dart
subjects()  // /subjects - unchanged
```

### 6. **Removed Endpoints**
- ❌ `getHistory()` - tidak ada di backend
- Gunakan `dashboard()` untuk history alternative

## Response Structure

### Login Response
```json
{
  "status": true,
  "message": "Login berhasil",
  "token": "xxx",
  "data": {
    "id": 1,
    "username": "user",
    "role": "siswa|guru",
    "profile": {...}
  }
}
```

### Attendance Response
```json
{
  "status": true,
  "message": "Presensi berhasil",
  "data": {
    "nama": "Nama Siswa",
    "kelas": 1,
    "mapel": "Matematika",
    "jam": "08:00",
    "status": "hadir|terlambat",
    "foto": "path/to/foto",
    "lat": -6.xxx,
    "lng": 106.xxx
  }
}
```

### Schedule Response
```json
{
  "status": true,
  "data": {
    "Senin": [
      {
        "id": 1,
        "mapel": "Matematika",
        "guru": "Nama Guru",
        "jam_mulai": "08:00",
        "jam_selesai": "09:00",
        "ruangan": "A101"
      }
    ],
    "Selasa": [...]
  }
}
```

## Error Handling

Semua endpoint sudah handle:
- ✅ Status code 200, 401, 403, 409, 422
- ✅ Status field validation (status == true)
- ✅ Custom error messages dari backend
- ✅ Exception throwing untuk error handling di UI

## Testing Checklist

- [ ] Login dengan username/password yang valid
- [ ] Profile load dengan /me endpoint
- [ ] Logout clear token & user
- [ ] Student check-in dengan foto
- [ ] Teacher check-in/check-out
- [ ] Get schedule untuk siswa dan guru
- [ ] Get today attendance
- [ ] Missing students (guru view)
- [ ] Attendance report dengan date range

## Notes

1. **Base URL**: `http://192.168.0.110:8000/api`
   - Sesuaikan IP dengan server Laravel Anda

2. **Token**: Menggunakan Laravel Sanctum
   - Token disimpan di SharedPreferences via AuthStorage
   - Otomatis attach ke header: `Authorization: Bearer {token}`

3. **Middleware Required**:
   - `auth:sanctum` - untuk endpoint yang butuh login
   - `face.verified` - untuk attendance endpoints

4. **Face Recognition**:
   - Register face: `/face/register`
   - Verify face: `/face/verify`
   - Get status: `/face/status`
   - Semua sudah ada di code, tinggal integrate dengan camera

5. **Location Validation**:
   - Backend validasi jarak dari sekolah
   - Gunakan Geolocator plugin untuk get lat/lng
