import 'package:flutter/material.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/screens/wallet/create_eth.dart';
import 'package:nchat_mobile/screens/wallet/create_nkn.dart';
import 'package:nchat_mobile/screens/wallet/detail.dart';
import 'package:nchat_mobile/screens/wallet/export.dart';
import 'package:nchat_mobile/screens/wallet/home.dart';
import 'package:nchat_mobile/screens/wallet/import.dart';
import 'package:nchat_mobile/screens/wallet/receive.dart';
import 'package:nchat_mobile/screens/wallet/send.dart';

Map<String, WidgetBuilder> _routes = {
  WalletHomeScreen.routeName: (BuildContext context) => WalletHomeScreen(),
  WalletCreateNKNScreen.routeName: (BuildContext context) => WalletCreateNKNScreen(),
  WalletCreateETHScreen.routeName: (BuildContext context) => WalletCreateETHScreen(),
  WalletImportScreen.routeName: (BuildContext context, {arguments}) => WalletImportScreen(arguments: arguments),
  WalletDetailScreen.routeName: (BuildContext context, {arguments}) => WalletDetailScreen(arguments: arguments),
  WalletExportScreen.routeName: (BuildContext context, {arguments}) => WalletExportScreen(arguments: arguments),
  WalletReceiveScreen.routeName: (BuildContext context, {arguments}) => WalletReceiveScreen(arguments: arguments),
  WalletSendScreen.routeName: (BuildContext context, {arguments}) => WalletSendScreen(arguments: arguments),
};

init() {
  Routes.registerRoutes(_routes);
}
