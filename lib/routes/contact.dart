import 'package:flutter/material.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/screens/contact/add.dart';
import 'package:nchat_mobile/screens/contact/chat_profile.dart';
import 'package:nchat_mobile/screens/contact/home.dart';
import 'package:nchat_mobile/screens/contact/profile.dart';

Map<String, WidgetBuilder> _routes = {
  ContactHomeScreen.routeName: (BuildContext context, {arguments}) => ContactHomeScreen(arguments: arguments),
  ContactAddScreen.routeName: (BuildContext context) => ContactAddScreen(),
  ContactProfileScreen.routeName: (BuildContext context, {arguments}) => ContactProfileScreen(arguments: arguments),
  ContactChatProfileScreen.routeName: (BuildContext context, {arguments}) => ContactChatProfileScreen(arguments: arguments),
};

init() {
  Routes.registerRoutes(_routes);
}
