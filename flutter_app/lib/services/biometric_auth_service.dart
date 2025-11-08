import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsulates biometric + secure storage interactions so the UI
/// can stay focused on rendering.
class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricSessionKey = 'biometric_session';
  static const _biometricEmailKey = 'biometric_email';

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      return (canCheck || supported) && biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> enableForSession({
    required Session session,
    required String email,
  }) async {
    final payload = jsonEncode(session.toJson());
    await _secureStorage.write(key: _biometricSessionKey, value: payload);
    await _secureStorage.write(
      key: _biometricEmailKey,
      value: email,
    );
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }

  Future<void> refreshStoredSession(Session session, String email) async {
    if (!await isBiometricEnabled()) return;
    await enableForSession(session: session, email: email);
  }

  Future<String?> savedSessionString() {
    return _secureStorage.read(key: _biometricSessionKey);
  }

  Future<String?> savedEmail() {
    return _secureStorage.read(key: _biometricEmailKey);
  }

  Future<void> disableBiometrics() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _biometricSessionKey);
    await _secureStorage.delete(key: _biometricEmailKey);
  }
}
