import 'package:flutter/material.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/screens/settings/cache.dart';
import 'package:nchat_mobile/screens/settings/develop.dart';
import 'package:nchat_mobile/screens/settings/home.dart';
import 'package:nchat_mobile/screens/settings/seedphrase.dart';
import 'package:nchat_mobile/screens/settings/subscribe.dart';
import 'package:nchat_mobile/screens/settings/terms.dart';

Map<String, WidgetBuilder> _routes = {
  SettingsHomeScreen.routeName: (BuildContext context) => SettingsHomeScreen(),
  SettingsCacheScreen.routeName: (BuildContext context) =>
      SettingsCacheScreen(),
  SettingsAccelerateScreen.routeName: (BuildContext context) =>
      SettingsAccelerateScreen(),
  SettingsTermsScreen.routeName: (BuildContext context) =>
      SettingsTermsScreen(),
  SettingsDevelopScreen.routeName: (BuildContext context) =>
      SettingsDevelopScreen(),
  SeedphraseDisplayScreen.routeName: (BuildContext context) =>
      SeedphraseDisplayScreen(),
};

init() {
  Routes.registerRoutes(_routes);
}
