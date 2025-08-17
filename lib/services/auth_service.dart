import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyStorageKey = 'encryption_key_v1';

  // Cached key in memory after successful auth
  Uint8List? _cachedKey;

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    // Allow biometrics OR device credentials in one prompt.
    try {
      final bool didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock your passwords',
        options: const AuthenticationOptions(
          biometricOnly: false, // allows device PIN/password fallback
          useErrorDialogs: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      if (didAuth) {
        await _ensureKeyLoaded();
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> lock() async {
    _cachedKey = null;
  }

  bool get isUnlocked => _cachedKey != null;

  Uint8List? get key => _cachedKey;

  Future<void> _ensureKeyLoaded() async {
    if (_cachedKey != null) return;

    String? base64Key = await _secureStorage.read(key: _keyStorageKey);
    if (base64Key == null) {
      // Generate a new 256-bit random key and store securely.
      final key = _randomBytes(32);
      base64Key = _encodeBase64(key);
      await _secureStorage.write(key: _keyStorageKey, value: base64Key);
    }
    _cachedKey = _decodeBase64(base64Key);
  }

  // Helpers
  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  static String _encodeBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Uint8List _decodeBase64(String s) {
    return Uint8List.fromList(base64Decode(s));
  }
}
