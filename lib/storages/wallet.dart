import 'dart:async';

import 'package:nchat_mobile/helpers/local_storage.dart';
import 'package:nchat_mobile/helpers/secure_storage.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/utils/logger.dart';

class WalletStorage with Tag {
  static const String KEY_WALLET = 'WALLETS';
  static const String KEY_PUBKEY = 'PUBKEYS';
  static const String KEY_KEYSTORE = 'KEYSTORES';
  static const String KEY_PASSWORD = 'PASSWORDS';
  static const String KEY_SEEDS = 'SEEDS';
  static const String KEY_MNEMONICS = 'MNEMONICS';
  static const String KEY_DEFAULT_ADDRESS = 'default_d_chat_wallet_address';

  Future add(WalletSchema wallet, String keystore, String password, String seed,
      {String? mnemonic}) async {
    List<Future> futures = <Future>[];
    // In single-account mode, always overwrite any existing wallet entry
    // and associated secure data, then set this wallet as the default.
    List<WalletSchema> wallets = await getAll();
    int index = wallets.isEmpty ? -1 : 0;
    if (index < 0) {
      futures.add(LocalStorage.instance.addItem(KEY_WALLET, wallet.toMap()));
    } else {
      futures.add(
          LocalStorage.instance.setItem(KEY_WALLET, index, wallet.toMap()));
    }
    // keystore
    futures.add(SecureStorage.instance
        .set('$KEY_KEYSTORE:${wallet.address}', keystore));
    // password
    futures.add(SecureStorage.instance
        .set('$KEY_PASSWORD:${wallet.address}', password));
    // seed
    futures
        .add(SecureStorage.instance.set('$KEY_SEEDS:${wallet.address}', seed));
    // mnemonic (if provided)
    if (mnemonic != null && mnemonic.isNotEmpty) {
      futures.add(SecureStorage.instance
          .set('$KEY_MNEMONICS:${wallet.address}', mnemonic));
    }
    // Persist default address for the single wallet
    futures
        .add(LocalStorage.instance.set('$KEY_DEFAULT_ADDRESS', wallet.address));

    await Future.wait(futures);

    logger.v(
        "$TAG - add(single) - index:$index - wallet:$wallet - keystore:$keystore - password:$password");
    return;
  }

  Future delete(int index, String? address) async {
    List<Future> futures = <Future>[];
    if (index >= 0) {
      futures.add(LocalStorage.instance.removeItem(KEY_WALLET, index));
      // keystore
      futures.add(SecureStorage.instance.delete('$KEY_KEYSTORE:$address'));
      // password
      futures.add(SecureStorage.instance.delete('$KEY_PASSWORD:$address'));
      // seed
      futures.add(SecureStorage.instance.delete('$KEY_SEEDS:$address'));
      // mnemonic
      futures.add(SecureStorage.instance.delete('$KEY_MNEMONICS:$address'));
    }
    if (await getDefaultAddress() == address) {
      futures.add(LocalStorage.instance.remove('$KEY_DEFAULT_ADDRESS'));
    }
    await Future.wait(futures);

    logger.v("$TAG - delete - index:$index - address:$address");
    return;
  }

  Future update(int index, WalletSchema wallet,
      {String? keystore, String? password, String? seed}) async {
    List<Future> futures = <Future>[];
    if (index >= 0) {
      futures.add(
          LocalStorage.instance.setItem(KEY_WALLET, index, wallet.toMap()));
      // keystore
      if (keystore != null && keystore.isNotEmpty) {
        futures.add(SecureStorage.instance
            .set('$KEY_KEYSTORE:${wallet.address}', keystore));
      }
      // password
      if (password != null && password.isNotEmpty) {
        futures.add(SecureStorage.instance
            .set('$KEY_PASSWORD:${wallet.address}', password));
      }
      // seed
      if (seed != null && seed.isNotEmpty) {
        futures.add(
            SecureStorage.instance.set('$KEY_SEEDS:${wallet.address}', seed));
      }
    }
    await Future.wait(futures);

    logger.v(
        "$TAG - update - index:$index - wallet:$wallet - keystore:$keystore - password:$password");
    return;
  }

