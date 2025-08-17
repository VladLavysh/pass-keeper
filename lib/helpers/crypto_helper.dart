import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class CryptoHelper {
  static const int _pbkdf2Iterations = 150000; // ~150k iterations
  static const int _saltLength = 16; // 128-bit salt
  static const int _nonceLength = 12; // 96-bit nonce for AES-GCM

  static final _rng = Random.secure();

  static Future<String> encryptString({
    required String plaintext,
    required String passphrase,
  }) async {
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);

    final secretKey = await _deriveKey(passphrase: passphrase, salt: salt);
    final algorithm = AesGcm.with256bits();

    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    final envelope = {
      'version': 1,
      'kdf': 'pbkdf2-hmac-sha256',
      'rounds': _pbkdf2Iterations,
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  static Future<String> decryptString({
    required String encryptedEnvelopeJson,
    required String passphrase,
  }) async {
    final map = json.decode(encryptedEnvelopeJson) as Map<String, dynamic>;

    final salt = base64Decode((map['salt'] ?? '') as String);
    final nonce = base64Decode((map['nonce'] ?? '') as String);
    final ciphertext = base64Decode((map['ciphertext'] ?? '') as String);
    final macBytes = base64Decode((map['mac'] ?? '') as String);

    final secretKey = await _deriveKey(passphrase: passphrase, salt: salt);
    final algorithm = AesGcm.with256bits();

    final box = SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes));
    final decryptedBytes = await algorithm.decrypt(
      box,
      secretKey: secretKey,
    );
    return utf8.decode(decryptedBytes);
  }

  static Future<SecretKey> _deriveKey({
    required String passphrase,
    required List<int> salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  static List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _rng.nextInt(256));
  }
}
