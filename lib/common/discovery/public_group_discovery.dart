import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_state.dart';
import 'package:nchat_mobile/common/client/rpc.dart';
import 'package:nchat_mobile/common/client/client.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/settings.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/common/message/message.dart';
import 'package:nchat_mobile/storages/settings.dart';
import 'package:nchat_mobile/storages/topic.dart';
import 'package:nchat_mobile/common/chat/chat_out.dart';
import 'package:nchat_mobile/common/chat/chat.dart';
import 'package:nchat_mobile/common/contact/contact.dart';
import 'package:nchat_mobile/common/topic/topic.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/schema/message.dart';
import 'package:nchat_mobile/schema/topic.dart';
import 'package:nchat_mobile/utils/path.dart';
import 'package:nchat_mobile/helpers/error.dart';
import 'package:nchat_mobile/helpers/file.dart';
import 'package:nchat_mobile/helpers/media_picker.dart';
import 'package:nchat_mobile/common/discovery/public_group_storage.dart';

const String TAG = "PublicGroupDiscoveryService";

/// Public group information for discovery
class PublicGroupInfo {
  final String topicId;
  final String name;
  final String description;
  final String category;
  final int subscriberCount;
  final String? avatarPath;
  final Map<String, dynamic>?
      avatar; // Same format as contact profile: {type: 'base64', data: '...', ext: 'jpeg'}
  final Map<String, dynamic> metadata;

