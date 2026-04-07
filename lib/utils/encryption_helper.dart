import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  // In production, derive this from user's PIN using PBKDF2
  static const String _masterKey = 'my32lengthsupersecretkey1234567890';
  
  static Key get _key => Key.fromUtf8(_masterKey.padRight(32, '0').substring(0, 32));
  
  static IV _generateIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return IV.fromUtf8(utf8.decode(ivBytes));
  }

  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final iv = _generateIV();
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Prepend IV to encrypted text for decryption
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    final parts = cipherText.split(':');
    if (parts.length != 2) return '';
    
    final ivBytes = base64Decode(parts[0]);
    final iv = IV(ivBytes);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(parts[1]), iv: iv);
    return decrypted;
  }

  // Derive key from PIN (for additional security)
  static String deriveKeyFromPin(String pin, String salt) {
    final input = '$pin:$salt';
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 32);
  }
}