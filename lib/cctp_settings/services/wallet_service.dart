import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip32/bip32.dart' as bip32;

/// Mock Solana keypair for demonstration purposes
class MockSolanaKeypair {
  final String privateKey;
  final String publicKey;

  const MockSolanaKeypair({required this.privateKey, required this.publicKey});
}

// KeyData class to hold derived key information
class KeyData {
  final Uint8List key;
  final Uint8List chainCode;

  KeyData(this.key, this.chainCode);
}

// Extension to add hex encoding/decoding to Uint8List
extension HexExtension on Uint8List {
  String toHex() => HEX.encode(this);
}

// Extension to add hex encoding/decoding to List<int>
extension HexListExtension on List<int> {
  String toHex() => HEX.encode(this);
}

extension HexStringExtension on String {
  Uint8List hexToBytes() => Uint8List.fromList(HEX.decode(this));

  List<int> decodeHex() => HEX.decode(this);
}

class WalletService {
  String? _mnemonic;
  String? _ethereumAddress;
  String? _solanaAddress;
  Credentials? _ethCreds; // cache derived creds to keep signer consistent

  WalletService({String? mnemonic}) : _mnemonic = mnemonic;

  /// Sets the mnemonic for the wallet
  void setMnemonic(String mnemonic) {
    _mnemonic = mnemonic;
    // Clear cached addresses when mnemonic changes
    _ethereumAddress = null;
    _solanaAddress = null;
    _ethCreds = null;
  }

  /// Validates a BIP39 mnemonic phrase
  static bool validateMnemonic(String mnemonic) {
    try {
      return bip39.validateMnemonic(mnemonic);
    } catch (e) {
      return false;
    }
  }

  /// Derives Ethereum address from mnemonic
  Future<String> getEthereumAddress() async {
    if (_ethereumAddress != null) return _ethereumAddress!;

    if (_mnemonic == null) {
      throw Exception('No mnemonic provided');
    }

    try {
      final credentials = await _getEthereumCredentials();
      _ethereumAddress = credentials.address.hexEip55;
      return _ethereumAddress!;
    } catch (e) {
      print('Error getting Ethereum address: $e');
      rethrow;
    }
  }

  /// Gets Ethereum credentials from mnemonic
  Future<Credentials> _getEthereumCredentials() async {
    if (_ethCreds != null) return _ethCreds!;

    try {
      // Convert mnemonic to seed bytes
      final seed = bip39.mnemonicToSeed(_mnemonic!);

      // Derive Ethereum private key using BIP32/BIP44 on secp256k1 path m/44'/60'/0'/0/0
      final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
      final node = root.derivePath("m/44'/60'/0'/0/0");
      final pk = node.privateKey;

      if (pk == null || pk.isEmpty) {
        throw Exception('Failed to derive private key for Ethereum');
      }

      // Create EthPrivateKey from private key bytes
      _ethCreds = EthPrivateKey(Uint8List.fromList(pk));
      return _ethCreds!;
    } catch (e) {
      print('Error deriving Ethereum credentials: $e');
      rethrow;
    }
  }

  /// Derives Solana address from mnemonic
  Future<String> getSolanaAddress() async {
    if (_solanaAddress != null) return _solanaAddress!;

    if (_mnemonic == null) {
      throw Exception('No mnemonic provided');
    }

    // TODO: Implement proper Solana address derivation when solana package is properly configured
    _solanaAddress = "Solana address derivation not yet implemented";

    return _solanaAddress!;
  }

  /// Gets the Ethereum private key (hex encoded)
  Future<String> getEthereumPrivateKey() async {
    if (_mnemonic == null) {
      throw Exception('No mnemonic provided');
    }

    // Derive the private key from the mnemonic using BIP32/BIP44 (secp256k1)
    final seed = bip39.mnemonicToSeed(_mnemonic!);
    final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
    final node = root.derivePath("m/44'/60'/0'/0/0");
    final pk = node.privateKey;

    if (pk == null || pk.isEmpty) {
      throw Exception('Failed to derive Ethereum private key');
    }

    return HEX.encode(pk);
  }

  /// Gets the Ethereum credentials for signing
  Future<Credentials> getEthereumCredentials() async {
    return _getEthereumCredentials();
  }

  /// Gets all derived addresses in a map
  Future<Map<String, String>> getAllAddresses() async {
    final addresses = <String, String>{};

    try {
      addresses['ethereum'] = await getEthereumAddress();
    } catch (e) {
      addresses['ethereum'] = 'Error: $e';
    }

    try {
      addresses['solana'] = await getSolanaAddress();
    } catch (e) {
      addresses['solana'] = 'Error: $e';
    }

    return addresses;
  }

  /// Clears all cached data
  void clearCache() {
    _ethereumAddress = null;
    _solanaAddress = null;
    _ethCreds = null;
  }
}