  Future<List<WalletSchema>> getAll() async {
    var wallets = await LocalStorage.instance.getArray(KEY_WALLET);
    if (wallets.isNotEmpty) {
      String logText = '';
      var list = wallets.map((e) {
        WalletSchema walletSchema = WalletSchema.fromMap(e);
        logText += "\n      $e";
        return walletSchema;
      }).toList();
      logger.v("$TAG - getWallets - wallets:$logText");
      return list;
    }
    logger.i("$TAG - getWallets - wallets == []");
    return [];
  }

  Future getKeystore(String? address) async {
    if (address == null || address.isEmpty) return null;
    var keystore;
    keystore = await SecureStorage.instance.get('$KEY_KEYSTORE:$address');
    // SUPPORT:START
    if (keystore == null || keystore.isEmpty) {
      keystore = await SecureStorage.instance.get('NKN_KEYSTORES:$address');
      if (keystore == null || keystore.isEmpty) {
        // bug in android [v1.0.3(193)] fixed on android [v1.1.0(208)]
        // String? decryptKey = await LocalStorage.instance.get("WALLET_KEYSTORE_AESVALUE_KEY");
        // if (decryptKey?.isNotEmpty == true) {
        //   String? decodedValue = await LocalStorage.instance.get('WALLET_KEYSTORE_ENCRYPT_VALUE');
        //   if (decodedValue == null || decodedValue.isEmpty) {
        //     decodedValue = await LocalStorage.instance.get('WALLET_KEYSTORE_ENCRYPT_VALUE_$address');
        //   }
        //   if (decodedValue?.isNotEmpty == true) {
        //     keystore = await FlutterAesEcbPkcs5.decryptString(decodedValue, decryptKey);
        //   }
        // } else {
        keystore = await LocalStorage.instance
            .get('WALLET_KEYSTORE_ENCRYPT_VALUE_$address');
        // }
        logger.i(
            "$TAG - getKeystore - from(NKN_KEYSTORES) - address:$address - keystore:$keystore");
      } else {
        logger.i(
            "$TAG - getKeystore - from(WALLET_KEYSTORE_ENCRYPT_VALUE_) - address:$address - keystore:$keystore");
      }
      // sync wallet_add
      if (keystore != null && keystore.isNotEmpty) {
        await SecureStorage.instance.set('$KEY_KEYSTORE:$address', keystore);
      } else {
        logger.w("$TAG - getKeystore - address:$address - keystore is empty");
      }
    }
    // SUPPORT:END
    logger.v("$TAG - getKeystore - address:$address - keystore:$keystore");
    return keystore;
  }

  Future getPassword(String? address) async {
    if (address == null || address.isEmpty) return null;
    return SecureStorage.instance.get('$KEY_PASSWORD:$address');
  }

  Future getSeed(String? address) async {
    if (address == null || address.isEmpty) return null;
    return SecureStorage.instance.get('$KEY_SEEDS:$address');
  }

  Future getMnemonic(String? address) async {
    if (address == null || address.isEmpty) return null;
    return SecureStorage.instance.get('$KEY_MNEMONICS:$address');
  }

  // default
  Future setDefaultAddress(String? address) async {
    return LocalStorage.instance.set('$KEY_DEFAULT_ADDRESS', address ?? "");
  }

  Future<String?> getDefaultAddress() async {
    String? address = await LocalStorage.instance.get('$KEY_DEFAULT_ADDRESS');
    // if (address == null || !Validate.isNknAddressOk(address)) {
    //   List<WalletSchema> wallets = await getAll();
    //   if (wallets.isEmpty) {
    //     logger.w("$TAG - getDefaultAddress - wallets.isEmpty");
    //     return null;
    //   }
    //   String firstAddress = wallets[0].address;
    //   if (firstAddress.isNotEmpty && !Validate.isNknAddressOk(firstAddress)) {
    //     logger.w("$TAG - getDefaultAddress - address error");
    //     return null;
    //   }
    //   await setDefaultAddress(firstAddress);
    //   logger.i("$TAG - getDefaultAddress - default - address:$address");
    //   return firstAddress;
    // }
    logger.v("$TAG - getDefaultAddress - address:$address");
    return address?.isNotEmpty == true ? address : null;
  }
}
