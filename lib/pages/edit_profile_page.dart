import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/auth_storage.dart';
import '../core/app_config.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController nipController;
  late TextEditingController jabatanController;
  late TextEditingController instansiController;
  
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile['nama_lengkap']);
    nipController = TextEditingController(text: widget.profile['nip_nis']);
    jabatanController = TextEditingController(text: widget.profile['jabatan_kelas']);
    instansiController = TextEditingController(text: widget.profile['instansi']);
  }

  Future<void> _save() async {
    if (nameController.text.isEmpty || nipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan NIP/NIS tidak boleh kosong')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await ApiService.updateProfile(
        name: nameController.text.trim(),
        nip: nipController.text.trim(),
        jabatan: jabatanController.text.trim(),
        instansi: instansiController.text.trim(),
      );
      
      // Refresh local user data
      await ApiService.profile();
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('EDIT PROFIL', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _inputField('NAMA LENGKAP', nameController, Icons.person_outline),
            const SizedBox(height: 20),
            _inputField('NIP / NIS', nipController, Icons.badge_outlined),
            const SizedBox(height: 20),
            _inputField('JABATAN / KELAS', jabatanController, Icons.class_outlined),
            const SizedBox(height: 20),
            _inputField('INSTANSI', instansiController, Icons.school_outlined),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: loading ? null : _save,
                child: loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF5E5CE6), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
