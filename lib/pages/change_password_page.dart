import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_config.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  
  bool loading = false;
  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  Future<void> _submit() async {
    if (oldController.text.isEmpty || newController.text.isEmpty || confirmController.text.isEmpty) {
      _error('Harap isi semua kolom');
      return;
    }
    if (newController.text != confirmController.text) {
      _error('Konfirmasi password tidak cocok');
      return;
    }
    if (newController.text.length < 6) {
      _error('Password minimal 6 karakter');
      return;
    }

    setState(() => loading = true);
    try {
      await ApiService.changePassword(
        oldPassword: oldController.text,
        newPassword: newController.text,
        confirmPassword: confirmController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah')),
        );
      }
    } catch (e) {
      _error(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _error(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('GANTI PASSWORD', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
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
            _field('PASSWORD LAMA', oldController, hideOld, () => setState(() => hideOld = !hideOld)),
            const SizedBox(height: 20),
            _field('PASSWORD BARU', newController, hideNew, () => setState(() => hideNew = !hideNew)),
            const SizedBox(height: 20),
            _field('KONFIRMASI PASSWORD BARU', confirmController, hideConfirm, () => setState(() => hideConfirm = !hideConfirm)),
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
                onPressed: loading ? null : _submit,
                child: loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('UBAH PASSWORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, bool hide, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: hide,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: AppConfig.primaryColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(hide ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
              onPressed: onToggle,
            ),
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
