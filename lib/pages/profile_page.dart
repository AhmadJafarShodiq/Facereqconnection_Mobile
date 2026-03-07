import 'package:facereq_mobile/pages/login_page.dart';
import 'package:facereq_mobile/pages/edit_profile_page.dart';
import 'package:facereq_mobile/pages/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/auth_storage.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthStorage.getUser();
    if (mounted) {
      setState(() {
        profile = user?['profile'];
        loading = false;
      });
    }
    
    // Sync with server
    try {
      final fresh = await ApiService.profile();
      if (mounted) {
        setState(() => profile = fresh['profile']);
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengupload foto...'), duration: Duration(seconds: 1)),
    );

    try {
      final bytes = await File(image.path).readAsBytes();
      final newUrl = await ApiService.updatePhoto(bytes);
      
      // Update local storage
      await ApiService.profile();
      
      if (mounted) {
        setState(() => profile!['foto_url'] = newUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppConfig.primaryColor)),
      );
    }

    final name = profile?['nama_lengkap'] ?? '-';
    final role = profile?['jabatan_kelas'] ?? 'USER';
    final nip = profile?['nip_nis'] ?? '-';
    final fotoUrl = profile?['foto_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(name, role, fotoUrl),
            const SizedBox(height: 24),
            _infoCard(nip),
            const SizedBox(height: 24),
            _menuCard(),
            const SizedBox(height: 40),
            _logoutButton(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(String name, String role, String? fotoUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.primaryColor, AppConfig.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) 
                      ? NetworkImage(fotoUrl) 
                      : null,
                  child: (fotoUrl == null || fotoUrl.isEmpty) 
                      ? Icon(Icons.person, size: 50, color: AppConfig.primaryColor)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, size: 18, color: AppConfig.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ================= INFO CARD =================
  Widget _infoCard(String nip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.school_outlined, 'INSTANSI', profile?['instansi'] ?? 'SMK Negeri 1 Tamananan'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _infoRow(Icons.badge_outlined, 'NIP / NIS', nip),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppConfig.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= MENU CARD =================
  Widget _menuCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _menuItem(Icons.edit_outlined, 'Edit Profil', () async {
            if (profile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data profil belum dimuat')),
              );
              return;
            }
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile!))
            );
            if (ok == true) _loadProfile();
          }),
          _menuItem(Icons.lock_outline, 'Ganti Password', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage())
            );
          }),
          _menuItem(Icons.help_outline, 'Pusat Bantuan', () {}),
          _menuItem(Icons.info_outline, 'Tentang Aplikasi', () {}),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppConfig.primaryColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  // ================= LOGOUT =================
  Widget _logoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Color(0xFFFEE2E2)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          try {
            await ApiService.logout();
          } catch (_) {}
          
          await AuthStorage.clear();
          
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18),
            SizedBox(width: 8),
            Text('KELUAR DARI AKUN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
