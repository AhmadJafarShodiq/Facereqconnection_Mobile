import 'package:facereq_mobile/pages/login_page.dart';
import 'package:flutter/material.dart';
import '../core/auth_storage.dart';
import '../core/api_service.dart';

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
    setState(() => profile = user?['profile']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          _header(),
          _content(),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 40),
      alignment: Alignment.topCenter,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 40,
              backgroundImage: profile?['foto'] != null
                  ? NetworkImage(profile!['foto'])
                  : const AssetImage('assets/images/profile.png')
                      as ImageProvider,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile?['nama_lengkap'] ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?['jabatan_kelas'] ?? '-',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT =================
  Widget _content() {
    return Container(
      margin: const EdgeInsets.only(top: 210),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ListView(
        children: [
          _infoCard(),
          const SizedBox(height: 16),
          _menuCard(),
          const SizedBox(height: 24),
          _logoutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ================= INFO CARD =================
  Widget _infoCard() {
    return _card(
      child: Column(
        children: [
          _row('Instansi', profile?['instansi'] ?? '-'),
          _divider(),
          _row('Jabatan / Kelas', profile?['jabatan_kelas'] ?? '-'),
          _divider(),
          _row('NIP / NIS', profile?['nip_nis'] ?? '-'),
        ],
      ),
    );
  }

  // ================= MENU CARD =================
  Widget _menuCard() {
    return _card(
      child: Column(
        children: [
          _menu(Icons.help_outline, 'Bantuan'),
          _menu(Icons.report_problem_outlined, 'Laporkan Masalah'),
          _divider(),
          _menu(Icons.language, 'Bahasa', trailing: 'Indonesia'),
          _menu(Icons.lock_outline, 'Ubah Kata Sandi'),
          _menu(Icons.info_outline, 'Versi Aplikasi', trailing: 'v2.3.0'),
        ],
      ),
    );
  }

  // ================= LOGOUT =================
  Widget _logoutButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Keluar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () async {
        try {
          await ApiService.logout();
        } catch (_) {
          await AuthStorage.logout();
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      },
    );
  }

  // ================= COMPONENT =================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(IconData icon, String title, {String? trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF1E88E5)),
      title: Text(title),
      trailing: trailing != null
          ? Text(trailing, style: const TextStyle(color: Color(0xFF1E88E5)))
          : const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: Color(0xFFE0E0E0));
  }
}
