import 'package:flutter/material.dart';
import '../core/auth_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthStorage.getUser();
    setState(() {
      profile = user?['profile'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A5DBA),

      // ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A5DBA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          _header(),

          // ================= BODY =================
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionTitle('Data Pegawai'),
                      _row('Instansi', profile?['instansi'] ?? '-'),
                      _row('Jabatan / Kelas', profile?['jabatan_kelas'] ?? '-'),
                      _row('NIP / NIS', profile?['nip_nis'] ?? '-'),

                      const Divider(height: 36),

                      _sectionTitle('Pusat Bantuan'),
                      _menu('Bantuan'),
                      _menu('Laporkan Masalah'),

                      const Divider(height: 36),

                      _sectionTitle('Pengaturan'),
                      _menu('Bahasa', trailing: 'Indonesia'),
                      _menu('Atur Ulang Kata Sandi'),
                      _menu('Versi Aplikasi', trailing: 'v2.3.0'),

                      const SizedBox(height: 120),
                    ],
                  ),

                  // ================= LOGOUT =================
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          await AuthStorage.logout();
                          Navigator.popUntil(context, (r) => r.isFirst);
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: profile?['foto'] != null
                ? NetworkImage(profile!['foto'])
                : const AssetImage('assets/images/profile.png')
                    as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            profile?['nama_lengkap'] ?? '-',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?['nip_nis'] ?? '-',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            profile?['jabatan_kelas'] ?? '-',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ================= COMPONENT =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _menu(String title, {String? trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: trailing != null
          ? Text(
              trailing,
              style: const TextStyle(color: Colors.green),
            )
          : const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
