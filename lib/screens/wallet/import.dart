import 'package:nchat_mobile/common/settings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/dialog/modal.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/common/scanner.dart';
import 'package:nchat_mobile/screens/wallet/import_by_seed.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class WalletImportScreen extends BaseStateFulWidget {
  static const String routeName = '/wallet/import';
  static final String argWalletType = "wallet_type";

  static Future go(BuildContext? context, String walletType) {
    if (context == null) return Future.value(null);
    return Navigator.pushNamed(context, routeName, arguments: {
      argWalletType: walletType,
    });
  }

  final Map<String, dynamic>? arguments;

  const WalletImportScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _ImportWalletScreenState createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState
    extends BaseStateFulWidgetState<WalletImportScreen> with Tag {
  late String _walletType;

  StreamController<String> _qrController = StreamController<String>.broadcast();

  @override
  void onRefreshArguments() {
    this._walletType =
        widget.arguments?[WalletImportScreen.argWalletType] ?? WalletType.nkn;
  }

  @override
  void dispose() {
    _qrController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      headerColor: application.theme.backgroundColor4,
      header: Header(
        title: this._walletType == WalletType.eth
            ? Settings.locale((s) => s.import_ethereum_wallet, ctx: context)
            : Settings.locale((s) => s.import_nkn_wallet, ctx: context),
        backgroundColor: application.theme.backgroundColor4,
        actions: [
          IconButton(
            icon: Asset.iconSvg('scan',
                width: 24, color: application.theme.backgroundLightColor),
            onPressed: () async {
              // permission
              PermissionStatus permissionStatus =
                  await Permission.camera.request();
              if (permissionStatus != PermissionStatus.granted) return;
              // scan
              String? qrData =
                  (await Navigator.pushNamed(context, ScannerScreen.routeName))
                      ?.toString()
                      .replaceAll("\n", "")
                      .trim();
              logger.i("$TAG - QR_DATA:$qrData");
              if (qrData != null && qrData.isNotEmpty) {
                _qrController.sink.add(qrData);
              } else {
                ModalDialog.of(Settings.appContext).show(
                  content: Settings.locale((s) => s.error_unknown_nkn_qrcode,
                      ctx: context),
                  hasCloseButton: true,
                );
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: WalletImportBySeedLayout(
              walletType: this._walletType, qrStream: _qrController.stream),
        ),
      ),
    );
  }
}
