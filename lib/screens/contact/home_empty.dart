import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/screens/contact/add.dart';
import 'package:nchat_mobile/utils/asset.dart';

class ContactHomeEmptyLayout extends BaseStateFulWidget {
  @override
  _ContactHomeEmptyLayoutState createState() => _ContactHomeEmptyLayoutState();
}

class _ContactHomeEmptyLayoutState extends BaseStateFulWidgetState<ContactHomeEmptyLayout> {
  @override
  void onRefreshArguments() {}

  @override
  Widget build(BuildContext context) {
    double imgSize = Settings.screenWidth() / 2;

    return Layout(
      headerColor: application.theme.primaryColor,
      header: Header(
        title: Settings.locale((s) => s.my_contact, ctx: context),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, ContactAddScreen.routeName);
            },
            icon: Asset.iconSvg(
              'user-plus',
              // color: application.theme.backgroundLightColor,
              width: 24,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Asset.image("contact/no-contact.png", width: imgSize, height: imgSize),
              SizedBox(height: 30),
              Column(
                children: <Widget>[
                  Label(
                    Settings.locale((s) => s.contact_no_contact_title, ctx: context),
                    type: LabelType.h2,
                    textAlign: TextAlign.center,
                    maxLines: 10,
                  ),
                  SizedBox(height: 50),
                  Label(
                    Settings.locale((s) => s.contact_no_contact_desc, ctx: context),
                    type: LabelType.bodySmall,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 10,
                  )
                ],
              ),
              SizedBox(height: 96),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Button(
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Asset.iconSvg('user-plus', color: application.theme.backgroundLightColor, width: 24),
                            SizedBox(width: 24),
                            Label(
                              Settings.locale((s) => s.add_contact, ctx: context),
                              type: LabelType.h3,
                              color: application.theme.fontLightColor,
                            )
                          ],
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, ContactAddScreen.routeName);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
