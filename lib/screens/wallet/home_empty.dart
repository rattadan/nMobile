import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/screens/wallet/create_nkn.dart';
import 'package:nchat_mobile/utils/asset.dart';

class WalletHomeEmptyLayout extends BaseStateFulWidget {
  @override
  _WalletHomeEmptyLayoutState createState() => _WalletHomeEmptyLayoutState();
}

class _WalletHomeEmptyLayoutState
    extends BaseStateFulWidgetState<WalletHomeEmptyLayout> {
  @override
  void onRefreshArguments() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: application.theme.backgroundColor4,
      padding: EdgeInsets.fromLTRB(20, 32, 20, 86),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Center(
            child: Asset.image("wallet/pig.png",
                width: Settings.screenWidth() / 3),
          ),
          Column(
            children: <Widget>[
              Label(
                Settings.locale((s) => s.no_wallet_title, ctx: context),
                color: application.theme.fontLightColor,
                type: LabelType.h2,
                dark: true,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.only(top: 16, left: 24, right: 24),
                child: Label(
                  Settings.locale((s) => s.no_wallet_desc, ctx: context),
                  color: application.theme.fontLightColor,
                  type: LabelType.h4,
                  dark: true,
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
          Column(
            children: <Widget>[
              Button(
                text: Settings.locale((s) => s.no_wallet_create, ctx: context),
                width: double.infinity,
                fontColor: application.theme.fontLightColor,
                backgroundColor: application.theme.primaryColor,
                onPressed: () {
                  WalletCreateNKNScreen.go(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