  PublicGroupInfo({
    required this.topicId,
    required this.name,
    this.description = '',
    this.category = 'general',
    this.subscriberCount = 0,
    this.avatarPath,
    this.avatar,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'topicId': topicId,
      'name': name,
      'description': description,
      'category': category,
      'subscriberCount': subscriberCount,
      'avatar': avatar,
      'metadata': metadata,
    };
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      json['avatarPath'] = avatarPath;
    }
    return json;
  }

  factory PublicGroupInfo.fromJson(Map<String, dynamic> json) {
    return PublicGroupInfo(
      topicId: json['topicId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      subscriberCount: json['subscriberCount'] ?? 0,
      avatarPath: json['avatarPath'],
      avatar: json['avatar'] != null
          ? Map<String, dynamic>.from(json['avatar'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Discovery broadcast message format
class DiscoveryBroadcastMessage {
  static const String TYPE_ANNOUNCEMENT = "announcement";
  static const String TYPE_PERIODIC = "periodic";
  static const String PROTOCOL_VERSION = "1.0";

  final String type;
  final String version;
  final DateTime timestamp;
  final String senderAddress;
  final List<PublicGroupInfo> groups;

  DiscoveryBroadcastMessage({
    required this.type,
    required this.version,
    required this.timestamp,
    required this.senderAddress,
    this.groups = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'sender': senderAddress,
      'payload': {
        'groups': groups.map((g) => g.toJson()).toList(),
      },
    };
  }

  factory DiscoveryBroadcastMessage.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> payload = json['payload'] ?? {};
    List groupsList = payload['groups'] ?? [];

    return DiscoveryBroadcastMessage(
      type: json['type'] ?? '',
      version: json['version'] ?? '1.0',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      senderAddress: json['sender'] ?? '',
      groups: groupsList.map((g) => PublicGroupInfo.fromJson(g)).toList(),
    );
  }

  static String serialize(DiscoveryBroadcastMessage message) {
    return jsonEncode(message.toJson());
  }

  static DiscoveryBroadcastMessage deserialize(String data) {
    return DiscoveryBroadcastMessage.fromJson(jsonDecode(data));
  }
}

/// Public Group Discovery Service
///
/// Handles broadcasting and discovering public groups via the publicGroups topic
class PublicGroupDiscoveryService {
  static const String DISCOVERY_TOPIC = "publicGroups";
  static const String CACHE_KEY = 'public_groups_cache';

  // Cached groups
  Map<String, PublicGroupInfo> _knownGroups = {};

  // Stream controller for UI updates
  final StreamController<List<PublicGroupInfo>> _groupsController =
      StreamController<List<PublicGroupInfo>>.broadcast();

  // Periodic broadcast timer
  Timer? _broadcastTimer;
  bool _isBroadcasting = false;

  // Message deduplication - track processed message IDs
  Set<String> _processedMessageIds = {};

  Stream<List<PublicGroupInfo>> get groupsStream => _groupsController.stream;
  List<PublicGroupInfo> get knownGroups => _knownGroups.values.toList();
  Map<String, PublicGroupInfo> get knownGroupsMap => _knownGroups;

  /// Load cached groups from storage
  Future<void> loadCache() async {
    try {
      // Run in background to not block UI
      await Future.delayed(Duration(milliseconds: 10));

      Object? cacheDataObj = await SettingsStorage.getSettings(CACHE_KEY);
      if (cacheDataObj == null) {
        logger.i("$TAG - No cache found");
        _notifyListeners(); // Emit empty list
        return;
      }

      // Handle various cache data formats
      Map<String, dynamic> cacheData;
      if (cacheDataObj is Map<String, dynamic>) {
        cacheData = cacheDataObj;
      } else if (cacheDataObj is Map) {
        cacheData = Map<String, dynamic>.from(cacheDataObj);
      } else {
        logger.w(
            "$TAG - Invalid cache data type: ${cacheDataObj.runtimeType}, clearing cache");
        await _clearCache();
        return;
      }

      Object? groupsDataObj = cacheData['groups'];
      if (groupsDataObj == null) {
        logger.i("$TAG - No groups data in cache");
        _notifyListeners(); // Emit empty list
        return;
      }

      // Handle potential type mismatch (migration from old cache format)
      Map<String, dynamic> groupsData;
      if (groupsDataObj is Map<String, dynamic>) {
        groupsData = groupsDataObj;
      } else if (groupsDataObj is Map) {
        // Convert to Map<String, dynamic>
        groupsData = Map<String, dynamic>.from(groupsDataObj);
      } else {
        logger.w(
            "$TAG - Invalid groups data type in cache: ${groupsDataObj.runtimeType}, clearing cache");
        await _clearCache();
        return;
      }

      _knownGroups.clear();
      groupsData.forEach((key, value) {
        try {
          if (value is Map<String, dynamic>) {
            _knownGroups[key] = PublicGroupInfo.fromJson(value);
          } else if (value is Map) {
            _knownGroups[key] =
                PublicGroupInfo.fromJson(Map<String, dynamic>.from(value));
          }
        } catch (e) {
          logger.w("$TAG - Failed to parse cached group '$key': $e");
        }
      });
      logger.i("$TAG - Loaded ${_knownGroups.length} groups from cache");
      _notifyListeners();
    } catch (e) {
      logger.e("$TAG - Error loading cache: $e");
      // Clear corrupted cache
      await _clearCache();
    }
  }

  /// Clear cache helper method
  Future<void> _clearCache() async {
    try {
      // Use empty map instead of null to avoid type errors
      Map<String, dynamic> emptyCache = {
        'timestamp': DateTime.now().toIso8601String(),
        'groups': {},
      };
      await SettingsStorage.setSettings(CACHE_KEY, emptyCache);
      _knownGroups.clear();
      _notifyListeners();
      logger.i("$TAG - Cache cleared successfully");
    } catch (e) {
      logger.e("$TAG - Failed to clear cache: $e");
      // Last resort - just clear memory
      _knownGroups.clear();
      _notifyListeners();
    }
  }

  /// Save groups to cache
  Future<void> saveCache() async {
    try {
      Map<String, dynamic> cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'groups':
            _knownGroups.map((key, value) => MapEntry(key, value.toJson())),
      };
      await SettingsStorage.setSettings(CACHE_KEY, cacheData);
      logger.d("$TAG - Saved ${_knownGroups.length} groups to cache");
    } catch (e) {
      logger.e("$TAG - Error saving cache: $e");
    }
  }

  /// Start discovery service with periodic broadcasting
  Future<void> start() async {
    logger.i("$TAG - Discovery service start called");

    try {
      logger.i("$TAG - Step 1: Loading cache...");
      await loadCache();
      logger.i(
          "$TAG - Cache loaded successfully, known groups: ${_knownGroups.length}");

      // Add existing public groups to known groups
      logger.i("$TAG - Step 2: Scanning existing public groups...");
      await _scanExistingPublicGroups();
      logger
          .i("$TAG - Scan complete, known groups now: ${_knownGroups.length}");

      // Fetch and process messages from publicGroups channel to get latest group data
      // including avatar base64 images from broadcasts
      logger
          .i("$TAG - Step 3: Processing messages from publicGroups channel...");
      await refreshDiscovery();
      logger.i("$TAG - Message processing complete");

      logger.i("$TAG - Step 4: Starting periodic broadcast...");
      _startPeriodicBroadcast();

      logger.i("$TAG - Step 5: Notifying listeners...");
      _notifyListeners();

      logger.i("$TAG - Discovery service started successfully!");
    } catch (e, st) {
      logger.e("$TAG - Error in start(): $e");
      logger.e("$TAG - Stack trace: $st");
      handleError(e, st);
    }
  }

  /// Scan existing public groups and add them to known groups
  Future<void> _scanExistingPublicGroups() async {
    try {
      logger.i("$TAG - Scanning existing public groups...");

      // Get all joined public topics
      List<TopicSchema> allTopics = await topicCommon.queryListJoined();
      int addedCount = 0;

      for (TopicSchema topic in allTopics) {
        if (!topic.isPrivate && topic.joined) {
          // Load avatar file if it exists
          File? avatarFile;
          if (topic.avatar != null && topic.avatar is File) {
            avatarFile = topic.avatar as File;
            logger.d(
                "$TAG - Found avatar file for ${topic.topicId}: ${avatarFile.path}");
          } else {
            logger.d("$TAG - No avatar file for ${topic.topicId}");
          }

          // Check if already in known groups
          if (!_knownGroups.containsKey(topic.topicId)) {
            // New group - add it
            logger.d(
                "$TAG - Adding new group: ${topic.topicId} with avatar: ${avatarFile != null}");
            await addKnownGroup(topic, avatarFile: avatarFile);
            addedCount++;
          } else {
            // Existing group - always update if we have an avatar file
            PublicGroupInfo existingGroup = _knownGroups[topic.topicId]!;

            // Always update if we have an avatar file (to regenerate base64 for broadcasting)
            if (avatarFile != null) {
              logger.i(
                  "$TAG - Updating group with avatar: ${topic.topicId} - existing avatar: ${existingGroup.avatar != null}");
              await addKnownGroup(topic, avatarFile: avatarFile);
              addedCount++;
            } else if (existingGroup.avatarPath == null ||
                existingGroup.avatarPath!.isEmpty) {
              // No avatar file and no existing avatar path - update metadata only
              logger.d("$TAG - Updating metadata for group: ${topic.topicId}");
              await addKnownGroup(topic, avatarFile: null);
              addedCount++;
            }
          }
        }
      }

      logger.i(
          "$TAG - Scanned existing groups: added/updated $addedCount groups, total known: ${_knownGroups.length}");
    } catch (e, st) {
      logger.e("$TAG - Error scanning existing groups: $e");
      handleError(e, st);
    }
  }

  /// Start periodic broadcasting based on settings
  void _startPeriodicBroadcast() {
    // Stop existing timer if any
    _stopPeriodicBroadcast();

    // Check if broadcasting is enabled
    if (!Settings.discoveryBroadcastEnabled) {
      logger.w("$TAG - Broadcasting is disabled in settings");
      return;
    }

    // Get broadcast period from settings (in minutes)
    int periodMinutes = Settings.discoveryBroadcastPeriod;
    if (periodMinutes <= 0) {
      logger.w(
          "$TAG - Broadcast period is $periodMinutes, disabling periodic broadcast");
      return;
    }

    Duration period = Duration(minutes: periodMinutes);
    logger.i("$TAG - Starting periodic broadcast every $periodMinutes minutes");

    _broadcastTimer = Timer.periodic(period, (timer) async {
      if (!_isBroadcasting) {
        _isBroadcasting = true;
        try {
          logger.i("$TAG - Periodic broadcast triggered");
          await broadcastAllKnownGroups();
        } catch (e) {
          logger.e("$TAG - Error in periodic broadcast: $e");
        } finally {
          _isBroadcasting = false;
        }
      }
    });
  }

  /// Stop periodic broadcasting
  void _stopPeriodicBroadcast() {
    if (_broadcastTimer != null) {
      _broadcastTimer!.cancel();
      _broadcastTimer = null;
      logger.i("$TAG - Stopped periodic broadcast");
    }
  }

  /// Restart periodic broadcasting (call when settings change)
  void restartPeriodicBroadcast() {
    logger.i("$TAG - Restarting periodic broadcast with new settings");
    _startPeriodicBroadcast();
  }

  /// Get group by topic ID (backward compatibility)
  PublicGroupInfo? getGroup(String topicId) {
    return _knownGroups[topicId];
  }

  /// Announce new public group (backward compatibility alias)
  Future<void> announceNewGroup(
    TopicSchema topic, {
    String? description,
    String? category,
    String? avatarPath,
    File? avatarFile,
  }) async {
    await announceGroup(topic,
        description: description,
        category: category,
        avatarPath: avatarPath,
        avatarFile: avatarFile);
  }

  /// Advertise a specific group (backward compatibility alias)
  Future<void> advertiseGroup(
    TopicSchema topic, {
    String? description,
    String? category,
    String? avatarPath,
    File? avatarFile,
  }) async {
    await announceGroup(topic,
        description: description,
        category: category,
        avatarPath: avatarPath,
        avatarFile: avatarFile);
  }

  /// Read recent messages from publicGroups topic
  Future<List<MessageSchema>> getRecentMessages({int limit = 20}) async {
    try {
      // Cap limit to avoid database issues
      int safeLimit = limit > 20 ? 20 : limit;

      logger.i("$TAG - Querying publicGroups messages (limit: $safeLimit)...");

      List<MessageSchema> messages =
          await messageCommon.queryListByTargetVisible(
        DISCOVERY_TOPIC,
        2, // SessionType.TOPIC
        offset: 0,
        limit: safeLimit,
      );

      logger
          .i("$TAG - Found ${messages.length} messages in publicGroups topic");

      // Log message details for debugging
      for (var msg in messages) {
        logger.i(
            "$TAG - Message: ${msg.msgId} | outbound: ${msg.isOutbound} | content: ${msg.content?.substring(0, 50) ?? 'null'}...");
      }

      return messages;
    } catch (e, st) {
      logger.e("$TAG - Error querying messages: $e");
      handleError(e, st);
      return [];
    }
  }

  /// Process messages and extract group information
  Future<int> processMessages(List<MessageSchema> messages) async {
    int processedCount = 0;
    int skippedCount = 0;

    logger.i("$TAG - Processing ${messages.length} messages...");

    for (var message in messages) {
      // Skip if no content
      if (message.content == null || message.content!.isEmpty) {
        logger.d("$TAG - Skipping message ${message.msgId} - no content");
        continue;
      }

      // Skip if message already processed (deduplication)
      String messageId = message.msgId;
      if (messageId.isEmpty) {
        continue;
      }

      // TEMPORARY: Comment out deduplication for testing - reprocess all messages
      // if (_processedMessageIds.contains(messageId)) {
      //   skippedCount++;
      //   continue;
      // }

      // Mark message as processed
      _processedMessageIds.add(messageId);

      try {
        // Try to decode base64
        String jsonContent;
        try {
          Uint8List decodedBytes = base64Decode(message.content!);
          jsonContent = utf8.decode(decodedBytes);
        } catch (e) {
          // Not base64, skip
          continue;
        }

        // Deserialize broadcast
        DiscoveryBroadcastMessage broadcast =
            DiscoveryBroadcastMessage.deserialize(jsonContent);

        // Process only announcement/periodic messages
        if (broadcast.type == DiscoveryBroadcastMessage.TYPE_PERIODIC ||
            broadcast.type == DiscoveryBroadcastMessage.TYPE_ANNOUNCEMENT) {
          // Add groups to known groups, processing avatar base64 data
          for (var group in broadcast.groups) {
            // Process avatar data if present (same format as contact profile)
            // IMPORTANT: never downgrade an existing non-null avatarPath to null.
            // If this message has no avatar data, keep whatever we already have in _knownGroups.
            String? savedAvatarPath = group.avatarPath;
            PublicGroupInfo? existingGroup;

            // Merge with existing cached group (if any) to preserve avatarPath
            if (_knownGroups.containsKey(group.topicId)) {
              existingGroup = _knownGroups[group.topicId]!;
              // Prefer existing non-empty avatarPath over null/empty from the message
              if ((savedAvatarPath == null || savedAvatarPath.isEmpty) &&
                  (existingGroup.avatarPath != null &&
                      existingGroup.avatarPath!.isNotEmpty)) {
                savedAvatarPath = existingGroup.avatarPath;
              }
            }

            logger.d(
                "$TAG - Processing avatar for group: ${group.topicId} - hasAvatar: ${group.avatar != null} - currentPath: $savedAvatarPath");

            if (group.avatar != null && group.avatar!['type'] == 'base64') {
              String? avatarData = group.avatar!['data'];
              String avatarExt =
                  group.avatar!['ext'] ?? FileHelper.DEFAULT_IMAGE_EXT;

              logger.d(
                  "$TAG - Found base64 avatar for group: ${group.topicId} - dataSize: ${avatarData?.length} - ext: $avatarExt");

              if (avatarData != null && avatarData.isNotEmpty) {
                // Convert base64 avatar to file
                try {
                  String avatarPath =
                      await _getGroupAvatarPath(group.topicId, avatarExt);
                  logger.d("$TAG - Generated avatar path: $avatarPath");

                  File? avatarFile = await FileHelper.convertBase64toFile(
                    avatarData,
                    (ext) async => avatarPath,
                  );

                  if (avatarFile != null) {
                    savedAvatarPath = avatarFile.path;
                    logger.i(
                        "$TAG - ✅ Saved avatar from base64 for group: ${group.topicId} - path: $savedAvatarPath - size: ${avatarFile.lengthSync()} bytes");

                    // Verify file exists
                    if (await avatarFile.exists()) {
                      logger.d(
                          "$TAG - ✅ Avatar file verified exists: ${avatarFile.path}");
                    } else {
                      logger.e(
                          "$TAG - ❌ Avatar file does not exist after save: ${avatarFile.path}");
                    }
                  } else {
                    logger.e(
                        "$TAG - ❌ Failed to convert base64 to file for group: ${group.topicId}");
                  }
                } catch (e, st) {
                  logger.e(
                      "$TAG - ❌ Error processing avatar for group: ${group.topicId} - error: $e");
                  handleError(e, st);
                }
              } else {
                logger.w(
                    "$TAG - ⚠️ Avatar data is empty for group: ${group.topicId}");
              }
            } else if (group.avatar != null) {
              logger.w(
                  "$TAG - ⚠️ Avatar is not base64 format for group: ${group.topicId} - type: ${group.avatar!['type']}");
            } else {
              logger.d("$TAG - ℹ️ No avatar data for group: ${group.topicId}");
            }

            // Update group with saved avatar path (clear avatar data after saving)
            // The avatarPath will be used for display, avatar data is only for transmission
            PublicGroupInfo updatedGroup = PublicGroupInfo(
              topicId: group.topicId,
              name: group.name.isNotEmpty
                  ? group.name
                  : (existingGroup?.name ?? ''),
              description: group.description.isNotEmpty
                  ? group.description
                  : (existingGroup?.description ?? ''),
              category: group.category.isNotEmpty
                  ? group.category
                  : (existingGroup?.category ?? 'general'),
              subscriberCount: group.subscriberCount > 0
                  ? group.subscriberCount
                  : (existingGroup?.subscriberCount ?? 0),
              avatarPath:
                  savedAvatarPath, // Use the locally saved path or previously cached path
              avatar:
                  null, // Clear avatar data after saving to file (don't keep in memory/cache)
              metadata: group.metadata.isNotEmpty
                  ? group.metadata
                  : (existingGroup?.metadata ?? {}),
            );

            // Persist to local discovery DB; cache base64 avatar if present in payload
            final String? incomingAvatarBase64 =
                group.avatar?['data'] as String?;
            if (incomingAvatarBase64 != null &&
                incomingAvatarBase64.isNotEmpty) {
              await PublicGroupStorage.instance.upsertGroup(
                updatedGroup,
                avatarBase64: incomingAvatarBase64,
              );
            } else {
              await PublicGroupStorage.instance.upsertGroup(updatedGroup);
            }
            _knownGroups[group.topicId] = updatedGroup;
          }
          processedCount++;
        }
      } catch (e, st) {
        logger.e("$TAG - Error processing message: $e");
        handleError(e, st);
      }
    }

    // Clean up processed message IDs if set gets too large (prevent memory leaks)
    if (_processedMessageIds.length > 1000) {
      // Keep only the most recent 500 message IDs
      List<String> messageList = _processedMessageIds.toList();
      messageList.sort();
      _processedMessageIds.clear();
      _processedMessageIds.addAll(messageList.skip(500));
      logger.d(
          "$TAG - Cleaned up message ID cache, kept ${_processedMessageIds.length} recent IDs");
    }

    if (skippedCount > 0) {
      logger.d("$TAG - Skipped $skippedCount already processed messages");
    }

    logger.i(
        "$TAG - Processing complete: processedCount=$processedCount, totalMessages=${messages.length}, knownGroups=${_knownGroups.length}");

    // Always notify UI to ensure it updates with current state
    _notifyListeners();

    // Save cache if we processed any messages
    if (processedCount > 0) {
      await saveCache();
    }

    return processedCount;
  }

  /// Refresh discovery by reading messages from channel
  Future<int> refreshDiscovery() async {
    logger.i("$TAG - Refreshing discovery...");
    List<MessageSchema> messages = await getRecentMessages(limit: 20);
    int count = await processMessages(messages);
    logger.i(
        "$TAG - Refresh complete: processed $count groups from ${messages.length} messages");
    return count;
  }

  /// Add a group to known groups without broadcasting (for existing groups)
  Future<void> addKnownGroup(TopicSchema topic, {File? avatarFile}) async {
    try {
      String? description = topic.data['description'] as String?;
      String? category = topic.data['category'] as String?;
      // Note: We don't use the stored avatarPath from topic.data['groupAvatar']
      // because it's an internal path. Avatar will be saved locally from broadcasts.

      // Convert avatar file to base64 if provided (same format as contact profile)
      // Note: avatarData is only for transmission, not stored in cache
      Map<String, dynamic>? avatarData;
      String? savedAvatarPath;

      if (avatarFile != null && await avatarFile.exists()) {
        try {
          // Resize avatar to 80x80 to reduce size
          String tempPath = await Path.getRandomFile(
            clientCommon.getPublicKey(),
            DirType.cache,
            fileExt: FileHelper.DEFAULT_IMAGE_EXT,
          );

          File? resizedFile = await MediaPicker.compressImageBySize(
            avatarFile,
            savePath: tempPath,
            maxSize: 80 * 80 * 4, // 80x80 pixels, ~25KB max
            bestSize: 80 * 80 * 2, // Target ~12KB
            force: true,
          );

          if (resizedFile != null && await resizedFile.exists()) {
            String base64 = base64Encode(await resizedFile.readAsBytes());

            if (base64.isNotEmpty) {
              avatarData = {
                'type': 'base64',
                'data': base64,
                'ext':
                    Path.getFileExt(avatarFile, FileHelper.DEFAULT_IMAGE_EXT),
              };

              // Save resized avatar locally for display
              try {
                String avatarPath = await _getGroupAvatarPath(
                  topic.topicId,
                  Path.getFileExt(avatarFile, FileHelper.DEFAULT_IMAGE_EXT),
                );

                File? savedFile = await FileHelper.convertBase64toFile(
                  base64,
                  (ext) async => avatarPath,
                );

                if (savedFile != null && await savedFile.exists()) {
                  savedAvatarPath = savedFile.path;
                  logger.i(
                      "$TAG - Saved resized avatar (80x80) for group: ${topic.topicId} - path: $savedAvatarPath - size: ${savedFile.lengthSync()} bytes");
                }
              } catch (e) {
                logger.e("$TAG - Error saving avatar for ${topic.topicId}: $e");
              }

              logger.i(
                  "$TAG - Converted resized avatar to base64 for group: ${topic.topicId} - size: ${base64.length} chars");
            }

            // Clean up temp resized file
            try {
              await resizedFile.delete();
            } catch (e) {
              logger.w("$TAG - Could not delete temp file: $e");
            }
          } else {
            logger.w("$TAG - Failed to resize avatar for ${topic.topicId}");
          }
        } catch (e) {
          logger.e("$TAG - Error processing avatar for ${topic.topicId}: $e");
        }
      }

      // Create group info with saved avatar path and avatar data for broadcasting
      PublicGroupInfo groupInfo = PublicGroupInfo(
        topicId: topic.topicId,
        name: topic.data['name'] ?? topic.topicId,
        description: description ?? topic.data['description'] ?? '',
        category: category ?? topic.data['category'] ?? 'general',
        subscriberCount: topic.count,
        avatarPath: savedAvatarPath, // Store local path for display
        avatar:
            avatarData, // Keep avatar data for broadcasting (resized to 80x80)
        metadata: topic.data,
      );

      // Persist to local discovery DB (cache base64 if available)
      await PublicGroupStorage.instance.upsertGroup(
        groupInfo,
        avatarBase64: avatarData?['data'] as String?,
      );

      // Add to known groups
      _knownGroups[topic.topicId] = groupInfo;
      _notifyListeners();
      await saveCache();

      logger.i(
          "$TAG - Added existing group to known groups: ${topic.topicId} (avatarData: ${avatarData != null ? 'yes' : 'no'}), total known: ${_knownGroups.length}");
    } catch (e, st) {
      logger.e("$TAG - Error adding known group: $e");
      handleError(e, st);
    }
  }

  /// Announce a new public group
  Future<void> announceGroup(
    TopicSchema topic, {
    String? description,
    String? category,
    String? avatarPath,
    File? avatarFile,
  }) async {
    try {
      // Get client info
      var client = clientCommon.client;
      if (client == null) {
        logger.e("$TAG - No client available for announcement");
        return;
      }

      // Log avatar info for debugging
      logger.i("$TAG - announceGroup called for: ${topic.topicId}");
      logger.i(
          "$TAG - avatarPath: $avatarPath, avatarFile: ${avatarFile != null ? 'provided' : 'null'}");
      if (avatarFile != null) {
        logger.i(
            "$TAG - avatarFile path: ${avatarFile.path}, exists: ${await avatarFile.exists()}");
      }

      // Convert avatar file to base64 if provided or load from path
      Map<String, dynamic>? avatarData;
      final cachedEntry =
          await PublicGroupStorage.instance.query(topic.topicId);
      final existingKnownGroup = _knownGroups[topic.topicId];
      String? cachedAvatarPath = existingKnownGroup?.avatarPath;

      if ((cachedAvatarPath == null || cachedAvatarPath.isEmpty) &&
          cachedEntry?.info.avatarPath != null &&
          cachedEntry!.info.avatarPath!.isNotEmpty) {
        cachedAvatarPath = cachedEntry.info.avatarPath;
      }

      if ((cachedAvatarPath == null || cachedAvatarPath.isEmpty) &&
          avatarPath != null &&
          avatarPath.isNotEmpty) {
        cachedAvatarPath = Path.convert2Complete(avatarPath) ?? avatarPath;
      }

      // Prefer cached base64 avatar from discovery.db to avoid re-encoding
      try {
        final cachedBase64 = cachedEntry?.avatarBase64;
        if (cachedBase64 != null && cachedBase64.isNotEmpty) {
          avatarData = {
            'type': 'base64',
            'data': cachedBase64,
            'ext': FileHelper.DEFAULT_IMAGE_EXT,
          };
          logger.i(
              "$TAG - Using cached base64 avatar from discovery.db for group: ${topic.topicId}, base64 length: ${cachedBase64.length}");
        }
      } catch (e) {
        // ignore and fall back to file-based encoding
      }

      // First try: use provided avatar file
      if (avatarData == null &&
          avatarFile != null &&
          await avatarFile.exists()) {
        String base64 = base64Encode(await avatarFile.readAsBytes());
        if (base64.isNotEmpty) {
          avatarData = {
            'type': 'base64',
            'data': base64,
            'ext': Path.getFileExt(avatarFile, FileHelper.DEFAULT_IMAGE_EXT),
          };
          logger.i(
              "$TAG - Converted avatar to base64 from provided file for group: ${topic.topicId}, base64 length: ${base64.length}");

          // Store for reuse
          await PublicGroupStorage.instance.upsertGroup(
            PublicGroupInfo(
              topicId: topic.topicId,
              name: topic.data['name'] ?? topic.topicId,
              description: description ?? topic.data['description'] ?? '',
              category: category ?? topic.data['category'] ?? 'general',
              subscriberCount: topic.count,
              avatarPath: cachedAvatarPath,
              avatar: null,
              metadata: topic.data,
            ),
            avatarBase64: base64,
          );
        }
      }
      // Second try: load avatar from saved path
      else if (avatarData == null &&
          avatarPath != null &&
          avatarPath.isNotEmpty) {
        String? completePath = Path.convert2Complete(avatarPath);
        logger.i(
            "$TAG - Trying to load avatar from saved path: $avatarPath -> $completePath");
        if (completePath != null && completePath.isNotEmpty) {
          File fileFromPath = File(completePath);
          if (await fileFromPath.exists()) {
            String base64 = base64Encode(await fileFromPath.readAsBytes());
            if (base64.isNotEmpty) {
              avatarData = {
                'type': 'base64',
                'data': base64,
                'ext':
                    Path.getFileExt(fileFromPath, FileHelper.DEFAULT_IMAGE_EXT),
              };
              logger.i(
                  "$TAG - Converted avatar to base64 from saved path for group: ${topic.topicId}, base64 length: ${base64.length}");

              // Store for reuse
              await PublicGroupStorage.instance.upsertGroup(
                PublicGroupInfo(
                  topicId: topic.topicId,
                  name: topic.data['name'] ?? topic.topicId,
                  description: description ?? topic.data['description'] ?? '',
                  category: category ?? topic.data['category'] ?? 'general',
                  subscriberCount: topic.count,
                  avatarPath: cachedAvatarPath,
                  avatar: null,
                  metadata: topic.data,
                ),
                avatarBase64: base64,
              );
            }
          } else {
            logger.w(
                "$TAG - Avatar file does not exist at saved path: $completePath");
          }
        }
      }

      if (avatarData == null) {
        logger.w("$TAG - No avatar file available for group: ${topic.topicId}");
      }

      // Create group info - DON'T broadcast avatarPath (internal path), only broadcast base64 avatar data
      // Each receiving user will save the avatar locally and get their own path
      PublicGroupInfo groupInfo = PublicGroupInfo(
        topicId: topic.topicId,
        name: topic.data['name'] ?? topic.topicId,
        description: description ?? topic.data['description'] ?? '',
        category: category ?? topic.data['category'] ?? 'general',
        subscriberCount: topic.count,
        avatarPath: null, // Don't broadcast internal path
        avatar: avatarData,
        metadata: topic.data,
      );

      PublicGroupInfo cachedGroupInfo = PublicGroupInfo(
        topicId: topic.topicId,
        name: topic.data['name'] ?? topic.topicId,
        description: description ?? topic.data['description'] ?? '',
        category: category ?? topic.data['category'] ?? 'general',
        subscriberCount: topic.count,
        avatarPath: cachedAvatarPath,
        avatar: null,
        metadata: topic.data,
      );

      logger.i(
          "$TAG - groupInfo created - avatar: ${avatarData != null ? 'present' : 'null'}");

      // Add to known groups
      _knownGroups[topic.topicId] = cachedGroupInfo;

      // Create broadcast message
      DiscoveryBroadcastMessage message = DiscoveryBroadcastMessage(
        type: DiscoveryBroadcastMessage.TYPE_ANNOUNCEMENT,
        version: DiscoveryBroadcastMessage.PROTOCOL_VERSION,
        timestamp: DateTime.now(),
        senderAddress: clientCommon.address ?? '',
        groups: [groupInfo],
      );

      // Encode to base64
      String messageJson = DiscoveryBroadcastMessage.serialize(message);
      String messageBase64 = base64Encode(utf8.encode(messageJson));

      // Send via chatOutCommon
      var result = await _sendToTopic(DISCOVERY_TOPIC, messageBase64);

      logger.i(
          "$TAG - Announced group: ${topic.topicId} - result: ${result != null ? 'SUCCESS' : 'FAILED'}");

      // Notify and save
      _notifyListeners();
      await saveCache();
    } catch (e, st) {
      handleError(e, st);
      logger.e("$TAG - Error announcing group: $e");
    }
  }

  /// Broadcast all known groups for manual network propagation
  Future<void> broadcastAllKnownGroups() async {
    try {
      if (_knownGroups.isEmpty) {
        logger.i("$TAG - No known groups to broadcast");
        return;
      }

      var client = clientCommon.client;
      if (client == null) {
        logger.e("$TAG - No client available for broadcasting");
        return;
      }

      // Prefer cached base64 avatars from discovery.db to avoid re-encoding on every broadcast
      final List<PublicGroupInfo> groupsToBroadcast = [];
      for (final g in _knownGroups.values) {
        try {
          final cached = await PublicGroupStorage.instance.query(g.topicId);
          final cachedBase64 = cached?.avatarBase64;

          if (cachedBase64 != null && cachedBase64.isNotEmpty) {
            groupsToBroadcast.add(PublicGroupInfo(
              topicId: g.topicId,
              name: g.name,
              description: g.description,
              category: g.category,
              subscriberCount: g.subscriberCount,
              avatarPath: null, // Never broadcast local file paths
              avatar: {
                'type': 'base64',
                'data': cachedBase64,
                'ext': FileHelper.DEFAULT_IMAGE_EXT,
              },
              metadata: g.metadata,
            ));
          } else {
            groupsToBroadcast.add(PublicGroupInfo(
              topicId: g.topicId,
              name: g.name,
              description: g.description,
              category: g.category,
              subscriberCount: g.subscriberCount,
              avatarPath: null, // Never broadcast local file paths
              avatar: g.avatar,
              metadata: g.metadata,
            ));
          }
        } catch (e) {
          // If storage fails for any reason, fall back to in-memory version
          groupsToBroadcast.add(PublicGroupInfo(
            topicId: g.topicId,
            name: g.name,
            description: g.description,
            category: g.category,
            subscriberCount: g.subscriberCount,
            avatarPath: null, // Never broadcast local file paths
            avatar: g.avatar,
            metadata: g.metadata,
          ));
        }
      }

      logger.i("$TAG - Broadcasting ${groupsToBroadcast.length} known groups");

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < groupsToBroadcast.length; i++) {
        final group = groupsToBroadcast[i];

        // Broadcast groups one-by-one to avoid oversized payloads that can break receiving
        final message = DiscoveryBroadcastMessage(
          type: DiscoveryBroadcastMessage.TYPE_PERIODIC,
          version: DiscoveryBroadcastMessage.PROTOCOL_VERSION,
          timestamp: DateTime.now(),
          senderAddress: clientCommon.address ?? '',
          groups: [group],
        );

        final messageJson = DiscoveryBroadcastMessage.serialize(message);
        final messageBase64 = base64Encode(utf8.encode(messageJson));

        final result = await _sendToTopic(DISCOVERY_TOPIC, messageBase64);
        if (result != null) {
          successCount++;
        } else {
          failCount++;
        }

        // 500ms delay between broadcasts to reduce receiver load
        if (i < groupsToBroadcast.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      logger.i(
          "$TAG - Broadcast all groups complete: success=$successCount, failed=$failCount, total=${groupsToBroadcast.length}");
    } catch (e, st) {
      handleError(e, st);
      logger.e("$TAG - Error broadcasting all groups: $e");
    }
  }

  /// Send text message to topic (low-level helper)
  Future<MessageSchema?> _sendToTopic(String topicId, String content) async {
    if (content.isEmpty) return null;

    MessageSchema message = MessageSchema.fromSend(
      topicId,
      2, // SessionType.TOPIC
      MessageContentType.text,
      content,
      extra: {
        "profileVersion": (await contactCommon.getMe())?.profileVersion,
      },
    );

    message = await messageCommon.loadMessageSendQueue(message);
    message.data = MessageData.getText(message);

    return await chatOutCommon.sendVisibleForDiscovery(message);
  }

  /// Generate file path for group avatar from base64
  Future<String> _getGroupAvatarPath(String topicId, String fileExt) async {
    return await Path.getRandomFile(
      clientCommon.getPublicKey(),
      DirType.chat,
      subPath: 'topic_avatar_$topicId',
      fileExt: fileExt,
    );
  }

  /// Query for groups (placeholder for future search implementation)
  Future<void> queryGroups(String searchText, {int maxResults = 20}) async {
    logger.i("$TAG - Query groups: '$searchText'");
    // For now, just filter local groups
    // Future implementation: send query to network and collect responses
  }

  /// Notify UI listeners
  void _notifyListeners() {
    if (!_groupsController.isClosed) {
      _groupsController.add(_knownGroups.values.toList());
    }
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    return {
      'total_groups': _knownGroups.length,
      'groups': _knownGroups.values
          .map((g) => {
                'topicId': g.topicId,
                'name': g.name,
                'category': g.category,
                'subscriberCount': g.subscriberCount,
              })
          .toList(),
    };
  }

  /// Clear all cached groups
  Future<void> clearCache() async {
    _knownGroups.clear();
    await saveCache();
    _notifyListeners();
    logger.i("$TAG - Cleared all cached groups");
  }

  /// Dispose
  Future<void> dispose() async {
    _stopPeriodicBroadcast();
    await _groupsController.close();
  }
}
