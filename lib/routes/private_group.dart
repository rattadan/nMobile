import 'package:flutter/material.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/screens/private_group/profile.dart';
import 'package:nchat_mobile/screens/private_group/subscribers.dart';

Map<String, WidgetBuilder> _routes = {
  PrivateGroupProfileScreen.routeName: (BuildContext context, {arguments}) => PrivateGroupProfileScreen(arguments: arguments),
  PrivateGroupSubscribersScreen.routeName: (BuildContext context, {arguments}) => PrivateGroupSubscribersScreen(arguments: arguments),
};

init() {
  Routes.registerRoutes(_routes);
}
