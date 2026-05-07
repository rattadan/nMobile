import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nkn_sdk_flutter/wallet.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_event.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_state.dart';
import 'package:nchat_mobile/common/wallet/erc20.dart';
import 'package:nchat_mobile/helpers/error.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/storages/wallet.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:web3dart/web3dart.dart' as Web3;

class WalletCommon with Tag {
  WalletStorage _walletStorage = WalletStorage();
  EthErc20Client _erc20client = EthErc20Client();

  WalletCommon();

  Future<List<WalletSchema>> getWallets() {
    return _walletStorage.getAll();
  }

  Future<String?> getDefaultAddress() {
    return _walletStorage.getDefaultAddress();
  }

  Future<WalletSchema?> getDefault() async {
    // In single-account mode, always resolve to the single stored wallet.
    String? address = await getDefaultAddress();
    List<WalletSchema> wallets = await getWallets();

    // No wallets stored at all.
    if (wallets.isEmpty) return null;

    // If we have a default address and it matches a stored wallet, use it.
    if (address != null && address.isNotEmpty) {
      final finds = wallets.where((w) => w.address == address).toList();
      if (finds.isNotEmpty) return finds[0];
    }

    // Otherwise, fall back to the first wallet and set it as default.
    final WalletSchema first = wallets[0];
    await _walletStorage.setDefaultAddress(first.address);
    return first;
  }

  Future<String> getKeystore(String? walletAddress) async {
    String? keystore = await _walletStorage.getKeystore(walletAddress);
    if (keystore == null || keystore.isEmpty) {
      throw new Exception("keystore not exits");
    }
    return keystore;
  }

  Future getPassword(String? walletAddress) async {
    if (walletAddress == null || walletAddress.isEmpty) return null;
    return _walletStorage.getPassword(walletAddress);
  }

  Future<bool> isPasswordRight(String? walletAddress, String? password) async {
    if (walletAddress == null || walletAddress.isEmpty) return false;
    if (password == null || password.isEmpty) return false;
    String? storagePassword = await getPassword(walletAddress);
    if (storagePassword?.isNotEmpty == true) {
      return password == storagePassword;
    } else {
      try {
        final keystore = await getKeystore(walletAddress);
        Wallet nknWallet = await Wallet.restore(keystore,
            config: WalletConfig(password: password));
        if (nknWallet.address.isNotEmpty) return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future getSeed(String? walletAddress) async {
    if (walletAddress == null || walletAddress.isEmpty) return null;
    return _walletStorage.getSeed(walletAddress);
  }

  bool isBalanceSame(WalletSchema? w1, WalletSchema? w2) {
    if (w1 == null || w2 == null) return true;
    return w1.balance == w2.balance && w1.balanceEth == w2.balanceEth;
  }

  queryAllBalance({int? delayMs}) async {
    if (delayMs != null) await Future.delayed(Duration(milliseconds: delayMs));
    WalletBloc _walletBloc = BlocProvider.of<WalletBloc>(Settings.appContext);
    var state = _walletBloc.state;
    if (state is WalletLoaded) {
      logger.d("$TAG - queryAllBalance - start");
      for (var i = 0; i < state.wallets.length; i++) {
        WalletSchema wallet = state.wallets[i];
        if (wallet.type == WalletType.eth) {
          await queryETHBalance(wallet, notifyIfNeed: true);
        } else {
          await queryNKNBalance(wallet, notifyIfNeed: true);
        }
      }
    }
  }

  Future<double?> queryNKNBalance(WalletSchema wallet,
      {bool notifyIfNeed = false, int? delayMs}) async {
    if (delayMs != null) await Future.delayed(Duration(milliseconds: delayMs));
    if (wallet.address.isEmpty || wallet.type == WalletType.eth) return null;
    WalletBloc _walletBloc = BlocProvider.of<WalletBloc>(Settings.appContext);
    try {
      double balance = await Wallet.getBalanceByAddr(wallet.address);
      logger.d(
          "$TAG - queryNKNBalance - old:${wallet.balance} - new:$balance - wallet_address:${wallet.address}");
      if (notifyIfNeed && (wallet.balance != balance)) {
        wallet.balance = balance;
        _walletBloc.add(UpdateWallet(wallet));
      }
      return balance;
    } catch (e, st) {
      handleError(e, st);
    }
    return null;
  }

  Future<List<double?>> queryETHBalance(WalletSchema wallet,
      {bool notifyIfNeed = false, int? delayMs}) async {
    if (delayMs != null) await Future.delayed(Duration(milliseconds: delayMs));
    if (wallet.address.isEmpty || wallet.type == WalletType.nkn)
      return [null, null];
    WalletBloc _walletBloc = BlocProvider.of<WalletBloc>(Settings.appContext);
    try {
      Web3.EtherAmount? ethAmount =
          await _erc20client.getBalanceEth(address: wallet.address);
      Web3.EtherAmount? nknAmount =
          await _erc20client.getBalanceNkn(address: wallet.address);
      logger.d(
          "$TAG - queryETHBalance - eth - old:${wallet.balanceEth} - new:${ethAmount?.ether} - wallet_address:${wallet.address}");
      logger.d(
          "$TAG - queryETHBalance - nkn - old:${wallet.balance} - new:${nknAmount?.ether} - wallet_address:${wallet.address}");
      bool ethDiff = (ethAmount != null) &&
          (wallet.balanceEth != (ethAmount.ether as double?));
      bool nknDiff = (nknAmount != null) &&
          (wallet.balance != (nknAmount.ether as double?));
      if (notifyIfNeed && (ethDiff || nknDiff)) {
        wallet.balanceEth = (ethAmount?.ether as double?) ?? 0;
        wallet.balance = (nknAmount?.ether as double?) ?? 0;
        _walletBloc.add(UpdateWallet(wallet));
      }
      return [(ethAmount?.ether as double?), (nknAmount?.ether as double?)];
    } catch (e, st) {
      handleError(e, st);
    }
    return [null, null];
  }
}
