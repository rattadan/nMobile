import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nkn_sdk_flutter/utils/hex.dart';
import 'package:nkn_sdk_flutter/wallet.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_event.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/settings.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/dialog/loading.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/form_text.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/helpers/validation.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/settings/terms.dart';
import 'package:nchat_mobile/screens/onboarding/seed_pin_enhanced.dart';
import 'package:nchat_mobile/screens/wallet/import.dart';
import 'package:nchat_mobile/utils/logger.dart';

class ChatNoWalletLayout extends BaseStateFulWidget {
  @override
  _ChatNoWalletLayoutState createState() => _ChatNoWalletLayoutState();
}

class _ChatNoWalletLayoutState
    extends BaseStateFulWidgetState<ChatNoWalletLayout> with Tag {
  GlobalKey _formKey = new GlobalKey<FormState>();

  WalletBloc? _walletBloc;

  bool _formValid = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _termsChecked = false;

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();
    _walletBloc = BlocProvider.of<WalletBloc>(context);
  }

  _create() async {
    if (!_termsChecked) {
      Toast.show(Settings.locale((s) => s.read_and_agree_terms, ctx: context));
      return;
    }
    if ((_formKey.currentState as FormState).validate()) {
      (_formKey.currentState as FormState).save();
      Loading.show();

      String name = _nameController.text;
      String password = _passwordController.text;
      logger.i("$TAG - name:$name, password:$password");

      Wallet nkn =
          await Wallet.create(null, config: WalletConfig(password: password));
      logger.i("$TAG - wallet create - nkn:${nkn.toString()}");
      if (nkn.address.isEmpty || nkn.keystore.isEmpty) {
        Loading.dismiss();
        return;
      }

      WalletSchema wallet = WalletSchema(
          type: WalletType.nkn,
          address: nkn.address,
          publicKey: hexEncode(nkn.publicKey),
          name: name);
      logger.i("$TAG - wallet create - wallet:${wallet.toString()}");

      _walletBloc
          ?.add(AddWallet(wallet, nkn.keystore, password, hexEncode(nkn.seed)));

      Loading.dismiss();
      // AppScreen.go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 40, bottom: 110),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: <Widget>[
                  Label(
                    Settings.locale((s) => s.chat_no_wallet_title,
                        ctx: context),
                    type: LabelType.h2,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8, left: 48, right: 48),
                    child: Label(
                      Settings.locale((s) => s.chat_no_wallet_desc,
                          ctx: context),
                      type: LabelType.bodySmall,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  )
                ],
              ),
              SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                decoration: BoxDecoration(
                  color: application.theme.backgroundColor2,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Button(
                        text: 'Get started...',
                        onPressed: () => FirstWelcomeScreen.go(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
