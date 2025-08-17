import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';

class PasswordRepository {
  PasswordRepository._internal();
  static final PasswordRepository instance = PasswordRepository._internal();

  static const String _fileName = 'passwords.enc';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<bool> exists() async {
    final f = await _getFile();
    return f.existsSync();
    
  }

  Future<void> saveRaw(List<Map<String, dynamic>> groups) async {
    final key = AuthService.instance.key;
    if (key == null) {
      throw StateError('Auth key is not available. Ensure user is authenticated.');
    }

    final payload = jsonEncode({'groups': groups});

    final algorithm = AesGcm.with256bits();
    final nonce = _randomBytes(12);
    final secretKey = SecretKey(key);

    final secretBox = await algorithm.encrypt(
      utf8.encode(payload),
      secretKey: secretKey,
      nonce: nonce,
    );

    final envelope = <String, dynamic>{
      'version': 1,
      'cipher': 'aes-256-gcm',
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    final file = await _getFile();
    await file.writeAsString(jsonEncode(envelope), flush: true);
  }

  Future<List<Map<String, dynamic>>?> loadRaw() async {
    final key = AuthService.instance.key;
    if (key == null) {
      throw StateError('Auth key is not available. Ensure user is authenticated.');
    }

    final file = await _getFile();
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;

    final map = jsonDecode(content) as Map<String, dynamic>;
    if (!(map.containsKey('cipher') && map.containsKey('ciphertext'))) {
      // Backward/unsupported format
      return null;
    }

    final nonce = base64Decode((map['nonce'] ?? '') as String);
    final ciphertext = base64Decode((map['ciphertext'] ?? '') as String);
    final macBytes = base64Decode((map['mac'] ?? '') as String);

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(key);
    final box = SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes));

    final decrypted = await algorithm.decrypt(box, secretKey: secretKey);
    final jsonMap = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;

    final groups = (jsonMap['groups'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return groups;
  }

  static Uint8List _randomBytes(int length) {
    final rnd = SecureRandom();
    return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
  }
}

// Simple secure random fallback using Dart Random.secure if cryptography's random isn't exposed
class SecureRandom {
  final _rng = Random.secure();
  int nextInt(int max) => _rng.nextInt(max);
}
