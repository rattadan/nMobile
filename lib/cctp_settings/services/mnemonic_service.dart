import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing mnemonic phrases
class MnemonicService {
  static const String _secureMnemonicKey = 'primary_mnemonic';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Get the mnemonic from secure storage
  static Future<String?> getMnemonic() async {
    try {
      final mnemonic = await _secureStorage.read(key: _secureMnemonicKey);
      if (mnemonic != null && mnemonic.trim().isNotEmpty) {
        return mnemonic.trim();
      }
      return null;
    } catch (e) {
      print('Error getting mnemonic: $e');
      return null;
    }
  }

  /// Set a custom mnemonic (overrides default)
  static Future<void> setCustomMnemonic(String mnemonic) async {
    await _secureStorage.write(key: _secureMnemonicKey, value: mnemonic.trim());
  }

  /// Check if user has set a custom mnemonic
  static Future<bool> hasCustomMnemonic() async {
    try {
      final customMnemonic = await _secureStorage.read(key: _secureMnemonicKey);
      return customMnemonic != null && customMnemonic.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Remove custom mnemonic
  static Future<void> removeCustomMnemonic() async {
    await _secureStorage.delete(key: _secureMnemonicKey);
  }

  /// Check if this is the first run (no mnemonic set yet)
  static Future<bool> isFirstRun() async {
    return !(await hasCustomMnemonic());
  }
}
