import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _notesKey = 'encrypted_notes';
  static const String _pinHashKey = 'pin_hash';
  static const String _themeKey = 'theme_mode';
  static const String _lastActivityKey = 'last_activity';

  // Notes storage
  static Future<void> saveNotes(String encryptedJson) async {
    await _storage.write(key: _notesKey, value: encryptedJson);
  }

  static Future<String?> loadNotes() async {
    return await _storage.read(key: _notesKey);
  }

  // PIN storage
  static Future<void> savePinHash(String hash) async {
    await _storage.write(key: _pinHashKey, value: hash);
  }

  static Future<String?> loadPinHash() async {
    return await _storage.read(key: _pinHashKey);
  }

  static Future<bool> hasPin() async {
    final pin = await loadPinHash();
    return pin != null;
  }

  // Theme preference
  static Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: _themeKey, value: themeMode);
  }

  static Future<String?> loadThemeMode() async {
    return await _storage.read(key: _themeKey);
  }

  // Auto-lock: track last activity
  static Future<void> updateLastActivity() async {
    await _storage.write(key: _lastActivityKey, value: DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastActivity() async {
    final timestamp = await _storage.read(key: _lastActivityKey);
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}