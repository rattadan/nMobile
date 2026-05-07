import 'package:nchat_mobile/common/settings.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/utils/asset.dart';

// Removed unused imports and media_store_plus for unblocking

class VideoScreen extends BaseStateFulWidget {
  static final String routeName = "/video";
  static final String argFilePath = "file_path";
  static final String argThumbnail = "thumbnail_path";
  static final String argNetUrl = "net_url";

  static Future go(BuildContext? context,
      {String? filePath, String? thumbnailPath, String? netUrl}) {
    if (context == null) return Future.value(null);
    if ((filePath == null || filePath.isEmpty) &&
        (netUrl == null || netUrl.isEmpty)) return Future.value(null);
    return Navigator.pushNamed(context, routeName, arguments: {
      argFilePath: filePath,
      argThumbnail: thumbnailPath,
      argNetUrl: netUrl,
    });
  }

  final Map<String, dynamic>? arguments;

  VideoScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends BaseStateFulWidgetState<VideoScreen>
    with SingleTickerProviderStateMixin {
  static const int TYPE_FILE = 1;
  static const int TYPE_NET = 2;

  int? _contentType;
  String? _content;

  @override
  void onRefreshArguments() {
    String? filePath = widget.arguments?[VideoScreen.argFilePath];
    String? netUrl = widget.arguments?[VideoScreen.argNetUrl];
    if (filePath != null && filePath.isNotEmpty) {
      _contentType = TYPE_FILE;
      _content = filePath;
    } else if (netUrl != null && netUrl.isNotEmpty) {
      _contentType = TYPE_NET;
      _content = netUrl;
    }
  }

  Future _save() async {
    Toast.show("Saving to gallery is temporarily disabled.");
  }

  @override
  Widget build(BuildContext context) {
    double playSize = Settings.screenWidth() / 5;
    double btnSize = Settings.screenWidth() / 10;
    double iconSize = Settings.screenWidth() / 15;

    return Layout(
      bodyColor: Colors.black,
      headerColor: Colors.black,
      borderRadius: BorderRadius.zero,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.video_camera,
                  size: playSize,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Label(
                  "Video playback is not available in this build",
                  type: LabelType.h3,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Label(
                  _contentType == TYPE_NET
                      ? (_content ?? "")
                      : ((_content?.isNotEmpty == true)
                          ? File(_content!).path.split('/').last
                          : ""),
                  type: LabelType.bodyRegular,
                  color: Colors.white.withAlpha(180),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: Platform.isAndroid ? 45 : 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: btnSize / 4),
                Button(
                  width: btnSize,
                  height: btnSize,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: Container(
                    width: btnSize,
                    height: btnSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(60),
                      borderRadius:
                          BorderRadius.all(Radius.circular(btnSize / 2)),
                    ),
                    child: Icon(
                      CupertinoIcons.back,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  onPressed: () {
                    if (Navigator.of(this.context).canPop())
                      Navigator.pop(this.context);
                  },
                ),
                Spacer(),
                Container(
                  width: btnSize,
                  height: btnSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(60),
                    borderRadius:
                        BorderRadius.all(Radius.circular(btnSize / 2)),
                  ),
                  child: PopupMenuButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    icon: Asset.iconSvg('more', width: 24),
                    onSelected: (int result) async {
                      switch (result) {
                        case 0:
                          await _save();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<int>>[
                      PopupMenuItem<int>(
                        value: 0,
                        child: Label(
                          Settings.locale((s) => s.save_to_album, ctx: context),
                          type: LabelType.display,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: btnSize / 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
