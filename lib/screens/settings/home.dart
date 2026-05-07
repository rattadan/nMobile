import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nchat_mobile/blocs/settings/settings_bloc.dart';
import 'package:nchat_mobile/blocs/settings/settings_event.dart';
import 'package:nchat_mobile/blocs/settings/settings_state.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/settings.dart';
import 'package:nchat_mobile/common/discovery/public_group_discovery.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/horizontal_action_slideout.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/layout/slideout_controller_provider.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/helpers/error.dart';
import 'package:nchat_mobile/screens/common/select.dart';
import 'package:nchat_mobile/screens/settings/cache.dart';
import 'package:nchat_mobile/screens/settings/develop.dart';
import 'package:nchat_mobile/screens/settings/seedphrase.dart';
import 'package:nchat_mobile/screens/settings/subscribe.dart';
import 'package:nchat_mobile/utils/asset.dart';

import '../wallet/home.dart';

class SettingsHomeScreen extends BaseStateFulWidget {
  static const String routeName = '/settings';

  @override
  _SettingsHomeScreenState createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState
    extends BaseStateFulWidgetState<SettingsHomeScreen>
    with AutomaticKeepAliveClientMixin, SlideoutControllerMixin {
  SettingsBloc? _settingsBloc;
  StreamSubscription? _settingSubscription;

  String? _currentLanguage;
  int? _currentBroadcastPeriod;
  List<SelectListItem> _languageList = [];
  List<SelectListItem> _broadcastPeriodList = [];
  bool _broadcastEnabled = false;

  // Slideout state
  bool _isSlideoutVisible = false;
  List<SlideoutActionItem> _settingsActions = [];

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();

    // Initialize settings-specific slideout actions
    _initializeSettingsActions();

    // Set initial slideout content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        updateSlideoutContent(_buildSlideout());
      }
    });

    _settingsBloc = BlocProvider.of<SettingsBloc>(context);
    _settingSubscription = _settingsBloc?.stream.listen((state) async {
      if (state is LocaleUpdated) {
        setState(() {
          _currentLanguage = _getLanguageText(state.locale);
        });
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            _initData();
          });
        });
      }
    });

    _initData();

    _currentLanguage = _getLanguageText(Settings.language);
    _currentBroadcastPeriod = Settings.discoveryBroadcastPeriod;
    _broadcastEnabled = Settings.discoveryBroadcastEnabled;
  }

  void _initializeSettingsActions() {
    _settingsActions = [
      SlideoutActionItem(
        label: 'Wallet',
        icon: Icons.account_balance_wallet,
        color: Colors.blue,
        onTap: () {
          Navigator.pushNamed(context, WalletHomeScreen.routeName);
        },
      ),
      SlideoutActionItem(
        label: 'Language',
        icon: Icons.language,
        color: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, SelectScreen.routeName, arguments: {
            SelectScreen.title:
                Settings.locale((s) => s.change_language, ctx: context),
            SelectScreen.selectedValue: Settings.language,
            SelectScreen.list: _languageList,
          }).then((lang) {
            if ((lang != null) && (lang is String)) {
              _settingsBloc?.add(UpdateLanguage(lang));
            }
          });
        },
      ),
      SlideoutActionItem(
        label: 'Security',
        icon: Icons.security,
        color: Colors.purple,
        onTap: () {
          // Scroll to security section or show security quick actions
          Toast.show('Security settings - Coming soon');
        },
      ),
      SlideoutActionItem(
        label: 'Develop',
        icon: Icons.developer_mode,
        color: Colors.orange,
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => SettingsDevelopScreen()));
        },
      ),
    ];
  }

  @override
  void dispose() {
    _settingSubscription?.cancel();
    // Clear slideout content
    updateSlideoutContent(SizedBox.shrink());
    super.dispose();
  }

  _initData() {
    _languageList = <SelectListItem>[
      SelectListItem(
        text: Settings.locale((s) => s.language_auto),
        value: 'auto',
      ),
      SelectListItem(
        text: 'English',
        value: 'en',
      ),
      SelectListItem(
        text: '简体中文',
        value: 'zh',
      ),
      SelectListItem(
        text: '繁体中文',
        value: 'zh_Hant_CN',
      ),
    ];
    _broadcastPeriodList = <SelectListItem>[
      SelectListItem(
        text: '1 minute',
        value: 1,
      ),
      SelectListItem(
        text: '5 minutes',
        value: 5,
      ),
      SelectListItem(
        text: '10 minutes',
        value: 10,
      ),
      SelectListItem(
        text: '15 minutes',
        value: 15,
      ),
      SelectListItem(
        text: '30 minutes',
        value: 30,
      ),
      SelectListItem(
        text: '60 minutes',
        value: 60,
      ),
    ];
  }

  String _getLanguageText(String? lang) {
    if (lang == null || lang.isEmpty || lang == 'auto') {
      return Settings.locale((s) => s.language_auto);
    }
    try {
      return _languageList.firstWhere((x) => x.value == lang).text;
    } catch (e, st) {
      handleError(e, st);
      return Settings.locale((s) => s.language_auto);
    }
  }

  String _getBroadcastPeriodText(int? period) {
    try {
      return _broadcastPeriodList.firstWhere((x) => x.value == period).text;
    } catch (e, st) {
      handleError(e, st);
      return '1 minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Layout(
      headerColor: application.theme.primaryColor,
      header: Header(
        titleChild: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Label(
            Settings.locale((s) => s.menu_settings, ctx: context),
            type: LabelType.h2,
            color: application.theme.fontLightColor,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.only(top: 20, bottom: 100, left: 20, right: 20),
        children: [
          // My account
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Label(
                  Settings.locale((s) => s.my_wallets, ctx: context),
                  type: LabelType.h3,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: application.theme.backgroundLightColor,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(top: true, bottom: true),
                    onPressed: () async {
                      Navigator.pushNamed(context, WalletHomeScreen.routeName);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          Settings.locale((s) => s.menu_wallet, ctx: context),
                          type: LabelType.bodyRegular,
                          fontWeight: FontWeight.bold,
                          color: application.theme.fontColor1,
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // general
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Label(
                  Settings.locale((s) => s.general, ctx: context),
                  type: LabelType.h3,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: application.theme.backgroundLightColor,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(top: true, bottom: true),
                    onPressed: () async {
                      Navigator.pushNamed(context, SelectScreen.routeName,
                          arguments: {
                            SelectScreen.title: Settings.locale(
                                (s) => s.change_language,
                                ctx: context),
                            SelectScreen.selectedValue: Settings.language,
                            SelectScreen.list: _languageList,
                          }).then((lang) {
                        if ((lang != null) && (lang is String)) {
                          _settingsBloc?.add(UpdateLanguage(lang));
                        }
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          Settings.locale((s) => s.language, ctx: context),
                          type: LabelType.bodyRegular,
                          fontWeight: FontWeight.bold,
                          color: application.theme.fontColor1,
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            Label(
                              _currentLanguage ?? "",
                              type: LabelType.bodyRegular,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                              height: 1,
                            ),
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Broadcast Enabled Setting
                Container(
                  width: double.infinity,
                  height: 60,
                  child: TextButton(
                    style: _buttonStyle(top: false, bottom: false),
                    onPressed: () async {
                      setState(() {
                        _broadcastEnabled = !_broadcastEnabled;
                      });
                      await Settings.saveDiscoveryBroadcastEnabled(
                          _broadcastEnabled);

                      // Restart periodic broadcast with new setting
                      final discoveryService =
                          locator.get<PublicGroupDiscoveryService>();
                      discoveryService.restartPeriodicBroadcast();

                      Toast.show('Broadcast setting updated');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          'Active Broadcasting',
                          type: LabelType.bodyRegular,
                          fontWeight: FontWeight.bold,
                          color: application.theme.fontColor1,
                        ),
                        Row(
                          children: [
                            Label(
                              _broadcastEnabled ? 'Enabled' : 'Disabled',
                              type: LabelType.bodyRegular,
                              color: _broadcastEnabled
                                  ? application.theme.primaryColor
                                  : application.theme.fontColor3,
                            ),
                            SizedBox(width: 12),
                            Switch(
                              value: _broadcastEnabled,
                              onChanged: (value) async {
                                setState(() {
                                  _broadcastEnabled = value;
                                });
                                await Settings.saveDiscoveryBroadcastEnabled(
                                    value);

                                // Restart periodic broadcast with new setting
                                final discoveryService =
                                    locator.get<PublicGroupDiscoveryService>();
                                discoveryService.restartPeriodicBroadcast();

                                Toast.show('Broadcast setting updated');
                              },
                              activeColor: application.theme.primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Broadcast Period Setting
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(top: false, bottom: true),
                    onPressed: () async {
                      // Only allow changing period if broadcasting is enabled
                      if (!_broadcastEnabled) {
                        Toast.show('Enable broadcasting to change period');
                        return;
                      }

                      Navigator.pushNamed(context, SelectScreen.routeName,
                          arguments: {
                            SelectScreen.title: 'Discovery Broadcast Period',
                            SelectScreen.selectedValue:
                                Settings.discoveryBroadcastPeriod,
                            SelectScreen.list: _broadcastPeriodList,
                          }).then((period) {
                        if ((period != null) && (period is int)) {
                          Settings.saveDiscoveryBroadcastPeriod(period);
                          setState(() {
                            _currentBroadcastPeriod = period;
                          });

                          // Restart periodic broadcast with new period
                          final discoveryService =
                              locator.get<PublicGroupDiscoveryService>();
                          discoveryService.restartPeriodicBroadcast();

                          Toast.show('Broadcast period updated');
                        }
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          'Discovery Broadcast Period',
                          type: LabelType.bodyRegular,
                          fontWeight: FontWeight.bold,
                          color: _broadcastEnabled
                              ? application.theme.fontColor1
                              : application.theme.fontColor3,
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            Label(
                              _getBroadcastPeriodText(_currentBroadcastPeriod),
                              type: LabelType.bodyRegular,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                              height: 1,
                            ),
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // advanced
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Label(
                  Settings.locale((s) => s.advanced, ctx: context),
                  type: LabelType.h3,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: application.theme.backgroundLightColor,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(top: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          Settings.locale((s) => s.Accelerate, ctx: context),
                          type: LabelType.bodyRegular,
                          color: application.theme.fontColor1,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                          context, SettingsAccelerateScreen.routeName);
                    },
                  ),
                ),
                Divider(height: 0, color: application.theme.dividerColor),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(bottom: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          Settings.locale((s) => s.cache, ctx: context),
                          type: LabelType.bodyRegular,
                          color: application.theme.fontColor1,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                          context, SettingsCacheScreen.routeName);
                    },
                  ),
                ),
                Divider(height: 0, color: application.theme.dividerColor),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(bottom: false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          "Show Seedphrase",
                          type: LabelType.bodyRegular,
                          color: application.theme.fontColor1,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        Row(
                          children: [
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                          context, SeedphraseDisplayScreen.routeName);
                    },
                  ),
                ),
                Divider(height: 0, color: application.theme.dividerColor),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: _buttonStyle(bottom: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Label(
                          Settings.locale((s) => s.developer_options,
                              ctx: context),
                          type: LabelType.bodyRegular,
                          color: application.theme.fontColor1,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            Asset.iconSvg(
                              'right',
                              width: 24,
                              color: _broadcastEnabled
                                  ? application.theme.fontColor2
                                  : application.theme.fontColor4,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                          context, SettingsDevelopScreen.routeName);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buttonStyle({bool top = false, bool bottom = false}) {
    return ButtonStyle(
      padding: WidgetStateProperty.resolveWith(
          (states) => EdgeInsets.only(left: 16, right: 16)),
      shape: WidgetStateProperty.resolveWith(
        (states) => RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: top ? Radius.circular(12) : Radius.zero,
                bottom: bottom ? Radius.circular(12) : Radius.zero)),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  /// Build the horizontal slideout widget
  Widget _buildSlideout() {
    return HorizontalActionSlideout(
      items: _settingsActions,
      isVisible: _isSlideoutVisible,
      onVisibilityChanged: (isVisible) {
        setState(() {
          _isSlideoutVisible = isVisible;
        });
      },
    );
  }
}
