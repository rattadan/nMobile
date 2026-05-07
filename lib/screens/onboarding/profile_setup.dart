import 'package:nchat_mobile/common/settings.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/contact/avatar_editable.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/schema/contact.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/storages/contact.dart';
import 'package:nchat_mobile/storages/wallet.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nchat_mobile/helpers/media_picker.dart';
import 'package:nchat_mobile/helpers/file.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';
import 'package:nchat_mobile/app.dart';

class ProfileSetupScreen extends BaseStateFulWidget {
  static const String routeName = '/profile/setup';

  static Future go(BuildContext? context) {
    if (context == null) return Future.value(null);
    return Navigator.pushNamed(context, routeName);
  }

  /// Show profile setup as a dialog (for first-time NKN connection)
  static Future<bool> showAsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: ProfileSetupDialogContent(
            onCompleted: () => Navigator.of(context).pop(true),
            onSkipped: () => Navigator.of(context).pop(false),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

/// Full screen profile setup state (for onboarding flow)
class _ProfileSetupScreenState
    extends BaseStateFulWidgetState<ProfileSetupScreen> with Tag {
  ContactSchema? _myContact;
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  File? _selectedAvatar;
  bool _isUploading = false;

  @override
  void onRefreshArguments() {
    // No arguments to refresh
  }

  @override
  void initState() {
    super.initState();
    _loadMyContact();
  }

  Future<void> _loadMyContact() async {
    try {
      WalletSchema? wallet = await walletCommon.getDefault();
      if (wallet != null) {
        logger
            .d("PROFILE_SETUP - Loading contact for wallet: ${wallet.address}");
        ContactSchema? contact =
            await contactCommon.getMe(fetchWalletAddress: true);

        logger.d("PROFILE_SETUP - Contact loaded: '${contact?.firstName}'");

        // If no contact exists, don't create a temporary one
        // Let the user create it through the save process
        setState(() {
          _myContact = contact;
          if (contact?.displayName.isNotEmpty == true) {
            _usernameController.text = contact!.displayName;
          }
        });

        logger.d(
            "PROFILE_SETUP - Contact set in state: '${_myContact?.firstName}'");
      }
    } catch (e) {
      logger.e("$TAG - Error loading contact: $e");
    }
  }

  Future<void> _selectAvatarPicture() async {
    try {
      // Get wallet address for path generation - retry a few times
      WalletSchema? wallet;
      for (int i = 0; i < 3; i++) {
        wallet = await walletCommon.getDefault();
        if (wallet != null) break;
        if (i < 2) {
          logger.d("Wallet not found, retrying... (${i + 1}/3)");
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      if (wallet == null) {
        logger.e("No wallet found for avatar selection after retries");
        Toast.show('Please wait a moment and try again');
        return;
      }

      String remarkAvatarPath = await Path.getRandomFile(
          clientCommon.getPublicKey(), DirType.profile,
          subPath: wallet.address, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
      String? remarkAvatarLocalPath = Path.convert2Local(remarkAvatarPath);
      if (remarkAvatarPath.isEmpty ||
          remarkAvatarLocalPath == null ||
          remarkAvatarLocalPath.isEmpty) {
        logger.e("Failed to create avatar file path");
        Toast.show('Failed to prepare image storage');
        return;
      }

      logger.d("Starting image picker with save path: $remarkAvatarPath");
      application.inSystemSelecting = true;

      File? picked = await MediaPicker.pickImage(
        cropRectangle: true,
        maxSize: Settings.sizeAvatarMax,
        bestSize: Settings.sizeAvatarBest,
        savePath: remarkAvatarPath,
      );

      application.inSystemSelecting = false;
      logger.d("Image picker completed. Picked: ${picked?.path}");

      if (picked == null) {
        logger.d("User cancelled image selection");
        return;
      }

      setState(() {
        _selectedAvatar = picked;
      });

      Toast.show('Photo selected successfully!');
    } catch (e, st) {
      logger.e("Error selecting avatar: $e");
      logger.e("Stack trace: $st");
      Toast.show('Failed to select photo: ${e.toString()}');
    }
  }

  Future<bool> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      Toast.show('Please enter a username');
      return false;
    }

    // Get wallet address for saving - retry a few times
    WalletSchema? wallet;
    for (int i = 0; i < 3; i++) {
      wallet = await walletCommon.getDefault();
      if (wallet != null) break;
      if (i < 2) {
        logger.d("Wallet not found, retrying... (${i + 1}/3)");
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    if (wallet == null) {
      Toast.show('Please wait a moment and try again');
      return false;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Wait for NKN client connection before saving username
      await _waitForClientConnection();

      String username = _usernameController.text.trim();

      // Ensure contact exists before saving so avatar/name updates target the
      // canonical self contact address (client pubkey), not the wallet address.
      if (_myContact == null) {
        logger.d(
            "PROFILE_SETUP - Creating new contact for wallet: ${wallet.address}");
        final String meAddress = clientCommon.getPublicKey() ?? "";
        _myContact = ContactSchema(
          address: meAddress.isNotEmpty ? meAddress : wallet.address,
          firstName: username,
          lastName: "",
          remarkName: username,
          type: ContactType.me,
        );
        await ContactStorage.instance.insert(_myContact!);
      }

      final String contactAddress = _myContact?.address ?? "";
      if (contactAddress.isEmpty) {
        Toast.show('Failed to resolve your profile identity');
        return false;
      }

      // Save avatar first if selected
      if (_selectedAvatar != null) {
        String? remarkAvatarLocalPath =
            Path.convert2Local(_selectedAvatar!.path);
        if (remarkAvatarLocalPath != null) {
          await contactCommon.setSelfAvatar(
              contactAddress, remarkAvatarLocalPath,
              notify: true);
        }
      }

      // Save username for self profile (firstName = account name, remarkName = chat nickname)
      logger.d(
          "PROFILE_SETUP - Saving username: '$username' for address: $contactAddress");

      // Save firstName, lastName (empty), and remarkName (chat nickname)
      // Use the contact's own address (pubkey) as the key so that the "me" contact
      // is updated correctly, not the wallet address.
      String? result;
      result = await contactCommon.setSelfFullName(contactAddress, username, "",
          notify: true);

      // Also set remarkName for chat nickname display
      await contactCommon.setOtherRemarkName(contactAddress, username,
          notify: true);

      logger.d("PROFILE_SETUP - Contact save result: $result");

      // Also update the wallet name to match the username
      WalletStorage walletStorage = WalletStorage();
      List<WalletSchema> wallets = await walletStorage.getAll();
      int walletIndex = wallets.indexWhere((w) => w.address == wallet?.address);
      if (walletIndex >= 0) {
        WalletSchema updatedWallet = wallets[walletIndex];
        updatedWallet.name = username; // Update wallet name
        await walletStorage.update(walletIndex, updatedWallet);
        logger.d("PROFILE_SETUP - Wallet name updated to: '$username'");

        // Notify wallet bloc of the update
        final walletBloc = BlocProvider.of<WalletBloc>(context);
        walletBloc.add(UpdateWallet(updatedWallet));
      }

      // Reload contact to verify the save and clear any cache
      await _loadMyContact();

      // Force refresh the contact in contactCommon to clear any cache and trigger notifications
      await contactCommon.queryAndNotify(contactAddress);

      // Also explicitly trigger meUpdateSink to ensure UI components update
      ContactSchema? updatedContact =
          await contactCommon.getMe(fetchWalletAddress: true);
      if (updatedContact != null) {
        // Double-check that firstName matches the username
        if (updatedContact.firstName != username) {
          logger.d(
              "PROFILE_SETUP - Fixing mismatch: firstName was '${updatedContact.firstName}', should be '$username'");
          await contactCommon.setSelfFullName(contactAddress, username, "",
              notify: true);
          updatedContact = await contactCommon.getMe(fetchWalletAddress: true);
        }
        contactCommon.meUpdateSink.add(updatedContact);
      }

      // Verify the username was saved
      if (_myContact != null) {
        logger.d(
            "PROFILE_SETUP - After save - firstName: '${_myContact!.firstName}' - displayName: '${_myContact!.displayName}'");
      }

      Toast.show('Profile saved successfully!');
      return true;
    } catch (e, st) {
      logger.e("Error saving profile: $e");
      logger.e("Stack trace: $st");
      Toast.show('Failed to save profile: ${e.toString()}');
      return false;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _waitForClientConnection() async {
    logger.d("PROFILE_SETUP - Waiting for NKN client connection...");

    // Wait up to 30 seconds for client connection
    int maxWaitTime = 30;
    int waitTime = 0;

    while (!clientCommon.isClientOK && waitTime < maxWaitTime) {
      logger
          .d("PROFILE_SETUP - Client not connected, waiting... (${waitTime}s)");
      await Future.delayed(Duration(seconds: 1));
      waitTime++;
    }

    if (clientCommon.isClientOK) {
      logger.d("PROFILE_SETUP - Client connected successfully!");
    } else {
      logger
          .w("PROFILE_SETUP - Client connection timeout, proceeding anyway...");
    }
  }

  void _skipSetup() {
    // Navigate to main app
    AppScreen.go(context);
  }

  void _completeSetup() async {
    final success = await _saveUsername();
    if (!success) return;
    await Settings.saveProfileSetupCompleted(true);
    if (mounted) {
      AppScreen.go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      headerColor: application.theme.backgroundColor4,
      header: Header(
        title: "Setup Your Profile",
        backgroundColor: application.theme.backgroundColor4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 32),
              decoration: BoxDecoration(
                color: application.theme.backgroundColor4,
              ),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Label(
                      "Let's personalize your profile",
                      type: LabelType.h4,
                      color: application.theme.fontColor1,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Label(
                      "Set a username and profile photo that other users will see in chat",
                      type: LabelType.bodySmall,
                      color: application.theme.fontColor2,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    /// avatar
                    GestureDetector(
                      onTap: _selectAvatarPicture,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: application.theme.backgroundLightColor,
                          border: Border.all(
                            color: application.theme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: _selectedAvatar != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedAvatar!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _myContact != null
                                ? ContactAvatarEditable(
                                    radius: 48,
                                    contact: _myContact!,
                                    placeHolder: false,
                                    onSelect: _selectAvatarPicture,
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: application.theme.fontColor2,
                                  ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _selectAvatarPicture,
                      child: Label(
                        "Tap to change photo",
                        type: LabelType.bodyRegular,
                        color: application.theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Stack(
              children: [
                Container(
                  height: 32,
                  decoration:
                      BoxDecoration(color: application.theme.backgroundColor4),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: application.theme.backgroundColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding:
                      EdgeInsets.only(left: 16, right: 16, top: 26, bottom: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Label(
                        "Your Username",
                        type: LabelType.h3,
                      ),
                      SizedBox(height: 8),
                      Label(
                        "Choose a username that other users will see",
                        type: LabelType.bodySmall,
                        color: application.theme.fontColor2,
                      ),
                      SizedBox(height: 16),

                      /// username input field
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        decoration: InputDecoration(
                          hintText: "Enter your username",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: application.theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: application.theme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: application.theme.backgroundLightColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: application.theme.fontColor1,
                        ),
                        maxLength: 30,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 32),

                      // Action buttons
                      Column(
                        children: [
                          Button(
                            text: _isUploading ? "Saving..." : "Complete Setup",
                            width: double.infinity,
                            backgroundColor: application.theme.primaryColor,
                            fontColor: Colors.white,
                            onPressed: _isUploading ? null : _completeSetup,
                          ),
                          SizedBox(height: 12),
                          Button(
                            text: "Skip for Now",
                            width: double.infinity,
                            backgroundColor:
                                application.theme.primaryColor.withAlpha(20),
                            fontColor: application.theme.primaryColor,
                            onPressed: _skipSetup,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog content widget for profile setup
class ProfileSetupDialogContent extends StatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  const ProfileSetupDialogContent({
    Key? key,
    required this.onCompleted,
    required this.onSkipped,
  }) : super(key: key);

  @override
  State<ProfileSetupDialogContent> createState() =>
      _ProfileSetupDialogContentState();
}

class _ProfileSetupDialogContentState extends State<ProfileSetupDialogContent>
    with Tag {
  ContactSchema? _myContact;
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  File? _selectedAvatar;
  bool _isUploading = false;
  bool _isClientConnected = false;
  StreamSubscription? _clientStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadMyContact();
    _listenToClientStatus();
  }

  void _listenToClientStatus() {
    _clientStatusSubscription = clientCommon.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isClientConnected = clientCommon.isClientOK;
        });
      }
      logger.d(
          "PROFILE_SETUP_DIALOG - Client status changed: $status, isClientOK: $_isClientConnected");
    });

    // Check initial connection status
    setState(() {
      _isClientConnected = clientCommon.isClientOK;
    });
  }

  @override
  void dispose() {
    _clientStatusSubscription?.cancel();
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMyContact() async {
    try {
      WalletSchema? wallet = await walletCommon.getDefault();
      if (wallet != null) {
        logger
            .d("PROFILE_SETUP - Loading contact for wallet: ${wallet.address}");
        ContactSchema? contact =
            await contactCommon.getMe(fetchWalletAddress: true);

        logger.d("PROFILE_SETUP - Contact loaded: '${contact?.firstName}'");

        // If no contact exists, don't create a temporary one
        // Let the user create it through the save process
        setState(() {
          _myContact = contact;
        });

        logger.d(
            "PROFILE_SETUP - Contact set in state: '${_myContact?.firstName}'");
      }
    } catch (e) {
      logger.e("$TAG - Error loading contact: $e");
    }
  }

  Future<void> _selectAvatarPicture() async {
    try {
      // Get wallet address for path generation - retry a few times
      WalletSchema? wallet;
      for (int i = 0; i < 3; i++) {
        wallet = await walletCommon.getDefault();
        if (wallet != null) break;
        if (i < 2) {
          logger.d("Wallet not found, retrying... (${i + 1}/3)");
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      if (wallet == null) {
        logger.e("No wallet found for avatar selection after retries");
        Toast.show('Please wait a moment and try again');
        return;
      }

      String remarkAvatarPath = await Path.getRandomFile(
          clientCommon.getPublicKey(), DirType.profile,
          subPath: wallet.address, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
      String? remarkAvatarLocalPath = Path.convert2Local(remarkAvatarPath);
      if (remarkAvatarPath.isEmpty ||
          remarkAvatarLocalPath == null ||
          remarkAvatarLocalPath.isEmpty) {
        logger.e("Failed to create avatar file path");
        Toast.show('Failed to prepare image storage');
        return;
      }

      logger.d("Starting image picker with save path: $remarkAvatarPath");
      application.inSystemSelecting = true;

      File? picked = await MediaPicker.pickImage(
        cropRectangle: true,
        maxSize: Settings.sizeAvatarMax,
        bestSize: Settings.sizeAvatarBest,
        savePath: remarkAvatarPath,
      );

      application.inSystemSelecting = false;
      logger.d("Image picker completed. Picked: ${picked?.path}");

      if (picked == null) {
        logger.d("User cancelled image selection");
        return;
      }

      setState(() {
        _selectedAvatar = picked;
      });

      Toast.show('Photo selected successfully!');
    } catch (e, st) {
      logger.e("Error selecting avatar: $e");
      logger.e("Stack trace: $st");
      Toast.show('Failed to select photo: ${e.toString()}');
    }
  }

  Future<bool> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      Toast.show('Please enter a username');
      return false;
    }

    // Get wallet address for saving - retry a few times
    WalletSchema? wallet;
    for (int i = 0; i < 3; i++) {
      wallet = await walletCommon.getDefault();
      if (wallet != null) break;
      if (i < 2) {
        logger.d("Wallet not found, retrying... (${i + 1}/3)");
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    if (wallet == null) {
      Toast.show('Please wait a moment and try again');
      return false;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      if (!_isClientConnected) {
        await _waitForClientConnection();
      }

      String username = _usernameController.text.trim();

      if (_myContact == null) {
        logger.d(
            "PROFILE_SETUP - Creating new contact for wallet: ${wallet.address}");
        final String meAddress = clientCommon.getPublicKey() ?? "";
        _myContact = ContactSchema(
          address: meAddress.isNotEmpty ? meAddress : wallet.address,
          firstName: username,
          lastName: "",
          remarkName: username,
          type: ContactType.me,
        );
        await ContactStorage.instance.insert(_myContact!);
      }

      final String contactAddress = _myContact?.address ?? "";
      if (contactAddress.isEmpty) {
        Toast.show('Failed to resolve your profile identity');
        return false;
      }

      // Save avatar first if selected
      if (_selectedAvatar != null) {
        String? remarkAvatarLocalPath =
            Path.convert2Local(_selectedAvatar!.path);
        if (remarkAvatarLocalPath != null) {
          await contactCommon.setSelfAvatar(
              contactAddress, remarkAvatarLocalPath,
              notify: true);
        }
      }

      // Save username for self profile (firstName = account name, remarkName = chat nickname)
      logger.d(
          "PROFILE_SETUP - Saving username: '$username' for address: $contactAddress");

      // Save firstName, lastName (empty), and remarkName (chat nickname)
      String? result = await contactCommon
          .setSelfFullName(contactAddress, username, "", notify: true);

      // Also set remarkName for chat nickname display
      await contactCommon.setOtherRemarkName(contactAddress, username,
          notify: true);

      logger.d("PROFILE_SETUP - Contact save result: $result");

      // Also update the wallet name to match the username
      WalletStorage walletStorage = WalletStorage();
      List<WalletSchema> wallets = await walletStorage.getAll();
      int walletIndex = wallets.indexWhere((w) => w.address == wallet?.address);
      if (walletIndex >= 0) {
        WalletSchema updatedWallet = wallets[walletIndex];
        updatedWallet.name = username; // Update wallet name
        await walletStorage.update(walletIndex, updatedWallet);
        logger.d("PROFILE_SETUP - Wallet name updated to: '$username'");

        // Notify wallet bloc of the update
        final walletBloc = BlocProvider.of<WalletBloc>(context);
        walletBloc.add(UpdateWallet(updatedWallet));
      }

      // Reload contact to verify the save and clear any cache
      await _loadMyContact();

      // Force refresh the contact in contactCommon to clear any cache and trigger notifications
      await contactCommon.queryAndNotify(contactAddress);

      // Also explicitly trigger meUpdateSink to ensure UI components update
      ContactSchema? updatedContact =
          await contactCommon.getMe(fetchWalletAddress: true);
      if (updatedContact != null) {
        // Double-check that firstName matches the username
        if (updatedContact.firstName != username) {
          logger.d(
              "PROFILE_SETUP - Fixing mismatch: firstName was '${updatedContact.firstName}', should be '$username'");
          await contactCommon.setSelfFullName(contactAddress, username, "",
              notify: true);
          updatedContact = await contactCommon.getMe(fetchWalletAddress: true);
        }
        contactCommon.meUpdateSink.add(updatedContact);
      }

      // Verify the username was saved
      if (_myContact != null) {
        logger.d(
            "PROFILE_SETUP - After save - firstName: '${_myContact!.firstName}' - displayName: '${_myContact!.displayName}'");
      }

      Toast.show('Profile saved successfully!');
      return true;
    } catch (e, st) {
      logger.e("Error saving profile: $e");
      logger.e("Stack trace: $st");
      Toast.show('Failed to save profile: ${e.toString()}');
      return false;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _waitForClientConnection() async {
    logger.d("PROFILE_SETUP - Waiting for NKN client connection...");

    // Wait up to 30 seconds for client connection
    int maxWaitTime = 30;
    int waitTime = 0;

    while (!clientCommon.isClientOK && waitTime < maxWaitTime) {
      logger
          .d("PROFILE_SETUP - Client not connected, waiting... (${waitTime}s)");
      await Future.delayed(Duration(seconds: 1));
      waitTime++;
    }

    if (clientCommon.isClientOK) {
      logger.d("PROFILE_SETUP - Client connected successfully!");
    } else {
      logger
          .w("PROFILE_SETUP - Client connection timeout, proceeding anyway...");
    }
  }

  void _skipSetup() {
    widget.onSkipped();
  }

  void _completeSetup() async {
    final success = await _saveUsername();
    if (!success) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              child: Column(
                children: [
                  Label(
                    "Setup Your Profile",
                    type: LabelType.h3,
                    color: application.theme.fontColor1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Label(
                    "Set a username and profile photo that other users will see in chat",
                    type: LabelType.bodySmall,
                    color: application.theme.fontColor2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Connection status indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _isClientConnected ? Icons.cloud_done : Icons.cloud_sync,
                    size: 16,
                    color: _isClientConnected
                        ? Colors.green
                        : application.theme.fontColor2,
                  ),
                  SizedBox(width: 8),
                  Label(
                    _isClientConnected
                        ? "Connected to NKN network"
                        : "Connecting to NKN network...",
                    type: LabelType.bodySmall,
                    color: _isClientConnected
                        ? Colors.green
                        : application.theme.fontColor2,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Avatar section
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selectAvatarPicture,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: application.theme.backgroundLightColor,
                          border: Border.all(
                            color: application.theme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: _selectedAvatar != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedAvatar!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _myContact != null
                                ? ContactAvatarEditable(
                                    radius: 48,
                                    contact: _myContact!,
                                    placeHolder: false,
                                    onSelect: _selectAvatarPicture,
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: application.theme.fontColor2,
                                  ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: _selectAvatarPicture,
                      child: Label(
                        "Tap to change photo",
                        type: LabelType.bodyRegular,
                        color: application.theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Username section
            Container(
              decoration: BoxDecoration(
                color: application.theme.backgroundLightColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding:
                  EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    "Your Username",
                    type: LabelType.h4,
                  ),
                  SizedBox(height: 4),
                  Label(
                    "Choose a username that other users will see",
                    type: LabelType.bodySmall,
                    color: application.theme.fontColor2,
                  ),
                  SizedBox(height: 12),

                  /// username input field
                  TextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    decoration: InputDecoration(
                      hintText: "Enter your username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: application.theme.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: application.theme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: application.theme.backgroundColor,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: application.theme.fontColor1,
                    ),
                    maxLength: 30,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      Button(
                        text: _isUploading ? "Saving..." : "Complete Setup",
                        width: double.infinity,
                        backgroundColor: application.theme.primaryColor,
                        fontColor: Colors.white,
                        onPressed: (_isUploading || !_isClientConnected)
                            ? null
                            : _completeSetup,
                      ),
                      SizedBox(height: 12),
                      Button(
                        text: "Skip for Now",
                        width: double.infinity,
                        backgroundColor:
                            application.theme.primaryColor.withAlpha(20),
                        fontColor: application.theme.primaryColor,
                        onPressed: _isUploading ? null : _skipSetup,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
