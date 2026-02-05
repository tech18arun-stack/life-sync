import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication auth = LocalAuthentication();
  static const String _appLockKey = 'app_lock_enabled';
  static const String _biometricKey = 'biometric_enabled';

  bool _isAppLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isInitialized = false;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isAppLockEnabled = prefs.getBool(_appLockKey) ?? false;
      _isBiometricEnabled = prefs.getBool(_biometricKey) ?? false;
      _isInitialized = true;
    } catch (e) {
      debugPrint('SecurityService init error: $e');
      _isInitialized = true;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setAppLock(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_appLockKey, enabled);
      _isAppLockEnabled = enabled;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setBiometric(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricKey, enabled);
      _isBiometricEnabled = enabled;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    // If app lock is not enabled, always allow
    if (!_isAppLockEnabled) return true;

    // Skip on web
    if (kIsWeb) return true;

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Device doesn't support authentication, allow access
        return true;
      }

      return await auth.authenticate(
        localizedReason: 'Please authenticate to access LifeSync',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      // On error, allow access to prevent lockout
      return true;
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      return true;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }
}
