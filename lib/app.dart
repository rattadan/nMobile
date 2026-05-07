import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_event.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/settings.dart';
import 'package:nchat_mobile/components/layout/nav.dart';
import 'package:nchat_mobile/components/layout/slideout_controller_provider.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/helpers/error.dart';
import 'package:nchat_mobile/helpers/share.dart';
import 'package:nchat_mobile/native/common.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/chat/home.dart';
import 'package:nchat_mobile/evm_screens/evm_token_dashboard_screen.dart';
import 'package:nchat_mobile/screens/settings/home.dart';
import 'package:nchat_mobile/services/task.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:nchat_mobile/screens/onboarding/profile_setup.dart';

class AppScreen extends StatefulWidget {
  static const String routeName = '/';
  static final String argIndex = "index";

  static go(BuildContext? context) {
    if (context == null) return;
    // return Navigator.pushNamed(context, routeName, arguments: {
    //   argIndex: index,
    // });
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  final Map<String, dynamic>? arguments;

  const AppScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> with WidgetsBindingObserver {
  List<Widget> screens = <Widget>[
    ChatHomeScreen(),
    EvmTokenDashboardScreen(),
    SettingsHomeScreen(),
  ];

  int _currentIndex = 0;
  late PageController _pageController;

  // Track slideout visibility for each page
  Map<int, bool> _slideoutVisibility = {
    0: false, // Chat page
    1: false, // EVM page
    2: false, // Settings page
  };

  // Slideout content controllers (to be set by child screens)
  final Map<int, Widget> _slideoutContent = {};

  StreamSubscription? _clientStatusChangeSubscription;
  StreamSubscription? _appLifeChangeSubscription;

  StreamSubscription? _intentDataTextStreamSubscription;
  StreamSubscription? _intentDataMediaStreamSubscription;

  bool firstConnect = true;
  bool _profileSetupDialogShown = false;

  Completer loginCompleter = Completer();

  bool isAuthProgress = false;

  // Method for child screens to update slideout content
  void updateSlideoutContent(int pageIndex, Widget content) {
    setState(() {
      _slideoutContent[pageIndex] = content;
    });
  }

  // Method for child screens to update slideout visibility
  void updateSlideoutVisibility(int pageIndex, bool isVisible) {
    setState(() {
      _slideoutVisibility[pageIndex] = isVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // init
    Settings.appContext = context; // before at mounted

    // mounted
    application.registerMounted(() async {
      application.init();
      clientCommon.init();
      BlocProvider.of<WalletBloc>(Settings.appContext).add(LoadWallet());
      // await backgroundFetchService.install();
      await localNotification.init();
      await audioHelper.init();
      await avatarCacheService.init();
    });
    application.mounted(); // await

    // page_controller
    this._currentIndex = widget.arguments != null
        ? (widget.arguments?[AppScreen.argIndex] ?? 0)
        : 0;
    _pageController = PageController(initialPage: this._currentIndex);

    // clientStatus
    _clientStatusChangeSubscription =
        clientCommon.statusStream.listen((int status) {
      _tryCompleteLogin();
      if (clientCommon.isClientOK) {
        // Initialize avatar broadcast service when client is connected
        avatarBroadcastService.init();

        // task add
        if (firstConnect) {
          firstConnect = false;
          // taskService.addTask(TaskService.KEY_CLIENT_CONNECT, 6, (key) => clientCommon.ping(), delayMs: 0);
          taskService.addTask(TaskService.KEY_SUBSCRIBE_CHECK, 50,
              (key) => topicCommon.checkAndTryAllSubscribe(),
              delayMs: 2 * 1000);
          taskService.addTask(TaskService.KEY_PERMISSION_CHECK, 50,
              (key) => topicCommon.checkAndTryAllPermission(),
              delayMs: 3 * 1000);

          // Show profile setup dialog on first connection if not completed
          _showProfileSetupIfNeeded();
        }
      } else if (clientCommon.isClientStop) {
        // task remove
        // taskService.removeTask(TaskService.KEY_CLIENT_CONNECT, 6);
        taskService.removeTask(TaskService.KEY_SUBSCRIBE_CHECK, 50);
        taskService.removeTask(TaskService.KEY_PERMISSION_CHECK, 50);
        firstConnect = true;
      }
    });

    // appLife
    _appLifeChangeSubscription =
        application.appLifeStream.listen((bool inBackground) {
      if (inBackground) {
        loginCompleter = Completer();
      } else {
        int gap = application.goForegroundAt - application.goBackgroundAt;
        if (gap >= Settings.gapClientReAuthMs) _tryAuth();
      }
    });

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataMediaStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile>? values) async {
      if (values == null || values.isEmpty) return;
      await loginCompleter.future;
      ShareHelper.showWithFiles(this.context, values);
    }, onError: (err, stack) {
      handleError(err, stack);
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile>? values) async {
      if (values == null || values.isEmpty) return;
      await loginCompleter.future;
      ShareHelper.showWithFiles(this.context, values);
    });

    // wallet
    taskService.addTask(TaskService.KEY_WALLET_BALANCE, 60,
        (key) => walletCommon.queryAllBalance(),
        delayMs: 1 * 1000);
  }

  @override
  void dispose() {
    _clientStatusChangeSubscription?.cancel();
    _appLifeChangeSubscription?.cancel();
    _intentDataTextStreamSubscription?.cancel();
    _intentDataMediaStreamSubscription?.cancel();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.i("AppScreen - didChangeAppLifecycleState - $state");
    AppLifecycleState old = application.appLifecycleState;
    application.appLifecycleState = state;
    super.didChangeAppLifecycleState(state);
    application.appLifeSink.add([old, state]);
  }

  Future<bool> _tryAuth() async {
    if (clientCommon.isClientStop) return false;
    if (isAuthProgress) return false;
    // view
    _setAuthProgress(true);
    AppScreen.go(this.context);
    // wallet
    WalletSchema? wallet = await walletCommon.getDefault();
    if (wallet == null) {
      logger.i("AppScreen - _tryAuth - wallet default is empty");
      // ui handle, ChatNoWalletLayout()
      await clientCommon.signOut(clearWallet: true, closeDB: true);
      _setAuthProgress(false);
      return false;
    }
    // password (do not prompt on connect; use stored password)
    String? password = await walletCommon.getPassword(wallet.address);
    if (!(await walletCommon.isPasswordRight(wallet.address, password))) {
      logger.i("AppScreen - _tryAuth - password error, close all");
      Toast.show(Settings.locale((s) => s.tip_password_error, ctx: context));
      await clientCommon.signOut(clearWallet: true, closeDB: true);
      _setAuthProgress(false);
      return false;
    }
    // view
    _setAuthProgress(false);
    // client
    clientCommon.reconnect(force: true).then((success) {
      if (success) chatCommon.startInitChecks(delay: 500); // await
    }); // await
    _tryCompleteLogin(); // await
    return true;
  }

  _setAuthProgress(bool progress) {
    application.inAuthProgress = progress;
    if (isAuthProgress != progress) {
      isAuthProgress = progress; // no check mounted
      setState(() {
        isAuthProgress = progress;
      });
    }
  }

  void _tryCompleteLogin() {
    if (clientCommon.isClientOK) {
      try {
        if (!(loginCompleter.isCompleted == true)) {
          loginCompleter.complete();
        }
      } catch (e, st) {
        handleError(e, st);
      }
    }
  }

  Future<void> _showProfileSetupIfNeeded() async {
    // Only show once per app session and only if not completed before
    if (_profileSetupDialogShown || Settings.profileSetupCompleted) {
      logger.d("AppScreen - Profile setup already shown or completed");
      return;
    }

    _profileSetupDialogShown = true;

    // Wait a bit for the UI to settle after connection
    await Future.delayed(Duration(milliseconds: 500));

    if (!mounted) return;

    logger.i(
        "AppScreen - Showing profile setup dialog after first NKN connection");

    try {
      final completed = await ProfileSetupScreen.showAsDialog(context);
      if (completed) {
        logger.i("AppScreen - Profile setup completed by user");
        await Settings.saveProfileSetupCompleted(true);
      } else {
        logger.i("AppScreen - Profile setup skipped by user");
        // Don't mark as completed if skipped, so it can be shown again next time
      }
    } catch (e, st) {
      logger.e("AppScreen - Error showing profile setup dialog: $e");
      handleError(e, st, toast: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          await Common.backDesktop();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            SlideoutControllerProvider(
              currentPageIndex: _currentIndex,
              updateSlideoutContent: updateSlideoutContent,
              updateSlideoutVisibility: updateSlideoutVisibility,
              child: PageView(
                controller: _pageController,
                onPageChanged: (n) {
                  setState(() {
                    _currentIndex = n;
                  });
                },
                children: screens,
              ),
            ),
            // footer nav
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: PhysicalModel(
                color: Theme.of(context).scaffoldBackgroundColor,
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                child: Nav(
                  currentIndex: _currentIndex,
                  screens: screens,
                  controller: _pageController,
                  slideoutContent: _slideoutContent,
                  slideoutVisibility: _slideoutVisibility,
                  onSlideoutVisibilityChanged: (pageIndex, isVisible) {
                    updateSlideoutVisibility(pageIndex, isVisible);
                  },
                ),
              ),
            ),
            isAuthProgress
                ? Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      child: Asset.image(
                        "splash/splash@3x.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
