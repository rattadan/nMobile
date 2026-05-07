import 'package:flutter/material.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/screens/chat/home.dart';
import 'package:nchat_mobile/screens/chat/messages.dart';
import 'package:nchat_mobile/screens/discovery/public_group_discovery_screen.dart';
import 'package:nchat_mobile/screens/discovery/new_discovery_screen.dart';

Map<String, WidgetBuilder> _routes = {
  ChatHomeScreen.routeName: (BuildContext context) => ChatHomeScreen(),
  ChatMessagesScreen.routeName: (BuildContext context, {arguments}) =>
      ChatMessagesScreen(arguments: arguments),
  PublicGroupDiscoveryScreen.routeName: (BuildContext context) =>
      PublicGroupDiscoveryScreen(),
  NewDiscoveryScreen.routeName: (BuildContext context) => NewDiscoveryScreen(),
};

init() {
  Routes.registerRoutes(_routes);
}
