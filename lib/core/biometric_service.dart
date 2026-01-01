import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      // 1. Cek device support biometric
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        return false;
      }

      // 2. Cek fingerprint sudah terdaftar
      final available = await _auth.getAvailableBiometrics();
      if (available.isEmpty) {
        return false;
      }

      // 3. Authenticate
      return await _auth.authenticate(
        localizedReason: 'Scan fingerprint untuk melanjutkan',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true, 
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
