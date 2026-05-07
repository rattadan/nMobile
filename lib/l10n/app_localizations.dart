import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'nChat mobile'**
  String get app_name;

  /// No description provided for @d_chat.
  ///
  /// In en, this message translates to:
  /// **'D-Chat'**
  String get d_chat;

  /// No description provided for @menu_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get menu_home;

  /// No description provided for @menu_chat.
  ///
  /// In en, this message translates to:
  /// **'D-Chat'**
  String get menu_chat;

  /// No description provided for @menu_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menu_settings;

  /// No description provided for @menu_wallet.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get menu_wallet;

  /// No description provided for @menu_news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get menu_news;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @click_connect.
  ///
  /// In en, this message translates to:
  /// **'Click this button for connect'**
  String get click_connect;

  /// No description provided for @click_to_change.
  ///
  /// In en, this message translates to:
  /// **'Click to change'**
  String get click_to_change;

  /// No description provided for @click_to_settings.
  ///
  /// In en, this message translates to:
  /// **'Click to settings'**
  String get click_to_settings;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @top_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Top'**
  String get top_cancel;

  /// No description provided for @authenticate_to_access.
  ///
  /// In en, this message translates to:
  /// **'authenticate to access'**
  String get authenticate_to_access;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @language_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get language_auto;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @contact_us.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact_us;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @face_id.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get face_id;

  /// No description provided for @touch_id.
  ///
  /// In en, this message translates to:
  /// **'Touch ID'**
  String get touch_id;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @notification_type.
  ///
  /// In en, this message translates to:
  /// **'Notification Type'**
  String get notification_type;

  /// No description provided for @local_notification.
  ///
  /// In en, this message translates to:
  /// **'Local Notification'**
  String get local_notification;

  /// No description provided for @local_notification_only_name.
  ///
  /// In en, this message translates to:
  /// **'Only display name'**
  String get local_notification_only_name;

  /// No description provided for @local_notification_both_name_message.
  ///
  /// In en, this message translates to:
  /// **'Display name and message'**
  String get local_notification_both_name_message;

  /// No description provided for @local_notification_none_display.
  ///
  /// In en, this message translates to:
  /// **'None display'**
  String get local_notification_none_display;

  /// No description provided for @notification_sound.
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get notification_sound;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @read_and_agree_terms.
  ///
  /// In en, this message translates to:
  /// **'please read and agree to the Terms And Conditions Of Service / User Agreement.'**
  String get read_and_agree_terms;

  /// No description provided for @read_and_agree_terms_01.
  ///
  /// In en, this message translates to:
  /// **'read and agree to the '**
  String get read_and_agree_terms_01;

  /// No description provided for @read_and_agree_terms_02.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get read_and_agree_terms_02;

  /// No description provided for @cache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clear_cache;

  /// No description provided for @clear_database.
  ///
  /// In en, this message translates to:
  /// **'Clear Database'**
  String get clear_database;

  /// No description provided for @mainnet.
  ///
  /// In en, this message translates to:
  /// **'MAINNET'**
  String get mainnet;

  /// No description provided for @nkn.
  ///
  /// In en, this message translates to:
  /// **'NKN'**
  String get nkn;

  /// No description provided for @eth.
  ///
  /// In en, this message translates to:
  /// **'ETH'**
  String get eth;

  /// No description provided for @ethereum.
  ///
  /// In en, this message translates to:
  /// **'Ethereum'**
  String get ethereum;

  /// No description provided for @erc_20.
  ///
  /// In en, this message translates to:
  /// **'ERC-20'**
  String get erc_20;

  /// No description provided for @gwei.
  ///
  /// In en, this message translates to:
  /// **'GWEI'**
  String get gwei;

  /// No description provided for @gas_price.
  ///
  /// In en, this message translates to:
  /// **'Gas Price'**
  String get gas_price;

  /// No description provided for @gas_max.
  ///
  /// In en, this message translates to:
  /// **'Max Gas'**
  String get gas_max;

  /// No description provided for @nkn_mainnet.
  ///
  /// In en, this message translates to:
  /// **'NKN Mainnet'**
  String get nkn_mainnet;

  /// No description provided for @create_ethereum_wallet.
  ///
  /// In en, this message translates to:
  /// **'Create Ethereum Account'**
  String get create_ethereum_wallet;

  /// No description provided for @new_message.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get new_message;

  /// No description provided for @you_have_new_message.
  ///
  /// In en, this message translates to:
  /// **'You have a new message'**
  String get you_have_new_message;

  /// No description provided for @chat_no_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Private and Secure\n Messaging'**
  String get chat_no_wallet_title;

  /// No description provided for @chat_no_wallet_desc.
  ///
  /// In en, this message translates to:
  /// **'You need a Mainnet compatible wallet before you can use D-Chat.'**
  String get chat_no_wallet_desc;

  /// No description provided for @placeholder_draft.
  ///
  /// In en, this message translates to:
  /// **'[Draft]'**
  String get placeholder_draft;

  /// No description provided for @channel_invitation.
  ///
  /// In en, this message translates to:
  /// **'group invitation'**
  String get channel_invitation;

  /// No description provided for @accept_invitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get accept_invitation;

  /// No description provided for @joined_channel.
  ///
  /// In en, this message translates to:
  /// **'Joined group'**
  String get joined_channel;

  /// No description provided for @start_chat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get start_chat;

  /// No description provided for @wallet_name.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get wallet_name;

  /// No description provided for @hint_enter_wallet_name.
  ///
  /// In en, this message translates to:
  /// **'Enter wallet name'**
  String get hint_enter_wallet_name;

  /// No description provided for @wallet_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get wallet_password;

  /// No description provided for @input_password.
  ///
  /// In en, this message translates to:
  /// **'Enter your local password'**
  String get input_password;

  /// No description provided for @wallet_password_mach.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters. It is recommended to use a mix of different characters.'**
  String get wallet_password_mach;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @input_password_again.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get input_password_again;

  /// No description provided for @create_wallet.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_wallet;

  /// No description provided for @create_nkn_wallet.
  ///
  /// In en, this message translates to:
  /// **'Create Mainnet Account'**
  String get create_nkn_wallet;

  /// No description provided for @wallet_missing.
  ///
  /// In en, this message translates to:
  /// **'Wallet Info missing, Quit and ReImport.'**
  String get wallet_missing;

  /// No description provided for @my_wallets.
  ///
  /// In en, this message translates to:
  /// **'My Accounts'**
  String get my_wallets;

  /// No description provided for @import_wallet.
  ///
  /// In en, this message translates to:
  /// **'Import Account'**
  String get import_wallet;

  /// No description provided for @not_backed_up.
  ///
  /// In en, this message translates to:
  /// **'Not backed up yet'**
  String get not_backed_up;

  /// No description provided for @d_not_backed_up_title.
  ///
  /// In en, this message translates to:
  /// **'Important: Please Back Up\n Your Accounts!'**
  String get d_not_backed_up_title;

  /// No description provided for @d_not_backed_up_desc.
  ///
  /// In en, this message translates to:
  /// **'When you update your nChat mobile software or accidentally uninstall nChat mobile, your wallet might be lost and you might NOT be able to access your assets! So please take 3 minutes time now to back up all your wallets.'**
  String get d_not_backed_up_desc;

  /// No description provided for @go_backup.
  ///
  /// In en, this message translates to:
  /// **'Go Backup'**
  String get go_backup;

  /// No description provided for @private_key.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get private_key;

  /// No description provided for @public_key.
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get public_key;

  /// No description provided for @view_qrcode.
  ///
  /// In en, this message translates to:
  /// **'View QR Code'**
  String get view_qrcode;

  /// No description provided for @qrcode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrcode;

  /// No description provided for @seed_qrcode_dec.
  ///
  /// In en, this message translates to:
  /// **'Please save and backup your seed safely. Do not transfer via the internet. If you lose it you will lose access to your assets.'**
  String get seed_qrcode_dec;

  /// No description provided for @select_asset_to_backup.
  ///
  /// In en, this message translates to:
  /// **'Select Asset to Backup'**
  String get select_asset_to_backup;

  /// No description provided for @continue_text.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_text;

  /// No description provided for @verify_wallet_password.
  ///
  /// In en, this message translates to:
  /// **'Verify Account Password'**
  String get verify_wallet_password;

  /// No description provided for @password_wrong.
  ///
  /// In en, this message translates to:
  /// **'Account password or keystore file is wrong.'**
  String get password_wrong;

  /// No description provided for @keystore.
  ///
  /// In en, this message translates to:
  /// **'Keystore'**
  String get keystore;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @tab_seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get tab_seed;

  /// No description provided for @import_ethereum_wallet.
  ///
  /// In en, this message translates to:
  /// **'Import Ethereum Account'**
  String get import_ethereum_wallet;

  /// No description provided for @import_nkn_wallet.
  ///
  /// In en, this message translates to:
  /// **'Import Mainnet Account'**
  String get import_nkn_wallet;

  /// No description provided for @import_with_keystore_title.
  ///
  /// In en, this message translates to:
  /// **'Import with Keystore'**
  String get import_with_keystore_title;

  /// No description provided for @import_with_keystore_desc.
  ///
  /// In en, this message translates to:
  /// **'From your existing wallet, find out how to export keystore as well as associated password, make a backup of both, and then use both to import your existing wallet into nChat mobile.'**
  String get import_with_keystore_desc;

  /// No description provided for @input_keystore.
  ///
  /// In en, this message translates to:
  /// **'Please paste keystore'**
  String get input_keystore;

  /// No description provided for @import_with_seed_title.
  ///
  /// In en, this message translates to:
  /// **'Import with Seed'**
  String get import_with_seed_title;

  /// No description provided for @import_with_seed_desc.
  ///
  /// In en, this message translates to:
  /// **'From your existing wallet, find out how to export Seed (also called \"Secret Seed\"), make a backup copy, and then use it to import your existing wallet into nChat mobile.'**
  String get import_with_seed_desc;

  /// No description provided for @input_seed.
  ///
  /// In en, this message translates to:
  /// **'Please input seed'**
  String get input_seed;

  /// No description provided for @error_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get error_required;

  /// No description provided for @error_field_required.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String error_field_required(Object field);

  /// No description provided for @error_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Password does not match.'**
  String get error_confirm_password;

  /// No description provided for @error_keystore_format.
  ///
  /// In en, this message translates to:
  /// **'Keystore format does not match.'**
  String get error_keystore_format;

  /// No description provided for @error_seed_format.
  ///
  /// In en, this message translates to:
  /// **'Seed format does not match.'**
  String get error_seed_format;

  /// No description provided for @error_client_address_format.
  ///
  /// In en, this message translates to:
  /// **'Client address format does not match.'**
  String get error_client_address_format;

  /// No description provided for @error_nkn_address_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid wallet address.'**
  String get error_nkn_address_format;

  /// No description provided for @error_unknown_nkn_qrcode.
  ///
  /// In en, this message translates to:
  /// **'Unknown NKN qr code.'**
  String get error_unknown_nkn_qrcode;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @send_to.
  ///
  /// In en, this message translates to:
  /// **'Send To'**
  String get send_to;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enter_amount;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @enter_receive_address.
  ///
  /// In en, this message translates to:
  /// **'Enter receive address'**
  String get enter_receive_address;

  /// No description provided for @transfer_initiated.
  ///
  /// In en, this message translates to:
  /// **'Transfer Initiated'**
  String get transfer_initiated;

  /// No description provided for @transfer_initiated_desc.
  ///
  /// In en, this message translates to:
  /// **'Your transfer is in progress. It could take a few seconds to appear on the blockchain.'**
  String get transfer_initiated_desc;

  /// No description provided for @transfer_speed_up_fee.
  ///
  /// In en, this message translates to:
  /// **'Setting a reasonable NKN can speed up the transaction process.'**
  String get transfer_speed_up_fee;

  /// No description provided for @topic_new_speed_up_auto.
  ///
  /// In en, this message translates to:
  /// **'Public group chat subscription is turned on and auto-accelerate.'**
  String get topic_new_speed_up_auto;

  /// No description provided for @topic_new_speed_up_auto_no.
  ///
  /// In en, this message translates to:
  /// **'Public group chat subscription is turned on and does not auto-accelerate.'**
  String get topic_new_speed_up_auto_no;

  /// No description provided for @topic_renewal_speed_up_auto.
  ///
  /// In en, this message translates to:
  /// **'Public group chat renewal is turned on and auto-accelerate.'**
  String get topic_renewal_speed_up_auto;

  /// No description provided for @topic_renewal_speed_up_auto_no.
  ///
  /// In en, this message translates to:
  /// **'Public group chat renewal is turned on and does not auto-accelerate.'**
  String get topic_renewal_speed_up_auto_no;

  /// No description provided for @transfer_speed_up_desc.
  ///
  /// In en, this message translates to:
  /// **'The acceleration function requires additional NKN, please make sure you have enough NKN in your wallet.'**
  String get transfer_speed_up_desc;

  /// No description provided for @transfer_speed_up_enable.
  ///
  /// In en, this message translates to:
  /// **'Whether to enable acceleration'**
  String get transfer_speed_up_enable;

  /// No description provided for @pay_nkn.
  ///
  /// In en, this message translates to:
  /// **'Pay NKN amount'**
  String get pay_nkn;

  /// No description provided for @accelerate.
  ///
  /// In en, this message translates to:
  /// **'Accelerate'**
  String get accelerate;

  /// No description provided for @accelerate_no.
  ///
  /// In en, this message translates to:
  /// **'no accelerate'**
  String get accelerate_no;

  /// No description provided for @topic_subscribe_enable.
  ///
  /// In en, this message translates to:
  /// **'Public group subscription'**
  String get topic_subscribe_enable;

  /// No description provided for @topic_resubscribe_enable.
  ///
  /// In en, this message translates to:
  /// **'Public group renewal'**
  String get topic_resubscribe_enable;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @main_wallet.
  ///
  /// In en, this message translates to:
  /// **'Main Account'**
  String get main_wallet;

  /// No description provided for @export_wallet.
  ///
  /// In en, this message translates to:
  /// **'Export Account'**
  String get export_wallet;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @send_nkn.
  ///
  /// In en, this message translates to:
  /// **'Send NKN'**
  String get send_nkn;

  /// No description provided for @send_eth.
  ///
  /// In en, this message translates to:
  /// **'Send Eth'**
  String get send_eth;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @wallet_address.
  ///
  /// In en, this message translates to:
  /// **'Account Address'**
  String get wallet_address;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copy_success.
  ///
  /// In en, this message translates to:
  /// **'Copied to Clipboard'**
  String get copy_success;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copy_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copy_to_clipboard;

  /// No description provided for @delete_wallet.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_wallet;

  /// No description provided for @delete_wallet_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get delete_wallet_confirm_title;

  /// No description provided for @delete_wallet_confirm_text.
  ///
  /// In en, this message translates to:
  /// **'This will remove the account off your local device. Please make sure your account is fully backed up or you will lose your funds.'**
  String get delete_wallet_confirm_text;

  /// No description provided for @delete_message_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get delete_message_confirm_title;

  /// No description provided for @delete_contact_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this contact?'**
  String get delete_contact_confirm_title;

  /// No description provided for @delete_friend_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this friend?'**
  String get delete_friend_confirm_title;

  /// No description provided for @leave_group_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get leave_group_confirm_title;

  /// No description provided for @delete_cache_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete cache?'**
  String get delete_cache_confirm_title;

  /// No description provided for @delete_db_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the database?'**
  String get delete_db_confirm_title;

  /// No description provided for @delete_device_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this device?'**
  String get delete_device_confirm_title;

  /// No description provided for @delete_session_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get delete_session_confirm_title;

  /// No description provided for @delete_mapping_address_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get delete_mapping_address_confirm_title;

  /// No description provided for @select_asset_to_send.
  ///
  /// In en, this message translates to:
  /// **'Select Asset to Send'**
  String get select_asset_to_send;

  /// No description provided for @select_asset_to_receive.
  ///
  /// In en, this message translates to:
  /// **'Select Asset to Receive'**
  String get select_asset_to_receive;

  /// No description provided for @select_another_wallet.
  ///
  /// In en, this message translates to:
  /// **'Select Another Account'**
  String get select_another_wallet;

  /// No description provided for @select_wallet_type.
  ///
  /// In en, this message translates to:
  /// **'Select Account Type'**
  String get select_wallet_type;

  /// No description provided for @select_wallet_type_desc.
  ///
  /// In en, this message translates to:
  /// **'Select whether to create/import a NKN Mainnet wallet or an Ethereum based wallet to hold ERC-20 tokens. The two are not compatible.'**
  String get select_wallet_type_desc;

  /// No description provided for @no_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Keep your NKN organised'**
  String get no_wallet_title;

  /// No description provided for @no_wallet_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage both your Mainnet NKN\n tokens with our smart wallet manager.'**
  String get no_wallet_desc;

  /// No description provided for @no_wallet_create.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get no_wallet_create;

  /// No description provided for @no_wallet_import.
  ///
  /// In en, this message translates to:
  /// **'Import Existing Account'**
  String get no_wallet_import;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @stranger.
  ///
  /// In en, this message translates to:
  /// **'Stranger'**
  String get stranger;

  /// No description provided for @my_contact.
  ///
  /// In en, this message translates to:
  /// **'My Contact'**
  String get my_contact;

  /// No description provided for @add_contact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get add_contact;

  /// No description provided for @edit_contact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get edit_contact;

  /// No description provided for @delete_contact.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get delete_contact;

  /// No description provided for @delete_session.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get delete_session;

  /// No description provided for @contact_no_contact_title.
  ///
  /// In en, this message translates to:
  /// **'You haven’t got any\n contacts yet'**
  String get contact_no_contact_title;

  /// No description provided for @contact_no_contact_desc.
  ///
  /// In en, this message translates to:
  /// **'Use your contact list to quickly message and\n send funds to your friends.'**
  String get contact_no_contact_desc;

  /// No description provided for @type_a_message.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get type_a_message;

  /// No description provided for @pictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get pictures;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @save_to_album.
  ///
  /// In en, this message translates to:
  /// **'Save To Album'**
  String get save_to_album;

  /// No description provided for @invitation_sent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get invitation_sent;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @data_synchronization.
  ///
  /// In en, this message translates to:
  /// **'data synchronization'**
  String get data_synchronization;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @edit_name.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get edit_name;

  /// No description provided for @edit_nickname.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get edit_nickname;

  /// No description provided for @expiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @input_nickname.
  ///
  /// In en, this message translates to:
  /// **'Please input Nickname'**
  String get input_nickname;

  /// No description provided for @input_pubKey.
  ///
  /// In en, this message translates to:
  /// **'Please input Public Key'**
  String get input_pubKey;

  /// No description provided for @input_name.
  ///
  /// In en, this message translates to:
  /// **'Please input Name'**
  String get input_name;

  /// No description provided for @input_wallet_address.
  ///
  /// In en, this message translates to:
  /// **'Please input Account Address'**
  String get input_wallet_address;

  /// No description provided for @input_notes.
  ///
  /// In en, this message translates to:
  /// **'Please input Notes'**
  String get input_notes;

  /// No description provided for @invitee_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Invitee already exists'**
  String get invitee_already_exists;

  /// No description provided for @edit_notes.
  ///
  /// In en, this message translates to:
  /// **'Edit Notes'**
  String get edit_notes;

  /// No description provided for @view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get view_all;

  /// No description provided for @latest_transactions.
  ///
  /// In en, this message translates to:
  /// **'Latest Transactions'**
  String get latest_transactions;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'nChat mobile'**
  String get title;

  /// No description provided for @my_details.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get my_details;

  /// No description provided for @wallet_password_helper_text.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters. It is recommended to use a mix of different characters.'**
  String get wallet_password_helper_text;

  /// No description provided for @wallet_password_error.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters. It is recommended to use a mix of different characters.'**
  String get wallet_password_error;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save_contact.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get save_contact;

  /// No description provided for @view_channel_members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get view_channel_members;

  /// No description provided for @invite_members.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get invite_members;

  /// No description provided for @total_balance.
  ///
  /// In en, this message translates to:
  /// **'TOTAL BALANCE'**
  String get total_balance;

  /// No description provided for @eth_wallet.
  ///
  /// In en, this message translates to:
  /// **'Eth Account'**
  String get eth_wallet;

  /// No description provided for @enter_first_name.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enter_first_name;

  /// No description provided for @enter_last_name.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enter_last_name;

  /// No description provided for @enter_users_address.
  ///
  /// In en, this message translates to:
  /// **'Enter users address'**
  String get enter_users_address;

  /// No description provided for @enter_topic.
  ///
  /// In en, this message translates to:
  /// **'Enter topic'**
  String get enter_topic;

  /// No description provided for @new_whisper.
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get new_whisper;

  /// No description provided for @new_public_group.
  ///
  /// In en, this message translates to:
  /// **'New Public Group'**
  String get new_public_group;

  /// No description provided for @new_private_group.
  ///
  /// In en, this message translates to:
  /// **'New Private Group'**
  String get new_private_group;

  /// No description provided for @create_channel.
  ///
  /// In en, this message translates to:
  /// **'Create/Join to group'**
  String get create_channel;

  /// No description provided for @create_private_group.
  ///
  /// In en, this message translates to:
  /// **'Create Private Group'**
  String get create_private_group;

  /// No description provided for @private_channel.
  ///
  /// In en, this message translates to:
  /// **'Private Group'**
  String get private_channel;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @channel_settings.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get channel_settings;

  /// No description provided for @channel_members.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get channel_members;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @address_book.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get address_book;

  /// No description provided for @popular_channels.
  ///
  /// In en, this message translates to:
  /// **'Popular Groups'**
  String get popular_channels;

  /// No description provided for @my_group.
  ///
  /// In en, this message translates to:
  /// **'My Group'**
  String get my_group;

  /// No description provided for @chat_settings.
  ///
  /// In en, this message translates to:
  /// **'D-Chat Settings'**
  String get chat_settings;

  /// No description provided for @view_profile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get view_profile;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recent;

  /// No description provided for @burn_after_reading.
  ///
  /// In en, this message translates to:
  /// **'Burn After Reading'**
  String get burn_after_reading;

  /// No description provided for @accept_notification.
  ///
  /// In en, this message translates to:
  /// **'When turned on, you will receive immediate notification when this person sends you messages.'**
  String get accept_notification;

  /// No description provided for @setting_deny_notification.
  ///
  /// In en, this message translates to:
  /// **'Have Denied Remote Notification'**
  String get setting_deny_notification;

  /// No description provided for @setting_accept_notification.
  ///
  /// In en, this message translates to:
  /// **'Have Accepted Remote Notification'**
  String get setting_accept_notification;

  /// No description provided for @notification_push_content.
  ///
  /// In en, this message translates to:
  /// **'New Message!'**
  String get notification_push_content;

  /// No description provided for @remote_notification.
  ///
  /// In en, this message translates to:
  /// **'Message Notification'**
  String get remote_notification;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get app_version;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @client_address.
  ///
  /// In en, this message translates to:
  /// **'Client Address'**
  String get client_address;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// No description provided for @updated_at.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updated_at;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get members;

  /// No description provided for @invites_desc_me.
  ///
  /// In en, this message translates to:
  /// **'{other} invites You to join group'**
  String invites_desc_me(Object other);

  /// No description provided for @invites_desc_other.
  ///
  /// In en, this message translates to:
  /// **'You invites {other} to join group'**
  String invites_desc_other(Object other);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get accepted;

  /// No description provided for @accepted_already.
  ///
  /// In en, this message translates to:
  /// **'You have already accepted'**
  String get accepted_already;

  /// No description provided for @other_accepted_already.
  ///
  /// In en, this message translates to:
  /// **'{other} have already accepted'**
  String other_accepted_already(Object other);

  /// No description provided for @waiting_for_sync_data.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sync data'**
  String get waiting_for_sync_data;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get rejected;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pending;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscribe_or_waiting.
  ///
  /// In en, this message translates to:
  /// **'Subscribe or Waiting...'**
  String get subscribe_or_waiting;

  /// No description provided for @subscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get subscribed;

  /// No description provided for @unsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get unsubscribe;

  /// No description provided for @unsubscribed.
  ///
  /// In en, this message translates to:
  /// **'Leaved'**
  String get unsubscribed;

  /// No description provided for @news_from.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get news_from;

  /// No description provided for @chat_tab_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chat_tab_messages;

  /// No description provided for @chat_tab_channels.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get chat_tab_channels;

  /// No description provided for @chat_tab_group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get chat_tab_group;

  /// No description provided for @chat_no_messages_title.
  ///
  /// In en, this message translates to:
  /// **'Private and Secure\nMessaging'**
  String get chat_no_messages_title;

  /// No description provided for @chat_no_messages_desc.
  ///
  /// In en, this message translates to:
  /// **'Start a new direct message or group chat, or join\nexisting ones..'**
  String get chat_no_messages_desc;

  /// No description provided for @update_burn_after_reading.
  ///
  /// In en, this message translates to:
  /// **'set the disappearing message timer'**
  String get update_burn_after_reading;

  /// No description provided for @close_burn_after_reading.
  ///
  /// In en, this message translates to:
  /// **'disabled disappearing messages'**
  String get close_burn_after_reading;

  /// No description provided for @burn_5_seconds.
  ///
  /// In en, this message translates to:
  /// **'5 seconds'**
  String get burn_5_seconds;

  /// No description provided for @burn_10_seconds.
  ///
  /// In en, this message translates to:
  /// **'10 seconds'**
  String get burn_10_seconds;

  /// No description provided for @burn_30_seconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get burn_30_seconds;

  /// No description provided for @burn_1_minute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get burn_1_minute;

  /// No description provided for @burn_5_minutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get burn_5_minutes;

  /// No description provided for @burn_10_minutes.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get burn_10_minutes;

  /// No description provided for @burn_30_minutes.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get burn_30_minutes;

  /// No description provided for @burn_1_hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get burn_1_hour;

  /// No description provided for @burn_6_hour.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get burn_6_hour;

  /// No description provided for @burn_12_hour.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get burn_12_hour;

  /// No description provided for @burn_1_day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get burn_1_day;

  /// No description provided for @burn_1_week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get burn_1_week;

  /// No description provided for @add_new_contact.
  ///
  /// In en, this message translates to:
  /// **'Add New Contact'**
  String get add_new_contact;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @private_messages.
  ///
  /// In en, this message translates to:
  /// **'Private Messages'**
  String get private_messages;

  /// No description provided for @private_messages_desc.
  ///
  /// In en, this message translates to:
  /// **'All direct messages are completely private and secure.'**
  String get private_messages_desc;

  /// No description provided for @learn_more.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learn_more;

  /// No description provided for @enter_or_select_a_user_pubkey.
  ///
  /// In en, this message translates to:
  /// **'Enter/Select a user D-Chat ID'**
  String get enter_or_select_a_user_pubkey;

  /// No description provided for @scan_show_me_desc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code pattern to add friends to your contacts.'**
  String get scan_show_me_desc;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @d_chat_address.
  ///
  /// In en, this message translates to:
  /// **'D-Chat ID'**
  String get d_chat_address;

  /// No description provided for @input_d_chat_address.
  ///
  /// In en, this message translates to:
  /// **'Please input D-Chat ID'**
  String get input_d_chat_address;

  /// No description provided for @tip_password_error.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get tip_password_error;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friends;

  /// No description provided for @group_chat.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group_chat;

  /// No description provided for @d_chat_not_login.
  ///
  /// In en, this message translates to:
  /// **'D-Chat not login'**
  String get d_chat_not_login;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @import_wallet_as_account.
  ///
  /// In en, this message translates to:
  /// **'Import Account'**
  String get import_wallet_as_account;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tip;

  /// No description provided for @change_default_chat_wallet.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change_default_chat_wallet;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon...'**
  String get coming_soon;

  /// No description provided for @my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get my_profile;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @send_message.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get send_message;

  /// No description provided for @show_wallet_address_desc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code, you can transfer it to me'**
  String get show_wallet_address_desc;

  /// No description provided for @account_switching_completed.
  ///
  /// In en, this message translates to:
  /// **'Account switching Completed'**
  String get account_switching_completed;

  /// No description provided for @storage_text.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage_text;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @eth_keystore_export_desc.
  ///
  /// In en, this message translates to:
  /// **'The current version does not support ERC20 Token transactions. Please export this wallet keystore for backup immediately.'**
  String get eth_keystore_export_desc;

  /// No description provided for @burn_after_reading_desc_disappear.
  ///
  /// In en, this message translates to:
  /// **'Messages sent and received in this conversation will disappear {time} after they have been seen.'**
  String burn_after_reading_desc_disappear(Object time);

  /// No description provided for @burn_after_reading_desc.
  ///
  /// In en, this message translates to:
  /// **'Your messages will not expire.'**
  String get burn_after_reading_desc;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong! Please try again later.'**
  String get something_went_wrong;

  /// No description provided for @unavailable_device.
  ///
  /// In en, this message translates to:
  /// **'unsupported device'**
  String get unavailable_device;

  /// No description provided for @slide_to_cancel.
  ///
  /// In en, this message translates to:
  /// **'< Slide Cancel <'**
  String get slide_to_cancel;

  /// No description provided for @invite_and_send_success.
  ///
  /// In en, this message translates to:
  /// **'invite and send success'**
  String get invite_and_send_success;

  /// No description provided for @join_but_not_invite.
  ///
  /// In en, this message translates to:
  /// **'not invited'**
  String get join_but_not_invite;

  /// No description provided for @inviting.
  ///
  /// In en, this message translates to:
  /// **'inviting'**
  String get inviting;

  /// No description provided for @subscribing.
  ///
  /// In en, this message translates to:
  /// **'subscribing'**
  String get subscribing;

  /// No description provided for @need_re_subscribe.
  ///
  /// In en, this message translates to:
  /// **'Need to re-subscribe'**
  String get need_re_subscribe;

  /// No description provided for @invited_already.
  ///
  /// In en, this message translates to:
  /// **'You have already invited this member,still invite?'**
  String get invited_already;

  /// No description provided for @group_member_already.
  ///
  /// In en, this message translates to:
  /// **'The member is in group already'**
  String get group_member_already;

  /// No description provided for @invite_yourself_error.
  ///
  /// In en, this message translates to:
  /// **'Can not invite yourself!'**
  String get invite_yourself_error;

  /// No description provided for @kick_yourself_error.
  ///
  /// In en, this message translates to:
  /// **'Can not kick yourself!'**
  String get kick_yourself_error;

  /// No description provided for @member_no_auth_invite.
  ///
  /// In en, this message translates to:
  /// **'Private group member can not invite others currently,ask group owner to invite others'**
  String get member_no_auth_invite;

  /// No description provided for @tip_open_send_device_token.
  ///
  /// In en, this message translates to:
  /// **'Whether to open the notification reminder from the other party?'**
  String get tip_open_send_device_token;

  /// No description provided for @tip_switch_success.
  ///
  /// In en, this message translates to:
  /// **'Switch Success!'**
  String get tip_switch_success;

  /// No description provided for @tip_ask_group_owner_permission.
  ///
  /// In en, this message translates to:
  /// **'You are not in this group,ask the group owner for permission'**
  String get tip_ask_group_owner_permission;

  /// No description provided for @member_already_no_permission.
  ///
  /// In en, this message translates to:
  /// **'This member is no longer in the group'**
  String get member_already_no_permission;

  /// No description provided for @left_group_tip.
  ///
  /// In en, this message translates to:
  /// **'Left the group, please try again later.'**
  String get left_group_tip;

  /// No description provided for @removed_group_tip.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group, please contact the owner to invite you'**
  String get removed_group_tip;

  /// No description provided for @contact_invite_group_tip.
  ///
  /// In en, this message translates to:
  /// **'Please contact the owner to invite you'**
  String get contact_invite_group_tip;

  /// No description provided for @request_processed.
  ///
  /// In en, this message translates to:
  /// **'Requests still being processed, please try again later'**
  String get request_processed;

  /// No description provided for @blocked_user_disallow_invite.
  ///
  /// In en, this message translates to:
  /// **'The user has been blocked, and ordinary members are not allowed to invite'**
  String get blocked_user_disallow_invite;

  /// No description provided for @confirm_resend.
  ///
  /// In en, this message translates to:
  /// **'Confirm resend?'**
  String get confirm_resend;

  /// No description provided for @release_to_cancel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get release_to_cancel;

  /// No description provided for @has_left_the_group.
  ///
  /// In en, this message translates to:
  /// **'Left group'**
  String get has_left_the_group;

  /// No description provided for @reject_user_tip.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this user?'**
  String get reject_user_tip;

  /// No description provided for @file_too_big.
  ///
  /// In en, this message translates to:
  /// **'The file is too big'**
  String get file_too_big;

  /// No description provided for @file_not_exist.
  ///
  /// In en, this message translates to:
  /// **'The file does not exist'**
  String get file_not_exist;

  /// No description provided for @file_too_many.
  ///
  /// In en, this message translates to:
  /// **'Upload up to {limit} images at a time'**
  String file_too_many(Object limit);

  /// No description provided for @add_user_duplicated.
  ///
  /// In en, this message translates to:
  /// **'The user has been added'**
  String get add_user_duplicated;

  /// No description provided for @confirm_unsubscribe_group.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the group chat?'**
  String get confirm_unsubscribe_group;

  /// No description provided for @balance_not_enough.
  ///
  /// In en, this message translates to:
  /// **'Balance not enough'**
  String get balance_not_enough;

  /// No description provided for @group_no_exist.
  ///
  /// In en, this message translates to:
  /// **'private group no exist'**
  String get group_no_exist;

  /// No description provided for @invitation_has_expired.
  ///
  /// In en, this message translates to:
  /// **'invitation has expired'**
  String get invitation_has_expired;

  /// No description provided for @invitation_information_error.
  ///
  /// In en, this message translates to:
  /// **'invitation information error'**
  String get invitation_information_error;

  /// No description provided for @invitation_signature_error.
  ///
  /// In en, this message translates to:
  /// **'invitation signature error'**
  String get invitation_signature_error;

  /// No description provided for @waiting_for_data_to_sync.
  ///
  /// In en, this message translates to:
  /// **'waiting for data to sync'**
  String get waiting_for_data_to_sync;

  /// No description provided for @no_permission_join_group.
  ///
  /// In en, this message translates to:
  /// **'Have not been granted permission to join the group, please try again later.'**
  String get no_permission_join_group;

  /// No description provided for @no_permission_action.
  ///
  /// In en, this message translates to:
  /// **'Not authorized to perform this operation'**
  String get no_permission_action;

  /// No description provided for @need_microphone_permission.
  ///
  /// In en, this message translates to:
  /// **'Need microphone permission'**
  String get need_microphone_permission;

  /// No description provided for @upgrade_db_tips.
  ///
  /// In en, this message translates to:
  /// **'During the database upgrade, please do not exit the app or leave this page.'**
  String get upgrade_db_tips;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @mapped_address_does_not_match.
  ///
  /// In en, this message translates to:
  /// **'Mapped address does not match'**
  String get mapped_address_does_not_match;

  /// No description provided for @mapped_address.
  ///
  /// In en, this message translates to:
  /// **'Mapped address'**
  String get mapped_address;

  /// No description provided for @only_owner_can_modify.
  ///
  /// In en, this message translates to:
  /// **'Only the group owner can modify this item'**
  String get only_owner_can_modify;

  /// No description provided for @confirm_delete_remark_avatar.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the note avatar?'**
  String get confirm_delete_remark_avatar;

  /// No description provided for @tracker.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get tracker;

  /// No description provided for @notification_push.
  ///
  /// In en, this message translates to:
  /// **'Notification Push'**
  String get notification_push;

  /// No description provided for @error_tracking.
  ///
  /// In en, this message translates to:
  /// **'Error Tracking'**
  String get error_tracking;

  /// No description provided for @allow_push_message_notifications_to_others.
  ///
  /// In en, this message translates to:
  /// **'Allow push message notifications to others'**
  String get allow_push_message_notifications_to_others;

  /// No description provided for @do_not_allow_push_message_notifications_to_others.
  ///
  /// In en, this message translates to:
  /// **'Do not allow push message notifications to others'**
  String get do_not_allow_push_message_notifications_to_others;

  /// No description provided for @allow_uploading_application_exception_logs.
  ///
  /// In en, this message translates to:
  /// **'Allow uploading application exception logs'**
  String get allow_uploading_application_exception_logs;

  /// No description provided for @do_not_allow_uploading_application_exception_logs.
  ///
  /// In en, this message translates to:
  /// **'Do not allow uploading application exception logs'**
  String get do_not_allow_uploading_application_exception_logs;

  /// No description provided for @developer_options.
  ///
  /// In en, this message translates to:
  /// **'developer options'**
  String get developer_options;

  /// No description provided for @message_debug_info.
  ///
  /// In en, this message translates to:
  /// **'message debug information'**
  String get message_debug_info;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
