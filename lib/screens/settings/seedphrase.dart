import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/helpers/validation.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/storages/wallet.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';
import 'package:nchat_mobile/app.dart';

class SeedphraseDisplayScreen extends BaseStateFulWidget {
  static const String routeName = '/settings/seedphrase';

  static Future go(BuildContext? context) {
    if (context == null) return Future.value(null);
    return Navigator.pushNamed(context, routeName);
  }

  @override
  _SeedphraseDisplayScreenState createState() =>
      _SeedphraseDisplayScreenState();
}

class _SeedphraseDisplayScreenState
    extends BaseStateFulWidgetState<SeedphraseDisplayScreen> with Tag {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _pinConfirmController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _pinConfirmFocusNode = FocusNode();

  bool _isLoading = false;
  bool _seedphraseVisible = false;
  bool _formValid = false;
  String? _seedphrase;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinConfirmController.dispose();
    _pinFocusNode.dispose();
    _pinConfirmFocusNode.dispose();
    super.dispose();
  }

  @override
  void onRefreshArguments() {
    // No arguments to refresh
  }

  Future<void> _verifyPinAndShowSeedphrase() async {
    if (!_formValid) {
      Toast.show('Please enter a 4-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get wallet for password verification
      WalletSchema? wallet = await walletCommon.getDefault();
      if (wallet == null || wallet.address.isEmpty) {
        Toast.show("No wallet found");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verify password (using wallet password as security)
      bool isPasswordCorrect = await walletCommon.isPasswordRight(
          wallet.address, _pinController.text);
      if (!isPasswordCorrect) {
        Toast.show("Incorrect password");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get mnemonic from secure storage
      WalletStorage storage = WalletStorage();
      String? mnemonic = await storage.getMnemonic(wallet.address);
      if (mnemonic != null && mnemonic.isNotEmpty) {
        setState(() {
          _seedphrase = mnemonic;
          _seedphraseVisible = true;
        });
      } else {
        Toast.show("Seedphrase not available");
      }
    } catch (e) {
      logger.e("$TAG - Error retrieving seedphrase: $e");
      Toast.show("Error retrieving seedphrase");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copySeedphrase() async {
    if (_seedphrase != null) {
      await Clipboard.setData(ClipboardData(text: _seedphrase!));
      Toast.show("Seedphrase copied to clipboard");
    }
  }

  void _hideSeedphrase() {
    setState(() {
      _seedphraseVisible = false;
      _pinController.clear();
      _formValid = false;
    });
  }

  Widget _buildPinDisplay() {
    final pin = _pinController.text;
    const maxLength = 4;

    return Column(
      children: [
        Text(
          'Enter your 4-digit PIN',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxLength, (index) {
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < pin.length
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildNumpadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumpadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumpadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _pinController.clear();
                      _formValid = _validateForm();
                    });
                  },
                  icon: const Icon(Icons.close, size: 28),
                ),
              ),
              Expanded(child: _buildNumpadButton('0')),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_pinController.text.isNotEmpty) {
                        _pinController.text = _pinController.text
                            .substring(0, _pinController.text.length - 1);
                      }
                      _formValid = _validateForm();
                    });
                  },
                  icon: const Icon(Icons.backspace, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumpadButton(n)).toList(),
    );
  }

  Widget _buildNumpadButton(String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (_pinController.text.length < 4) {
              _pinController.text += number;
              _formValid = _validateForm();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(18),
          minimumSize: const Size(64, 64),
        ),
        child: Text(
          number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  bool _validateForm() {
    return _pinController.text.length == 4;
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      headerColor: application.theme.backgroundColor4,
      header: Header(
        title: "Show Seedphrase",
        backgroundColor: application.theme.backgroundColor4,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_seedphraseVisible) ...[
                // Warning message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Label(
                            "Security Warning",
                            type: LabelType.h4,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Label(
                        "Your seedphrase gives full access to your funds. Only show it when necessary and never share it with anyone.",
                        type: LabelType.bodySmall,
                        color: application.theme.fontColor1,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // PIN input form
                Label(
                  "Enter your PIN to continue",
                  type: LabelType.h4,
                  color: application.theme.fontColor1,
                ),
                SizedBox(height: 16),
                _buildPinDisplay(),
                SizedBox(height: 24),
                _buildNumpad(),
                SizedBox(height: 24),

                // Show button
                Button(
                  text: _isLoading ? "Verifying..." : "Show Seedphrase",
                  width: double.infinity,
                  backgroundColor: application.theme.primaryColor,
                  fontColor: Colors.white,
                  onPressed: _isLoading ? null : _verifyPinAndShowSeedphrase,
                ),
              ] else ...[
                // Seedphrase display
                Label(
                  "Your Seedphrase",
                  type: LabelType.h4,
                  color: application.theme.fontColor1,
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: application.theme.backgroundLightColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: application.theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _seedphrase ?? "",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: application.theme.fontColor1,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.content_copy,
                              size: 16, color: application.theme.fontColor2),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: _copySeedphrase,
                            child: Label(
                              "Tap to copy",
                              type: LabelType.bodySmall,
                              color: application.theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Security reminder
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Label(
                            "Important Security Notice",
                            type: LabelType.h4,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Label(
                        "• Write down your seedphrase and store it safely\n• Never store it digitally or take screenshots\n• Anyone with this seedphrase can steal your funds\n• This is the only way to recover your wallet",
                        type: LabelType.bodySmall,
                        color: application.theme.fontColor1,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Hide button
                Button(
                  text: "Hide Seedphrase",
                  width: double.infinity,
                  backgroundColor: application.theme.primaryColor.withAlpha(20),
                  fontColor: application.theme.primaryColor,
                  onPressed: _hideSeedphrase,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
