import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  static const String _masterKey = 'my32lengthsupersecretkey1234567890';
  
  static Key get _key => Key.fromUtf8(_masterKey.padRight(32, '0').substring(0, 32));
  
  static IV _generateIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return IV(Uint8List.fromList(ivBytes));
  }

  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final iv = _generateIV();
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final ivBase64 = base64.encode(iv.bytes);
    return '$ivBase64:${encrypted.base64}';
  }

  static String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    final parts = cipherText.split(':');
    if (parts.length != 2) return '';
    
    final ivBytes = base64.decode(parts[0]);
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(parts[1]), iv: iv);
    return decrypted;
  }
}