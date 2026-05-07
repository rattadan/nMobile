import 'package:nchat_mobile/common/settings.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_state.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/dialog/loading.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/wallet/dropdown.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';
import 'package:nchat_mobile/utils/util.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class WalletReceiveScreen extends BaseStateFulWidget {
  static const String routeName = '/wallet/receive';
  static final String argWallet = "wallet";

  static Future go(BuildContext? context, WalletSchema wallet) {
    if (context == null) return Future.value(null);
    return Navigator.pushNamed(context, routeName, arguments: {
      argWallet: wallet,
    });
  }

  final Map<String, dynamic>? arguments;

  WalletReceiveScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _WalletReceiveScreenState createState() => _WalletReceiveScreenState();
}

class _WalletReceiveScreenState extends BaseStateFulWidgetState<WalletReceiveScreen> with Tag {
  GlobalKey globalKey = new GlobalKey();
  late WalletSchema _wallet;

  @override
  void onRefreshArguments() {
    this._wallet = widget.arguments?[WalletReceiveScreen.argWallet];
  }

  @override
  void initState() {
    super.initState();
    // balance query
    // walletCommon.queryBalance();
  }

  @override
  Widget build(BuildContext context) {
    RepaintBoundary repaintBoundary = RepaintBoundary(
      key: globalKey,
      child: Container(
        color: application.theme.backgroundColor,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: Material(
                color: application.theme.backgroundColor2,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  onTap: () {
                    Util.copyText(_wallet.address);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    // decoration: BoxDecoration(
                    //   borderRadius: BorderRadius.all(Radius.circular(8)),
                    //   color: application.theme.backgroundColor2,
                    // ),
                    child: Column(
                      children: <Widget>[
                        Label(
                          Settings.locale((s) => s.wallet_address, ctx: context),
                          type: LabelType.h4,
                          textAlign: TextAlign.start,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Label(
                            _wallet.address,
                            type: LabelType.bodyRegular,
                            textAlign: TextAlign.start,
                            maxLines: 10,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Asset.iconSvg(
                                'copy',
                                width: 24,
                                color: application.theme.primaryColor,
                              ),
                            ),
                            Label(
                              Settings.locale((s) => s.copy_to_clipboard, ctx: context),
                              color: application.theme.primaryColor,
                              type: LabelType.h4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 24),
              child: QrImageView(
                data: _wallet.address,
                version: QrVersions.auto,
                size: Settings.screenWidth() * 0.57,
              ),
            ),
          ],
        ),
      ),
    );

    return Layout(
      headerColor: application.theme.backgroundColor4,
      header: Header(
        title: (Settings.locale((s) => s.receive, ctx: context) + ' ' + Settings.locale((s) => s.nkn, ctx: context)),
        backgroundColor: application.theme.backgroundColor4,
        actions: [
          IconButton(
            icon: Asset.iconSvg(
              'share',
              width: 24,
              color: application.theme.backgroundLightColor,
            ),
            onPressed: () async {
              Loading.show();
              // image
              RenderRepaintBoundary? boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
              var qrImg = await boundary?.toImage();
              ByteData? imgData = await qrImg?.toByteData(format: ImageByteFormat.png);
              Uint8List? imgBytes = imgData?.buffer.asUint8List();
              if (imgBytes == null || imgBytes.isEmpty) {
                Loading.dismiss();
                return;
              }
              // file
              String path = await Path.createRandomFile(null, DirType.download, fileExt: "png");
              File qrFile = File(path);
              qrFile = await qrFile.writeAsBytes(imgBytes);
              Loading.dismiss();
              XFile xFile = XFile(qrFile.path, mimeType: "image/png");
              // share
              Share.shareXFiles([xFile]);
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  if (state is WalletLoaded) {
                    // refresh balance
                    List<WalletSchema> finds = state.wallets.where((w) => w.address == _wallet.address).toList();
                    if (finds.isNotEmpty) {
                      _wallet = finds[0];
                    }
                    // else {
                    //   if (Navigator.of(this.context).canPop()) Navigator.pop(this.context);
                    // }
                  }
                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                        child: WalletDropdown(
                          selectTitle: Settings.locale((s) => s.select_asset_to_receive, ctx: context),
                          wallet: _wallet,
                          onTapWave: false,
                          onSelected: (WalletSchema picked) {
                            logger.i("$TAG - wallet picked - $picked");
                            setState(() {
                              _wallet = picked;
                            });
                          },
                        ),
                      ),
                      Divider(height: 3, indent: 20, endIndent: 20),
                      repaintBoundary,
                    ],
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Button(
                      text: Settings.locale((s) => s.done, ctx: context),
                      width: double.infinity,
                      onPressed: () {
                        if (Navigator.of(this.context).canPop()) Navigator.pop(this.context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
