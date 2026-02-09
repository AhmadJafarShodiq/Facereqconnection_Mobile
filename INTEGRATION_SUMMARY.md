# Summary: API Service & Pages Integration

## ✅ Selesai! Semua pages sudah disesuaikan dengan backend API

---

## File yang Diupdate

### 1. **lib/core/api_service.dart** (399 lines)
- ✅ Fixed `/me` endpoint untuk profile
- ✅ Added `logout()` method
- ✅ Added schedule endpoints (studentSchedule, teacherSchedule, todaySchedule)
- ✅ Updated attendance endpoints sesuai backend
- ✅ Added missing students, student attendance by subject, attendance report
- ✅ Removed `getHistory()` endpoint (gunakan dashboard)

### 2. **lib/pages/profile_page.dart**
- ✅ Added logout API call sebelum clear storage
- ✅ Added fallback ke AuthStorage.logout() jika API error

### 3. **lib/pages/history_page.dart**
- ✅ Changed dari `ApiService.getHistory()` ke `ApiService.dashboard()`
- ✅ Extract history dari dashboard response
- ✅ Updated field mapping: `tanggal`, `jam`, `status`

### Semua Pages Lainnya
- ✅ login_page.dart - sudah benar
- ✅ home_page.dart - sudah benar (dashboard loading)
- ✅ subject_select_page.dart - sudah benar (subjects loading)
- ✅ autocheckIn_page.dart - sudah benar (student/teacher check-in)
- ✅ location_check_page.dart - sudah benar (school validation)
- ✅ presensi_gate_page.dart - transit page (sudah benar)

---

## Flow Diagram

```
┌─────────────────────────────────────┐
│        LOGIN_PAGE.dart              │
│  - username/password                │
│  - ApiService.login()               │
│  - Check faceStatus()               │
└──────────────┬──────────────────────┘
               │
        ┌──────▼──────┐
        │ Face exist? │
        └──────┬──────┘
         No  /  \  Yes
           /      \
    ┌─────▼─┐    ┌─▼──────────────┐
    │REGISTER│   │ FINGER_PAGE    │
    │ FACE   │   │ (transit)      │
    └─────┬──┘   └─┬──────────────┘
          │        │
          └────┬───┘
               │
         ┌─────▼──────────────────┐
         │  HOME_PAGE.dart        │
         │ - Dashboard (API)      │
         │ - Today attendance     │
         │ - Profile/History/etc  │
         └─────┬──────────────────┘
               │
        ┌──────▼───────┐
        │ SUBJECT_PAGE │  (if siswa)
        │ ApiService.  │
        │ subjects()   │
        └──────┬───────┘
               │
         ┌─────▼─────────────┐
         │ LOCATION_PAGE     │
         │ - Get school data │
         │ - Validate area   │
         └─────┬─────────────┘
               │
         ┌─────▼──────────────┐
         │ AUTO_CHECKIN_PAGE  │
         │ - Verify face      │
         │ - Student/Teacher  │
         │ - Check-in API     │
         └────────┬───────────┘
                  │
         ┌────────▼─────────┐
         │ SUCCESS/ERROR    │
         │ Pop + Refresh    │
         └──────────────────┘

PROFILE_PAGE (Tab 0)
  │
  ├─ User info (from AuthStorage)
  ├─ Settings
  └─ Logout
     └─ ApiService.logout()
        └─ Clear token + AuthStorage
           └─ Navigate to LoginPage

HISTORY_PAGE (Tab 2)
  │
  └─ ApiService.dashboard()
     └─ Extract history[]
        └─ Display as list
```

---

## API Response Examples

### Dashboard (Siswa)
```json
{
  "role": "siswa",
  "nama": "Budi Santoso",
  "summary": {
    "hadir": 15,
    "terlambat": 2
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

### Dashboard (Guru)
```json
{
  "role": "guru",
  "nama": "Ibu Sri",
  "presensi": {
    "masuk": true,
    "pulang": false
  }
}
```

### Today Attendance
```json
{
  "check_in_time": "08:05",
  "is_late": false,
  "late_minutes": 0,
  "subject": "Matematika"
}
```

### Student Check-in Success
```json
{
  "status": true,
  "message": "Presensi berhasil",
  "data": {
    "nama": "Budi Santoso",
    "kelas": "10-A",
    "mapel": "Matematika",
    "jam": "08:00",
    "status": "hadir",
    "foto": "absensi/xyz.jpg",
    "lat": -6.1234,
    "lng": 106.5678
  }
}
```

### School Data
```json
{
  "id": 1,
  "nama_sekolah": "SMKN 1 Tamananan",
  "latitude": "-6.xxx",
  "longitude": "106.xxx",
  "radius": 100
}
```

---

## Error Handling Examples

### Location Outside Area (403)
```json
{
  "status": false,
  "message": "Di luar area sekolah"
}
```

### Already Checked In (409)
```json
{
  "status": false,
  "message": "Sudah absen mapel ini hari ini"
}
```

### Profile Incomplete (422)
```json
{
  "status": false,
  "message": "Data kelas siswa tidak lengkap"
}
```

### Unauthorized (401)
```json
{
  "status": false,
  "message": "Unauthorized"
}
```

---

## Key Implementation Details

### 1. Face Verification Flow
```
1. Capture photo dari camera
2. Get embedding dari native code
3. POST /face/verify dengan embedding
4. Jika success → proceed ke check-in
5. Jika fail → show error, retry atau back
```

### 2. Check-in Flow (Student)
```
1. Select subject dari list
2. Validate location (in area?)
3. Verify face
4. POST /attendance/student dengan:
   - subject_id
   - latitude, longitude
   - foto (multipart)
