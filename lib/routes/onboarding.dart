import 'package:flutter/material.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/screens/onboarding/seed_pin_enhanced.dart';
import 'package:nchat_mobile/screens/onboarding/profile_setup.dart';

void init() {
  Routes.registerRoutes({
    FirstWelcomeScreen.routeName: (BuildContext context, {arguments}) =>
        FirstWelcomeScreen(),
    ProfileSetupScreen.routeName: (BuildContext context, {arguments}) =>
        ProfileSetupScreen(),
  });
}
