import 'package:nchat_mobile/common/settings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_state.dart';
import 'package:nchat_mobile/common/client/client.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/contact/header.dart';
import 'package:nchat_mobile/components/dialog/bottom.dart';
import 'package:nchat_mobile/components/layout/chat_topic_search.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/horizontal_action_slideout.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/layout/slideout_controller_provider.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/routes/routes.dart';
import 'package:nchat_mobile/schema/contact.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/chat/no_connect.dart';
import 'package:nchat_mobile/screens/chat/no_wallet.dart';
import 'package:nchat_mobile/screens/chat/session_list.dart';
import 'package:nchat_mobile/screens/contact/home.dart';
import 'package:nchat_mobile/screens/contact/profile.dart';
import 'package:nchat_mobile/screens/discovery/new_discovery_screen.dart';
import 'package:nchat_mobile/screens/onboarding/profile_setup.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';

class ChatHomeScreen extends BaseStateFulWidget {
  static const String routeName = '/chat/home';

  @override
  _ChatHomeScreenState createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends BaseStateFulWidgetState<ChatHomeScreen>
    with
        AutomaticKeepAliveClientMixin,
        RouteAware,
        Tag,
        SlideoutControllerMixin {
  GlobalKey _floatingActionKey = GlobalKey();

  StreamSubscription? _upgradeTipListen;
  StreamSubscription? _dbOpenedSubscription;

  StreamSubscription? _contactMeUpdateSubscription;

  StreamSubscription? _clientStatusChangeSubscription;

  String? dbUpdateTip;
  bool dbOpen = false;

  ContactSchema? _contactMe;

  int clientConnectStatus = ClientConnectStatus.connecting;

  bool isLoginProgress = false;
  bool connected = false;

  // Profile setup dialog tracking
  bool _profileDialogShown = false;
  bool _profileDialogShowing = false;
  bool _profileSetupChecked =
      false; // Track if we've already checked for profile setup

  // Slideout state
  bool _isSlideoutVisible = false;
  List<SlideoutActionItem> _chatActions = [];

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();

    // Initialize chat-specific slideout actions
    _initializeChatActions();

    // Set initial slideout content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        updateSlideoutContent(_buildSlideout());
      }
    });

    // db
    _upgradeTipListen = dbCommon.upgradeTipStream.listen((String? tip) {
      setState(() {
        dbUpdateTip = tip;
      });
    });
    _dbOpenedSubscription = dbCommon.openedStream.listen((open) {
      setState(() {
        dbOpen = open;
      });
      if (open) _refreshContactMe(deviceInfo: true);
    });

    // contactMe
    _contactMeUpdateSubscription = contactCommon.meUpdateStream.listen((event) {
      _refreshContactMe();
    });

    // clientStatus
    _clientStatusChangeSubscription =
        clientCommon.statusStream.listen((int status) {
      if (clientConnectStatus != status) {
        setState(() {
          clientConnectStatus = status;
        });
      }
      // Check for profile setup when connected
      if (status == ClientConnectStatus.connected) {
        _checkAndShowProfileSetup();
      }
    });

    // login
    _tryLogin(init: true);
  }

  void _initializeChatActions() {
    _chatActions = [
      SlideoutActionItem(
        label: 'New Group',
        icon: Icons.group_add,
        color: Colors.blue,
        onTap: () {
          BottomDialog.of(Settings.appContext).showWithTitle(
            height: Settings.screenHeight() * 0.8,
            title: Settings.locale((s) => s.create_channel, ctx: context),
            child: ChatTopicSearchLayout(),
          );
        },
      ),
      SlideoutActionItem(
        label: 'Discover',
        icon: Icons.explore,
        color: Colors.green,
        onTap: () {
          NewDiscoveryScreen.go(context);
        },
      ),
      SlideoutActionItem(
        label: 'Scan QR',
        icon: Icons.qr_code_scanner,
        color: Colors.purple,
        onTap: () {
          // TODO: Implement QR scanner
          Toast.show('QR Scanner - Coming soon');
        },
      ),
      SlideoutActionItem(
        label: 'Broadcast',
        icon: Icons.campaign,
        color: Colors.orange,
        onTap: () {
          _showFloatActionMenu();
        },
      ),
    ];
  }

  @override
  void didPush() {
    // self push in, self show
    super.didPush();
  }

  @override
  void didPushNext() {
    // other push in, self hide
    super.didPushNext();
  }

  @override
  void didPopNext() {
    // other pop out, self show
    super.didPopNext();
  }

  @override
  void didPop() {
    // self pop out, self hide
    super.didPop();
  }

  @override
  void didChangeDependencies() {
    Routes.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _upgradeTipListen?.cancel();
    _dbOpenedSubscription?.cancel();
    _contactMeUpdateSubscription?.cancel();
    _clientStatusChangeSubscription?.cancel();
    Routes.routeObserver.unsubscribe(this);
    // Clear slideout content
    updateSlideoutContent(SizedBox.shrink());
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<bool> _tryLogin({WalletSchema? wallet, bool init = false}) async {
    if (clientCommon.isClientConnecting ||
        clientCommon.isClientReconnecting ||
        clientCommon.isClientOK) return true;
    if (isLoginProgress) return false;
    isLoginProgress = true;
    // view
    _setConnected(false);
    // wallet
    wallet = wallet ?? await walletCommon.getDefault();
    if (wallet == null) {
      // ui handle, ChatNoWalletLayout()
      logger.i("$TAG - _tryLogin - wallet default is empty");
      isLoginProgress = false;
      return false;
    }
    // client
    bool success = await clientCommon.signIn(wallet, toast: true,
        loading: (visible, input, dbOpen) {
      if (dbOpen) _setConnected(true);
    });
    // check
    if (success) chatCommon.startInitChecks(delay: 500); // await
    // view
    _setConnected(success);
    isLoginProgress = false;
    return success;
  }

  _setConnected(bool show) {
    if (connected != show) {
      connected = show; // no check mounted
      setState(() {
        connected = show;
      });
    }
  }

  _refreshContactMe({bool deviceInfo = false}) async {
    ContactSchema? contact = await contactCommon.getMe(
        selfAddress: clientCommon.address,
        canAdd: true,
        fetchWalletAddress: true);
    if ((contact == null) && mounted) {
      return await Future.delayed(Duration(milliseconds: 500), () {
        _refreshContactMe(deviceInfo: deviceInfo);
      });
    }
    setState(() {
      dbOpen = true;
      _contactMe = contact;
    });
    if (deviceInfo) {
      await deviceInfoCommon.getMe(
          selfAddress: contact?.address, canAdd: true, fetchDeviceToken: true);
    }
  }

  /// Check if profile setup is needed and show dialog
  Future<void> _checkAndShowProfileSetup() async {
    // DISABLED: Users now set up profile during onboarding flow
    // This automatic check is no longer needed and causes annoying prompts
    logger.d(
        "$TAG - _checkAndShowProfileSetup - DISABLED, profile setup handled in onboarding");
    return;

    // Only check once per session
    if (_profileSetupChecked) {
      logger.d("$TAG - _checkAndShowProfileSetup - already checked, skipping");
      return;
    }

    logger.d(
        "$TAG - _checkAndShowProfileSetup - dialogShown:$_profileDialogShown dialogShowing:$_profileDialogShowing");

    // Don't show if already shown or currently showing
    if (_profileDialogShown || _profileDialogShowing) {
      logger.d(
          "$TAG - _checkAndShowProfileSetup - skipping, already shown or showing");
      return;
    }

    // Mark as checked immediately to prevent duplicate checks
    _profileSetupChecked = true;

    // Set showing flag immediately to prevent race condition
    _profileDialogShowing = true;

    // Wait a bit to ensure app is fully loaded
    await Future.delayed(Duration(milliseconds: 500));

    if (!mounted) {
      logger.d("$TAG - _checkAndShowProfileSetup - widget not mounted");
      _profileDialogShowing = false;
      return;
    }

    ContactSchema? contact =
        await contactCommon.getMe(fetchWalletAddress: true);
    logger.d(
        "$TAG - _checkAndShowProfileSetup - contact: ${contact?.firstName ?? 'null'}");

    // Show dialog if:
    // 1. No contact exists, OR
    // 2. Contact exists but firstName is empty or is just the default derived name
    bool needsProfileSetup = false;
    if (contact == null) {
      needsProfileSetup = true;
      logger.d("$TAG - _checkAndShowProfileSetup - needs setup: no contact");
    } else if (contact.firstName.isEmpty) {
      needsProfileSetup = true;
      logger
          .d("$TAG - _checkAndShowProfileSetup - needs setup: empty firstName");
    } else {
      // Check if firstName is just the default derived name (first 6 chars of address)
      String defaultName = ContactSchema.getDefaultName(contact.address);
      logger.d(
          "$TAG - _checkAndShowProfileSetup - comparing: firstName='${contact.firstName}' vs defaultName='$defaultName'");
      if (contact.firstName == defaultName) {
        needsProfileSetup = true;
        logger.d(
            "$TAG - _checkAndShowProfileSetup - needs setup: default name '$defaultName'");
      } else {
        logger.d(
            "$TAG - _checkAndShowProfileSetup - username is set, no setup needed");
      }
    }

    if (!needsProfileSetup) {
      logger.d("$TAG - _checkAndShowProfileSetup - no setup needed");
      _profileDialogShowing = false;
      return;
    }

    if (!mounted) {
      _profileDialogShowing = false;
      return;
    }

    try {
      // Show profile setup dialog
      logger.d("$TAG - _checkAndShowProfileSetup - showing dialog");
      final completed = await ProfileSetupScreen.showAsDialog(context);

      _profileDialogShown = true;

      if (completed && mounted) {
        // Refresh contact to show updated profile
        _refreshContactMe();
        Toast.show('Profile setup completed!');
      }
    } catch (e) {
      logger.e("$TAG - _checkAndShowProfileSetup - error: $e");
    } finally {
      _profileDialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        // wallet loaded no
        if (!(state is WalletLoaded)) {
          return Container(
            child: SpinKitThreeBounce(
              color: Theme.of(context).colorScheme.primary,
              size: Settings.screenWidth() / 15,
            ),
          );
        }
        // wallet loaded yes
        if (state.isWalletsEmpty()) {
          return ChatNoWalletLayout();
        } else if (!dbOpen && (dbUpdateTip?.isNotEmpty == true)) {
          return _dbUpgradeTip();
        } else if (!connected || (state.defaultWallet() == null)) {
          return ChatNoConnectLayout((w) async {
            bool succeed = await _tryLogin(wallet: w);
            if (succeed) {
              _refreshContactMe(deviceInfo: true);
            }
          });
        }
        // client connected
        return Layout(
          headerColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).colorScheme.primary,
          bodyColor: Theme.of(context).scaffoldBackgroundColor,
          header: Header(
            titleChild: Container(
              margin: EdgeInsets.only(left: 20),
              child: _contactMe != null
                  ? ContactHeader(
                      contact: _contactMe!,
                      onTap: () {
                        ContactProfileScreen.go(context,
                            address: _contactMe?.address);
                      },
                      body: _headerBody(),
                    )
                  : SizedBox.shrink(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Asset.iconSvg('search', color: Colors.white, width: 24),
                  onPressed: () {
                    NewDiscoveryScreen.go(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon:
                      Asset.iconSvg('addbook', color: Colors.white, width: 24),
                  onPressed: () {
                    ContactHomeScreen.go(context);
                  },
                ),
              )
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 60, right: 4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                key: _floatingActionKey,
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    Icons.broadcast_on_personal,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  _showFloatActionMenu();
                },
              ),
            ),
          ),
          body: (_contactMe != null) && dbOpen
              ? ChatSessionListLayout(_contactMe!)
              : Container(
                  child: SpinKitThreeBounce(
                    color: Theme.of(context).colorScheme.primary,
                    size: Settings.screenWidth() / 15,
                  ),
                ),
        );
      },
    );
  }

  Widget _headerBody() {
    Widget statusWidget;
    switch (clientConnectStatus) {
      case ClientConnectStatus.connecting:
      case ClientConnectStatus.connectPing:
        statusWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Label(
              Settings.locale((s) => s.connecting, ctx: context),
              type: LabelType.h4,
              color: application.theme.fontLightColor.withAlpha(200),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 4),
              child: SpinKitThreeBounce(
                color: application.theme.fontLightColor.withAlpha(200),
                size: 10,
              ),
            ),
          ],
        );
        break;
      case ClientConnectStatus.connected:
        statusWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Label(
              Settings.locale((s) => s.connected, ctx: context),
              type: LabelType.h4,
              color: application.theme.successColor,
            ),
          ],
        );
        break;
      case ClientConnectStatus.disconnecting:
        statusWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Label(
              Settings.locale((s) => s.disconnect, ctx: context),
              type: LabelType.h4,
              color: application.theme.fontLightColor.withAlpha(200),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 4),
              child: SpinKitThreeBounce(
                color: application.theme.fontLightColor.withAlpha(200),
                size: 10,
              ),
            ),
          ],
        );
        break;
      case ClientConnectStatus.disconnected:
        statusWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Label(
              Settings.locale((s) => s.disconnect, ctx: context),
              type: LabelType.h4,
              color: application.theme.strongColor,
            ),
          ],
        );
        break;
      default:
        statusWidget = SizedBox.shrink();
        break;
    }
    return statusWidget;
  }

  _dbUpgradeTip() {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: Settings.screenHeight() / 4,
          minWidth: Settings.screenHeight() / 4,
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            CircularProgressIndicator(
              backgroundColor: Theme.of(context).cardColor,
            ),
            SizedBox(height: 25),
            Label(
              dbUpdateTip ?? "...",
              type: LabelType.display,
              textAlign: TextAlign.center,
              softWrap: true,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: 15),
            ((dbUpdateTip ?? "").length >= 3)
                ? Label(
                    Settings.locale((s) => s.upgrade_db_tips, ctx: context),
                    type: LabelType.display,
                    softWrap: true,
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  _showFloatActionMenu() {
    double btnSize = 48;

    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            if (Navigator.of(this.context).canPop())
              Navigator.pop(this.context);
          },
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.only(bottom: 67, right: 16),
              child: Row(
                children: [
                  Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: btnSize,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              color: Colors.black26,
                            ),
                            child: Label(
                              Settings.locale((s) => s.new_public_group,
                                  ctx: context),
                              height: 1.2,
                              type: LabelType.h4,
                              dark: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: btnSize,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              color: Colors.black26,
                            ),
                            child: Label(
                              'Public groups',
                              height: 1.2,
                              type: LabelType.h4,
                              dark: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      color: application.theme.primaryColor,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Button(
                          width: btnSize,
                          height: btnSize,
                          fontColor: application.theme.fontLightColor,
                          backgroundColor: application
                              .theme.backgroundLightColor
                              .withAlpha(77),
                          child: Asset.iconSvg('group',
                              width: 22,
                              color: application.theme.fontLightColor),
                          onPressed: () async {
                            if (Navigator.of(this.context).canPop())
                              Navigator.pop(this.context);
                            BottomDialog.of(Settings.appContext).showWithTitle(
                              height: Settings.screenHeight() * 0.8,
                              title: Settings.locale((s) => s.create_channel,
                                  ctx: context),
                              child: ChatTopicSearchLayout(),
                            );
                          },
                        ),
                        SizedBox(height: 10),
                        Button(
                          width: btnSize,
                          height: btnSize,
                          fontColor: application.theme.fontLightColor,
                          backgroundColor: application
                              .theme.backgroundLightColor
                              .withAlpha(77),
                          child: Asset.iconSvg('search',
                              width: 22,
                              color: application.theme.fontLightColor),
                          onPressed: () async {
                            if (Navigator.of(this.context).canPop())
                              Navigator.pop(this.context);
                            NewDiscoveryScreen.go(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build the horizontal slideout widget
  Widget _buildSlideout() {
    return HorizontalActionSlideout(
      items: _chatActions,
      isVisible: _isSlideoutVisible,
      onVisibilityChanged: (isVisible) {
        setState(() {
          _isSlideoutVisible = isVisible;
        });
      },
    );
  }
}
