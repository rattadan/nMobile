import 'package:flutter/material.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/routes/wallet.dart';
import 'package:nchat_mobile/screens/onboarding/new/entropy.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  static const String routeName = '/onboarding/new/welcome';

  const OnboardingWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Layout(
      headerColor: Colors.transparent,
      header: Header(
        title: '',
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Label(
              'Create New Account',
              type: LabelType.h2,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 12),
            Text(
              'Start by creating a new wallet with a secure recovery phrase.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Button(
              text: 'Create Seedphrase and PIN',
              width: double.infinity,
              onPressed: () {
                Navigator.pushNamed(context, OnboardingEntropyScreen.routeName);
              },
            ),
            const SizedBox(height: 24),
            SafeArea(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// Entropy screen defined in entropy.dart
