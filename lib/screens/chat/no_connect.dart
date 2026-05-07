import 'package:nchat_mobile/common/settings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/wallet/create_nkn.dart';
import 'package:nchat_mobile/screens/wallet/import.dart';
import 'package:nchat_mobile/utils/asset.dart';

class ChatNoConnectLayout extends BaseStateFulWidget {
  final Function(WalletSchema? wallet)? goConnect;

  ChatNoConnectLayout(this.goConnect);

  @override
  _ChatNoConnectLayoutState createState() => _ChatNoConnectLayoutState();
}

class _ChatNoConnectLayoutState
    extends BaseStateFulWidgetState<ChatNoConnectLayout> {
  WalletBloc? _walletBloc;
  StreamSubscription? _walletAddSubscription;

  bool loaded = false;
  WalletSchema? _selectWallet;

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();
    // wallet
    _walletBloc = BlocProvider.of<WalletBloc>(this.context);
    _walletAddSubscription = _walletBloc?.stream.listen((event) {
      _refreshWalletDefault();
    });

    // default
    _refreshWalletDefault();
  }

  @override
  void dispose() {
    _walletAddSubscription?.cancel();
    super.dispose();
  }

  _refreshWalletDefault() async {
    WalletSchema? _defaultSelect = await walletCommon.getDefault();
    if (_defaultSelect == null) {
      List<WalletSchema> wallets = await walletCommon.getWallets();
      if (wallets.isNotEmpty) {
        _defaultSelect = wallets[0];
      }
    }
    setState(() {
      loaded = true;
      _selectWallet = _defaultSelect;
    });
  }

  @override
  Widget build(BuildContext context) {
    double headImageWidth = Settings.screenWidth() * 0.55;
    double headImageHeight = headImageWidth / 3 * 2;

    return Layout(
      headerColor: application.theme.primaryColor,
      header: Header(
        titleChild: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Label(
            Settings.locale((s) => s.menu_chat, ctx: context),
            type: LabelType.h2,
            color: application.theme.fontLightColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 60, bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Asset.image(
              'chat/messages.png',
              width: headImageWidth,
              height: headImageHeight,
            ),
            SizedBox(height: 50),
            Column(
              children: [
                Label(
                  Settings.locale((s) => s.chat_no_wallet_title, ctx: context),
                  type: LabelType.h2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Label(
                  Settings.locale((s) => s.click_connect, ctx: context),
                  type: LabelType.bodyRegular,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: 30),
            SizedBox(height: 20),
            !loaded
                ? SizedBox.shrink()
                : this._selectWallet == null
                    ? Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Button(
                              text: Settings.locale((s) => s.no_wallet_create,
                                  ctx: context),
                              width: double.infinity,
                              fontColor: application.theme.fontLightColor,
                              backgroundColor: application.theme.primaryColor,
                              onPressed: () {
                                WalletCreateNKNScreen.go(context);
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Button(
                              text: Settings.locale((s) => s.no_wallet_import,
                                  ctx: context),
                              width: double.infinity,
                              fontColor: application.theme.fontLightColor,
                              backgroundColor:
                                  application.theme.primaryColor.withAlpha(80),
                              onPressed: () {
                                WalletImportScreen.go(context, WalletType.nkn);
                              },
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Button(
                              width: double.infinity,
                              text: Settings.locale((s) => s.connect,
                                  ctx: context),
                              onPressed: () {
                                if (this._selectWallet?.type != WalletType.nkn)
                                  return;
                                this.widget.goConnect?.call(this._selectWallet);
                              },
                            ),
                          )
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}
