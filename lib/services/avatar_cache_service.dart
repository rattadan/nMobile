import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nchat_mobile/helpers/file.dart';
import 'package:nchat_mobile/models/broadcast_avatar.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';
import 'package:path_provider/path_provider.dart';

const String _TAG = 'AvatarCache';

/// Avatar cache service for managing received avatars from broadcasts
/// Handles caching, retrieval, and expiration of avatar images
class AvatarCacheService {
  static final AvatarCacheService _instance = AvatarCacheService._internal();
  factory AvatarCacheService() => _instance;
  AvatarCacheService._internal();

  final Map<String, AvatarCacheEntry> _cache = {};
  static const int _cacheExpirationHours = 24; // Cache expires after 24 hours
  static const String _avatarCacheDir = 'avatars';

  /// Initialize the avatar cache service
  Future<void> init() async {
    await _loadCacheFromDisk();
    await _cleanupExpiredCache();
  }

  /// Get the avatar cache directory
  Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${appDir.path}/$_avatarCacheDir');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    return avatarDir;
  }

  /// Generate cache file path for an avatar
  Future<String> _getCacheFilePath(String id, AvatarSenderType type) async {
    final dir = await _cacheDir;
    final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final typeStr = _getTypeString(type);
    return '${dir.path}/${typeStr}_$safeId.dat';
  }

  String _getTypeString(AvatarSenderType type) {
    switch (type) {
      case AvatarSenderType.contact:
        return 'contact';
      case AvatarSenderType.topic:
        return 'topic';
      case AvatarSenderType.privateGroup:
        return 'group';
    }
  }

  AvatarSenderType _getTypeFromString(String str) {
    switch (str) {
      case 'contact':
        return AvatarSenderType.contact;
      case 'topic':
        return AvatarSenderType.topic;
      case 'group':
        return AvatarSenderType.privateGroup;
      default:
        return AvatarSenderType.contact;
    }
  }

  /// Save avatar from base64 data
  Future<bool> saveAvatar({
    required String id,
    required AvatarSenderType type,
    required String base64Data,
    required String ext,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + (_cacheExpirationHours * 60 * 60 * 1000);

      // Decode and save to file
      final bytes = base64Decode(base64Data);
      final filePath = await _getCacheFilePath(id, type);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Update cache entry
      final entry = AvatarCacheEntry(
        id: id,
        type: type,
        filePath: filePath,
        cachedAt: now,
        expiresAt: expiresAt,
      );
      _cache[_getCacheKey(id, type)] = entry;

      // Update schema cached base64 if needed
      _updateSchemaCache(id, type, base64Data);

      logger.d('$_TAG: Saved avatar: $id (${_getTypeString(type)}) to $filePath');
      return true;
    } catch (e) {
      logger.e('$_TAG: Failed to save avatar: $e');
      return false;
    }
  }

  /// Save avatar from file
  Future<bool> saveAvatarFile({
    required String id,
    required AvatarSenderType type,
    required File file,
  }) async {
    try {
      if (!await file.exists()) {
        logger.e('$_TAG: Avatar file does not exist: ${file.path}');
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + (_cacheExpirationHours * 60 * 60 * 1000);

      // Copy to cache directory
      final cacheFilePath = await _getCacheFilePath(id, type);
      await file.copy(cacheFilePath);

      // Update cache entry
      final entry = AvatarCacheEntry(
        id: id,
        type: type,
        filePath: cacheFilePath,
        cachedAt: now,
        expiresAt: expiresAt,
      );
      _cache[_getCacheKey(id, type)] = entry;

      logger.d('$_TAG: Saved avatar file: $id (${_getTypeString(type)}) to $cacheFilePath');
      return true;
    } catch (e) {
      logger.e('$_TAG: Failed to save avatar file: $e');
      return false;
    }
  }

  /// Get avatar file for a sender
  Future<File?> getAvatar(String id, AvatarSenderType type) async {
    final cacheKey = _getCacheKey(id, type);
    final entry = _cache[cacheKey];

    // Check if cache entry exists and is not expired
    if (entry != null && !entry.isExpired) {
      final file = File(entry.filePath);
      if (await file.exists()) {
        return file;
      }
    }

    // Try to load from disk even if not in memory cache
    final filePath = await _getCacheFilePath(id, type);
    final file = File(filePath);
    if (await file.exists()) {
      // Rebuild cache entry
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + (_cacheExpirationHours * 60 * 60 * 1000);
      _cache[cacheKey] = AvatarCacheEntry(
        id: id,
        type: type,
        filePath: filePath,
        cachedAt: now,
        expiresAt: expiresAt,
      );
      return file;
    }

    return null;
  }

  /// Get avatar as base64 string
  Future<String?> getAvatarBase64(String id, AvatarSenderType type) async {
    final file = await getAvatar(id, type);
    if (file == null) return null;

    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      logger.e('$_TAG: Failed to read avatar as base64: $e');
      return null;
    }
  }

  /// Get avatar path for display
  Future<String?> getAvatarPath(String id, AvatarSenderType type) async {
    final file = await getAvatar(id, type);
    return file?.path;
  }

  /// Check if avatar exists in cache
  Future<bool> hasAvatar(String id, AvatarSenderType type) async {
    final file = await getAvatar(id, type);
    return file != null && await file.exists();
  }

  /// Remove avatar from cache
  Future<bool> removeAvatar(String id, AvatarSenderType type) async {
    try {
      final cacheKey = _getCacheKey(id, type);
      final entry = _cache[cacheKey];

      if (entry != null) {
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _cache.remove(cacheKey);
        logger.d('$_TAG: Removed avatar: $id (${_getTypeString(type)})');
      }

      return true;
    } catch (e) {
      logger.e('$_TAG: Failed to remove avatar: $e');
      return false;
    }
  }

  /// Clear all cached avatars
  Future<bool> clearCache() async {
    try {
      final dir = await _cacheDir;
      await dir.delete(recursive: true);
      _cache.clear();
      logger.d('$_TAG: Cleared all cached avatars');
      return true;
    } catch (e) {
      logger.e('$_TAG: Failed to clear cache: $e');
      return false;
    }
  }

  /// Cleanup expired cache entries
  Future<void> _cleanupExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredKeys = <String>[];

      for (final entry in _cache.entries) {
        if (entry.value.isExpired) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        final entry = _cache[key];
        if (entry != null) {
          final file = File(entry.filePath);
          if (await file.exists()) {
            await file.delete();
          }
          _cache.remove(key);
        }
      }

      if (expiredKeys.isNotEmpty) {
        logger.d('$_TAG: Cleaned up ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      logger.e('$_TAG: Failed to cleanup expired cache: $e');
    }
  }

  /// Load cache metadata from disk
  Future<void> _loadCacheFromDisk() async {
    try {
      final dir = await _cacheDir;
      final files = dir.list();

      await for (final entity in files) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          final parts = fileName.split('_');
          if (parts.length >= 2) {
            final typeStr = parts[0];
            final id = parts.sublist(1).join('_').replaceAll('.dat', '');
            final type = _getTypeFromString(typeStr);
            final cacheKey = _getCacheKey(id, type);

            final now = DateTime.now().millisecondsSinceEpoch;
            final expiresAt = now + (_cacheExpirationHours * 60 * 60 * 1000);

            _cache[cacheKey] = AvatarCacheEntry(
              id: id,
              type: type,
              filePath: entity.path,
              cachedAt: now,
              expiresAt: expiresAt,
            );
          }
        }
      }

      logger.d('$_TAG: Loaded ${_cache.length} cache entries from disk');
    } catch (e) {
      logger.e('$_TAG: Failed to load cache from disk: $e');
    }
  }

  /// Update schema cache with base64 data
  void _updateSchemaCache(String id, AvatarSenderType type, String base64Data) {
    // This will be called by the broadcast service to update the appropriate schema
    // Implementation depends on which schema is being updated
  }

  String _getCacheKey(String id, AvatarSenderType type) {
    return '${_getTypeString(type)}:$id';
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'total_entries': _cache.length,
      'cache_expiration_hours': _cacheExpirationHours,
      'entries': _cache.entries.map((e) => e.value.toJson()).toList(),
    };
  }
}
