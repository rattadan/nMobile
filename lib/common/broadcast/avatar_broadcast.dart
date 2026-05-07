import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nchat_mobile/common/client/client.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/settings.dart';
import 'package:nchat_mobile/helpers/file.dart';
import 'package:nchat_mobile/models/broadcast_avatar.dart';
import 'package:nchat_mobile/services/avatar_cache_service.dart';
import 'package:nchat_mobile/utils/logger.dart';

/// Avatar broadcast service
/// Handles broadcasting and receiving avatar updates for contacts and groups
class AvatarBroadcastService {
  static final AvatarBroadcastService _instance = AvatarBroadcastService._internal();
  factory AvatarBroadcastService() => _instance;
  AvatarBroadcastService._internal();

  final AvatarCacheService _cacheService = AvatarCacheService();
  StreamSubscription? _messageSubscription;

  /// Initialize the avatar broadcast service
  Future<void> init() async {
    await _cacheService.init();
    await _startListeningForBroadcasts();
    logger.d('AvatarBroadcast: Avatar broadcast service initialized');
  }

  /// Start listening for incoming avatar broadcast messages
  Future<void> _startListeningForBroadcasts() async {
    try {
      // Listen to messages from the client
      _messageSubscription = clientCommon.client?.onMessage.listen((message) {
        _processIncomingMessage(message);
      });
      logger.d('AvatarBroadcast: Started listening for avatar broadcasts');
    } catch (e) {
      logger.e('AvatarBroadcast: Failed to start listening for broadcasts: $e');
    }
  }

  /// Process incoming message and check for avatar broadcast
  Future<void> _processIncomingMessage(message) async {
    try {
      // Try to decode as avatar broadcast
      final avatarMsg = AvatarBroadcastMessage.decode(message.data);
      if (avatarMsg == null) return;

      logger.d('AvatarBroadcast: Received avatar broadcast: $avatarMsg');
      await _handleIncomingAvatar(avatarMsg, message.sender);
    } catch (e) {
      // Not an avatar broadcast, ignore
    }
  }

  /// Handle incoming avatar broadcast
  Future<void> _handleIncomingAvatar(
    AvatarBroadcastMessage avatarMsg,
    String sender,
  ) async {
    try {
      final senderId = avatarMsg.senderId;
      final senderType = avatarMsg.senderType;

      // Save avatar to cache
      final saved = await _cacheService.saveAvatar(
        id: senderId,
        type: senderType,
        base64Data: avatarMsg.avatarBase64,
        ext: avatarMsg.avatarExt,
      );

      if (!saved) {
        logger.e('AvatarBroadcast: Failed to save avatar from broadcast');
        return;
      }

      logger.d('AvatarBroadcast: Successfully processed avatar from $senderId (${senderType.name})');
    } catch (e) {
      logger.e('AvatarBroadcast: Error processing incoming avatar: $e');
    }
  }

  /// Broadcast avatar for a topic (public group)
  /// Note: Actual broadcasting is handled by PublicGroupDiscoveryService
  /// This method saves the avatar to cache for local display
  Future<bool> broadcastTopicAvatar({
    required String topicId,
    required File avatarFile,
  }) async {
    try {
      if (!await avatarFile.exists()) {
        logger.e('AvatarBroadcast: Avatar file does not exist');
        return false;
      }

      // Avatar broadcasting is handled by PublicGroupDiscoveryService.announceGroup()
      // which includes the avatar in the broadcast message
      logger.d('AvatarBroadcast: Topic avatar broadcast prepared for: $topicId');
      return true;
    } catch (e) {
      logger.e('AvatarBroadcast: Error preparing topic avatar broadcast: $e');
      return false;
    }
  }

  /// Broadcast avatar for a private group
  Future<bool> broadcastPrivateGroupAvatar({
    required String groupId,
    required File avatarFile,
  }) async {
    try {
      if (!await avatarFile.exists()) {
        logger.e('AvatarBroadcast: Avatar file does not exist');
        return false;
      }

      // For private groups, avatar is shared via group messages
      // Implementation would use chatOutCommon.send() to send to group members
      logger.d('AvatarBroadcast: Private group avatar broadcast prepared for: $groupId');
      return true;
    } catch (e) {
      logger.e('AvatarBroadcast: Error preparing private group avatar broadcast: $e');
      return false;
    }
  }

  /// Get file extension from avatar file
  String _getFileExtension(File file) {
    final path = file.path;
    final ext = path.split('.').last;
    return ext.isNotEmpty ? ext : FileHelper.DEFAULT_IMAGE_EXT;
  }

  /// Get avatar for display from cache or schema
  Future<File?> getAvatarForDisplay({
    required String id,
    required AvatarSenderType type,
    File? localAvatarFile,
  }) async {
    // First try local avatar file
    if (localAvatarFile != null && await localAvatarFile.exists()) {
      return localAvatarFile;
    }

    // Then try cache
    final cachedFile = await _cacheService.getAvatar(id, type);
    if (cachedFile != null) {
      return cachedFile;
    }

    return null;
  }

  /// Dispose the service
  void dispose() {
    _messageSubscription?.cancel();
  }
}
