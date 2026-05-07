import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/components/dialog/bottom.dart';
import 'package:nchat_mobile/components/wallet/item.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';

class WalletDropdown extends StatelessWidget with Tag {
  final WalletSchema wallet;
  final String? selectTitle;
  final Function(WalletSchema)? onSelected;
  final Color? bgColor;
  final bool onTapWave;
  final bool onlyNKN;

  WalletDropdown({
    required this.wallet,
    this.selectTitle,
    this.onSelected,
    this.bgColor,
    this.onTapWave = true,
    this.onlyNKN = false,
  });

  @override
  Widget build(BuildContext context) {
    return WalletItem(
      walletType: this.wallet.type,
      wallet: this.wallet,
      radius: BorderRadius.circular(8),
      padding: EdgeInsets.all(0),
      bgColor: Colors.transparent,
      onTapWave: this.onTapWave,
      tail: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Asset.iconSvg('down2', width: 24),
      ),
      onTap: () async {
        WalletSchema? result = await BottomDialog.of(Settings.appContext).showWalletSelect(
          title: this.selectTitle ?? Settings.locale((s) => s.select_another_wallet, ctx: context),
          onlyNKN: this.onlyNKN,
        );
        logger.i("$TAG - wallet dropdown select - wallet:$result");
        if (result != null) {
          this.onSelected?.call(result);
        }
      },
    );
  }
}
