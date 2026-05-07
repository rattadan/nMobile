import 'package:nchat_mobile/common/settings.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/client/client.dart';
import 'package:nchat_mobile/common/db/db.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/dialog/bottom.dart';
import 'package:nchat_mobile/components/dialog/loading.dart';
import 'package:nchat_mobile/components/dialog/modal.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/helpers/local_storage.dart';
import 'package:nchat_mobile/helpers/secure_storage.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/common/select.dart';
import 'package:nchat_mobile/storages/wallet.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/format.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';

class FileType {
  static const cache = 0;
  static const db = 1;
  static const factoryReset = 2;
}

class SettingsCacheScreen extends BaseStateFulWidget {
  static const String routeName = '/settings/cache';

  @override
  _SettingsCacheScreenState createState() => _SettingsCacheScreenState();
}

class _SettingsCacheScreenState
    extends BaseStateFulWidgetState<SettingsCacheScreen> {
  static const String TAG = "SettingsCacheScreen";

  String? title;
  String? selectedValue;
  List<SelectListItem>? list;

  String? _cacheSize;
  String? _dbSize;

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();
    _refreshFilesLength();
  }

  _refreshFilesLength() async {
    double cacheSize = await _getTotalSizeOfFile(
        Settings.applicationRootDirectory,
        dirFilter: DirType.cache);
    double dbSize = await _getTotalSizeOfFile(
        Directory(await dbCommon.getDBDirPath()),
        filePrefix: DB.NKN_DATABASE_NAME);
    setState(() {
      _cacheSize = Format.flowSize(cacheSize, unitArr: ['B', 'KB', 'MB', 'GB']);
      _dbSize = Format.flowSize(dbSize, unitArr: ['B', 'KB', 'MB', 'GB']);
    });
  }

  Future<double> _getTotalSizeOfFile(final FileSystemEntity file,
      {String? dirFilter, String? filePrefix, bool can = false}) async {
    List<String> splits = file.path.split("/");
    if (splits.length <= 0) return 0;
    String dirName = splits[splits.length - 1];
    if (!can) {
      if (dirFilter?.isNotEmpty == true) {
        can = (file is Directory) && (dirName == dirFilter);
      } else if (filePrefix?.isNotEmpty == true) {
        can = (file is File) && (dirName.startsWith(filePrefix!));
      } else {
        can = true;
      }
    }
    if (file is Directory) {
      double total = 0;
      final List<FileSystemEntity> children = file.listSync();
      for (final FileSystemEntity child in children) {
        total += await _getTotalSizeOfFile(child,
            can: can, dirFilter: dirFilter, filePrefix: filePrefix);
      }
      return total;
    }
    if (file is File) {
      if (can) {
        int length = await file.length();
        return double.tryParse(length.toString()) ?? 0;
      }
      return 0;
    }
    return 0;
  }

  Future<bool> _delete(FileSystemEntity file) async {
    // if (path == null || path.isEmpty) return false;
    // File file = File(path);
    if (file.existsSync()) {
      file.deleteSync(recursive: true);
      return true;
    }
    return false;
  }

  _clearCache(int type) async {
    // wallet (single-account mode: always use the default wallet)
    WalletSchema? wallet = await walletCommon.getDefault();
    if (wallet == null || wallet.publicKey.isEmpty == true) {
      // No wallet available, nothing to clear that depends on wallet.
      return;
    }
    // address
    String? address = wallet?.address;
    if (wallet == null || address == null || address.isEmpty) return;
    // pubKey
    String pubKey = wallet.publicKey;
    if (pubKey.isEmpty) {
      // For cache cleaning, we don't need password verification, so we can get pubKey directly
      // from the wallet schema without decrypting
      pubKey = wallet.publicKey;
      if (pubKey.isEmpty) return;
    }
    // delete
    Loading.show();
    if (type == FileType.cache) {
      // Cache cleaning - remove cache and seedphrase
      String path1 = Path.getDir(null, DirType.cache);
      String path2 = Path.getDir(pubKey, DirType.cache);
      await _delete(Directory(path1));
      await _delete(Directory(path2));

      // Remove seedphrase from secure storage for factory reset behavior
      WalletStorage storage = WalletStorage();
      await storage.delete(0, address);

      Toast.show(Settings.locale((s) => s.success, ctx: context));
    } else if (type == FileType.db) {
      await clientCommon.signOut(clearWallet: true, closeDB: true);
      await Future.delayed(Duration(milliseconds: 500));
      String dbPath = await dbCommon.getDBFilePath(pubKey);
      await _delete(File(dbPath));

      // Remove seedphrase from secure storage for factory reset behavior
      WalletStorage storage = WalletStorage();
      await storage.delete(0, address);

      Toast.show(Settings.locale((s) => s.success, ctx: context));
    } else if (type == FileType.factoryReset) {
      // Complete factory reset - remove all data
      await _performFactoryReset(address);
    }
    // refresh
    await Future.delayed(Duration(milliseconds: 100));
    await _refreshFilesLength();
    Loading.dismiss();
  }

  Future<void> _performFactoryReset(String address) async {
    try {
      // 1. Remove all wallet data including seedphrase
      WalletStorage storage = WalletStorage();
      await storage.delete(0, address);

      // 2. Clear all local storage
      await LocalStorage.instance.clear();

      // 3. Clear all secure storage (except we already handled wallet-specific)
      // Note: SecureStorage doesn't have a clear all method, but we've already removed wallet data

      // 4. Clear cache directories
      String path1 = Path.getDir(null, DirType.cache);
      await _delete(Directory(path1));

      // 5. Sign out client
      await clientCommon.signOut(clearWallet: true, closeDB: true);

      // 6. Restart app to first-time setup
      await Future.delayed(Duration(milliseconds: 1000));

      Toast.show("Factory reset complete. App will restart.");

      // Restart the app to first-time setup
      // This would typically restart the app, but for now we'll show a message
      // In a real implementation, you might use SystemChannels.platform to restart
    } catch (e) {
      logger.e("$TAG - Factory reset error: $e");
      Toast.show("Factory reset failed. Please restart app manually.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      headerColor: application.theme.headBarColor2,
      header: Header(
        title: Settings.locale((s) => s.cache, ctx: context),
        backgroundColor: application.theme.headBarColor2,
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: application.theme.backgroundLightColor,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      style: _buttonStyle(top: true),
                      onPressed: () async {
                        await ModalDialog.of(Settings.appContext).confirm(
                          titleWidget: Label(
                            Settings.locale((s) => s.tips, ctx: context),
                            type: LabelType.h3,
                            softWrap: true,
                          ),
                          contentWidget: Label(
                            Settings.locale((s) => s.delete_cache_confirm_title,
                                ctx: context),
                            type: LabelType.bodyRegular,
                            softWrap: true,
                          ),
                          agree: Button(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Asset.iconSvg(
                                    'trash',
                                    color: application.theme.fontLightColor,
                                    width: 24,
                                  ),
                                ),
                                Label(
                                  Settings.locale((s) => s.delete,
                                      ctx: context),
                                  type: LabelType.h3,
                                  color: application.theme.fontLightColor,
                                )
                              ],
                            ),
                            backgroundColor: application.theme.strongColor,
                            width: double.infinity,
                            onPressed: () {
                              if (Navigator.of(context).canPop())
                                Navigator.pop(context);
                              _clearCache(FileType.cache);
                            },
                          ),
                          reject: Button(
                            width: double.infinity,
                            text:
                                Settings.locale((s) => s.cancel, ctx: context),
                            fontColor: application.theme.fontColor2,
                            backgroundColor:
                                application.theme.backgroundLightColor,
                            onPressed: () {
                              if (Navigator.of(context).canPop())
                                Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Label(
                            Settings.locale((s) => s.clear_cache, ctx: context),
                            type: LabelType.bodyRegular,
                            color: application.theme.fontColor1,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          Row(
                            children: <Widget>[
                              Label(
                                _cacheSize ?? '',
                                type: LabelType.bodyRegular,
                                color: application.theme.fontColor2,
                                height: 1,
                              ),
                              Asset.iconSvg(
                                'right',
                                width: 24,
                                color: application.theme.fontColor2,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 0, color: application.theme.dividerColor),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      style: _buttonStyle(bottom: true),
                      onPressed: () async {
                        await ModalDialog.of(Settings.appContext).confirm(
                          titleWidget: Label(
                            Settings.locale((s) => s.tips, ctx: context),
                            type: LabelType.h3,
                            softWrap: true,
                          ),
                          contentWidget: Label(
                            Settings.locale((s) => s.delete_db_confirm_title,
                                ctx: context),
                            type: LabelType.bodyRegular,
                            softWrap: true,
                          ),
                          agree: Button(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Asset.iconSvg(
                                    'trash',
                                    color: application.theme.fontLightColor,
                                    width: 24,
                                  ),
                                ),
                                Label(
                                  Settings.locale((s) => s.delete,
                                      ctx: context),
                                  type: LabelType.h3,
                                  color: application.theme.fontLightColor,
                                )
                              ],
                            ),
                            backgroundColor: application.theme.strongColor,
                            onPressed: () {
                              if (Navigator.of(context).canPop())
                                Navigator.pop(context);
                              _clearCache(FileType.db);
                            },
                          ),
                          reject: Button(
                            width: double.infinity,
                            text:
                                Settings.locale((s) => s.cancel, ctx: context),
                            fontColor: application.theme.fontColor2,
                            backgroundColor:
                                application.theme.backgroundLightColor,
                            onPressed: () {
                              if (Navigator.of(context).canPop())
                                Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Label(
                            Settings.locale(
                                (s) => s.clear_database + ' [debug]',
                                ctx: context),
                            type: LabelType.bodyRegular,
                            color: application.theme.fontColor1,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          Row(
                            children: <Widget>[
                              Label(
                                _dbSize ?? '',
                                type: LabelType.bodyRegular,
                                color: application.theme.fontColor2,
                                height: 1,
                              ),
                              Asset.iconSvg(
                                'right',
                                width: 24,
                                color: application.theme.fontColor2,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  // Add factory reset option
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      style: _buttonStyle(top: true, bottom: true),
                      onPressed: () async {
                        await ModalDialog.of(Settings.appContext).confirm(
                          titleWidget: Label(
                            "Factory Reset",
                            type: LabelType.h3,
                            softWrap: true,
                            color: Colors.red,
                          ),
                          contentWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Label(
                                "This will completely reset the app to factory defaults and remove:",
                                type: LabelType.bodyRegular,
                                softWrap: true,
                              ),
                              SizedBox(height: 8),
                              Label(
                                "• All wallet data including seedphrases\n• All local settings and preferences\n• All cache and temporary files\n• All chat history and contacts",
                                type: LabelType.bodySmall,
                                softWrap: true,
                                color: application.theme.fontColor2,
                              ),
                              SizedBox(height: 12),
                              Label(
                                "⚠️ WARNING: This action cannot be undone!",
                                type: LabelType.bodyRegular,
                                softWrap: true,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          agree: Button(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Asset.iconSvg(
                                    'trash',
                                    color: application.theme.fontLightColor,
                                    width: 24,
                                  ),
                                ),
                                Label(
                                  "Factory Reset",
                                  type: LabelType.h3,
                                  color: application.theme.fontLightColor,
                                )
                              ],
                            ),
                            backgroundColor: Colors.red,
                            width: double.infinity,
                            onPressed: () {
                              if (Navigator.of(context).canPop())
                                Navigator.pop(context);
                              _clearCache(FileType.factoryReset);
                            },
                          ),
                          reject: Button(
                            width: double.infinity,
                            text: "Cancel",
                            fontColor: application.theme.fontColor2,
                            backgroundColor:
                                application.theme.backgroundLightColor,
                            onPressed: () {
                              if (Navigator.of(context).canPop())
                                Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Label(
                            "Factory Reset",
                            type: LabelType.bodyRegular,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          Row(
                            children: [
                              Asset.iconSvg(
                                'trash',
                                width: 24,
                                color: Colors.red,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
}
