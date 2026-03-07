import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      if (!await canAuthenticate()) return false;
      
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