5. Jika success → show attendance data
6. Pop dan refresh home
```

### 3. Check-in Flow (Teacher)
```
1. POST /attendance/teacher/check-in dengan:
   - latitude, longitude
2. Status otomatis dari backend (hadir/terlambat)
3. Pop dan return
```

### 4. Logout Flow
```
1. POST /logout (delete token di backend)
2. Catch error → fallback ke AuthStorage.logout()
3. Clear token & user dari SharedPreferences
4. Navigate ke LoginPage dengan removeUntil
```

### 5. Dashboard Loading
```
1. GET /dashboard
2. Extract summary, history
3. Siswa: render hadir/terlambat cards
4. Guru: render masuk/pulang status
5. Semua: render history dalam ListView
```

---

## Status Codes & Error Handling

| Code | Scenario | Action |
|------|----------|--------|
| 200 | Success | Extract `data['data']` atau `data['message']` |
| 401 | Token invalid | Clear storage → navigate ke LoginPage |
| 403 | No permission / outside area | Show error message, allow retry |
| 409 | Already checked in | Show conflict message |
| 422 | Incomplete profile | Show "Data tidak lengkap" |
| 500+ | Server error | Show error message |

---

## Testing Checklist

### Auth Flow
- [ ] Login dengan valid credentials
- [ ] Login dengan invalid credentials (error)
- [ ] Face registration → verify → check-in
- [ ] Logout & clear storage
- [ ] Token persistence (restart app)

### Student Flow
- [ ] Get subjects dari API
- [ ] Location validation (inside area)
- [ ] Location validation (outside area - reject)
- [ ] Face verification (match - success)
- [ ] Face verification (no match - retry)
- [ ] Student check-in dengan foto
- [ ] Error: sudah absen mapel ini
- [ ] Dashboard update after check-in
- [ ] History page dengan data dari dashboard

### Teacher Flow
- [ ] Teacher check-in
- [ ] Teacher check-out
- [ ] Dashboard show masuk/pulang status
- [ ] View missing students (if implemented)
- [ ] View attendance by subject (if implemented)

### Data Validation
- [ ] Profile data lengkap
- [ ] School location valid
- [ ] Distance calculation correct
- [ ] Timestamp format consistent (H:i)
- [ ] Image upload multipart correct

---

## Future Enhancements (Not Yet Implemented)

1. **Teacher Features**:
   - [ ] View missing students per subject
   - [ ] View attendance by subject (today)
   - [ ] Generate attendance report (date range)
   - [ ] Teacher check-out UI

2. **Schedule Features**:
   - [ ] Student view jadwal per hari
   - [ ] Teacher view jadwal mengajar
   - [ ] Today schedule real-time

3. **Advanced Features**:
   - [ ] Multiple role support (siswa+guru)
   - [ ] Offline mode dengan sync
   - [ ] QR code attendance
   - [ ] Biometric (fingerprint) as backup

---

## Performance Notes

1. **Image Optimization**:
   - Resize foto sebelum upload
   - Compress ke JPEG format
   - Max size: ~2MB per image

2. **API Calls**:
   - Cache school data (30 min)
   - Cache subjects (daily)
   - Dashboard refresh: manual + pull-to-refresh

3. **Location Service**:
   - Turn off GPS setelah check-in
   - Cleanup resources di dispose()
   - Request permission sesuai platform

4. **Face Recognition**:
   - Embedding size: 512-dim vector
   - Processing time: <2 seconds
   - Liveness detection: optional tapi recommended

---

## Notes untuk Development

1. **Environment**:
   - Base URL: `http://192.168.0.110:8000/api`
   - Adjust untuk production

2. **Debugging**:
   - Enable logging di ApiService untuk see requests/responses
   - Use VS Code Network tab untuk monitor API calls
   - Check SharedPreferences untuk token validation

3. **Security**:
   - Never log sensitive data (password, token)
   - Use HTTPS untuk production
   - Implement token refresh jika diperlukan

4. **Data Formats**:
   - Tanggal: "YYYY-MM-DD"
   - Waktu: "HH:mm" atau "HH:mm:ss"
   - Koordinat: float (lat, lng)
   - Jarak: meter
