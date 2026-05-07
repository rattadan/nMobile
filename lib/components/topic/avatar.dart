import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/discovery/public_group_storage.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/schema/topic.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';

const String TAG = "TopicAvatar";

class TopicAvatar extends BaseStateFulWidget {
  final TopicSchema topic;
  final double radius;
  final bool placeHolder;

  TopicAvatar({
    required this.topic,
    this.radius = 24,
    this.placeHolder = false,
  });

  @override
  _TopicAvatarState createState() => _TopicAvatarState();
}

class _TopicAvatarState extends BaseStateFulWidgetState<TopicAvatar> {
  // File? _avatarFile;
  bool _fileError = false;
  String? _discoveryAvatarPath;
  Uint8List? _discoveryAvatarBytes;

  @override
  void onRefreshArguments() {
    _fileError = false;
    _discoveryAvatarPath = null;
    _discoveryAvatarBytes = null;
    // _checkAvatarFileExists();
    _loadDiscoveryAvatar();
  }

  // _checkAvatarFileExists() async {
  //   File? avatarFile = await widget.topic.displayAvatarFile;
  //   if (_avatarFile?.path != avatarFile?.path) {
  //     setState(() {
  //       _avatarFile = avatarFile;
  //     });
  //   }
  // }

  /// Load avatar from discovery service cache for public groups
  Future<void> _loadDiscoveryAvatar() async {
    try {
      logger.d(
          "$TAG - Loading discovery avatar for topic: ${widget.topic.topicId} - isPrivate: ${widget.topic.isPrivate} - joined: ${widget.topic.joined}");

      // Only for public topics (not private groups)
      if (!widget.topic.isPrivate && widget.topic.joined) {
        // Check if topic has no avatar set locally
        String? localAvatarPath = widget.topic.displayAvatarPath;
        logger.d(
            "$TAG - Local avatar path: $localAvatarPath for topic: ${widget.topic.topicId}");

        if (localAvatarPath == null || localAvatarPath.isEmpty) {
          // DB-only: Try to get avatar from discovery.db cache
          logger.d(
              "$TAG - No local avatar found, checking discovery cache for topic: ${widget.topic.topicId}");
          final cached =
              await PublicGroupStorage.instance.query(widget.topic.topicId);
          final info = cached?.info;

          if (info != null) {
            logger.d(
                "$TAG - Found group info in discovery.db: ${info.topicId} - avatarPath: ${info.avatarPath} - hasBase64: ${(cached?.avatarBase64?.isNotEmpty == true)}");

            if (info.avatarPath != null && info.avatarPath!.isNotEmpty) {
              final String avatarPath = info.avatarPath!;
              final String? completePath = avatarPath.startsWith('/')
                  ? avatarPath
                  : Path.convert2Complete(avatarPath);
              if (completePath == null || completePath.isEmpty) {
                return;
              }

              final avatarFile = File(completePath);
              final fileExists = await avatarFile.exists();
              final fileSize = fileExists ? await avatarFile.length() : 0;
              logger.d(
                  "$TAG - Discovery(db) avatar file check - exists: $fileExists - size: $fileSize bytes - path: $completePath");
              if (fileExists && fileSize > 0) {
                setState(() {
                  _discoveryAvatarPath = completePath;
                });
                return;
              }
            }

            final b64 = cached?.avatarBase64;
            if (b64 != null && b64.isNotEmpty) {
              try {
                final bytes = base64Decode(b64);
                setState(() {
                  _discoveryAvatarBytes = bytes;
                });
                return;
              } catch (e) {
                logger.w(
                    "$TAG - Failed to decode avatar_base64 for ${widget.topic.topicId}: $e");
              }
            }
          } else {
            logger.d(
                "$TAG - ℹ️ No group info found in discovery.db for topic: ${widget.topic.topicId}");
          }
        } else {
          logger.d(
              "$TAG - ℹ️ Local avatar exists, skipping discovery cache for topic: ${widget.topic.topicId}");
        }
      } else {
        logger.d(
            "$TAG - ℹ️ Skipping discovery avatar load - isPrivate: ${widget.topic.isPrivate} - joined: ${widget.topic.joined}");
      }
    } catch (e) {
      logger.e(
          "$TAG - ❌ Error loading discovery avatar for topic: ${widget.topic.topicId} - error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double radius = this.widget.radius;
    String name = widget.topic.displayName;

    // Try local avatar first, then discovery.db cached avatar
    String? path = widget.topic.displayAvatarPath ?? _discoveryAvatarPath;
    if (path != null && path.isNotEmpty && !path.startsWith('/')) {
      path = Path.convert2Complete(path);
    }

    if (!_fileError && (path?.isNotEmpty == true)) {
      // _avatarFile != null
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path!)),
        onBackgroundImageError: (Object exception, StackTrace? stackTrace) {
          if (!_fileError) {
            setState(() {
              _fileError = true;
            });
          }
        },
      );
    }

    if (!_fileError && _discoveryAvatarBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(_discoveryAvatarBytes!),
        onBackgroundImageError: (Object exception, StackTrace? stackTrace) {
          if (!_fileError) {
            setState(() {
              _fileError = true;
            });
          }
        },
      );
    }
    if (widget.placeHolder == true) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: application.theme.backgroundColor2,
        child: Asset.iconSvg('user', color: application.theme.fontColor2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: widget.topic.options.avatarBgColor ??
          application.theme.primaryColor.withAlpha(19),
      child: Label(
        name.length > 2 ? name.substring(0, 2).toUpperCase() : name,
        color: widget.topic.options.avatarNameColor ??
            application.theme.fontLightColor,
        type: LabelType.h3,
        fontSize: radius / 3 * 2,
      ),
    );
  }
}
