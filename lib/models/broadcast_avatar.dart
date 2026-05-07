import 'dart:convert';

/// Type of sender for avatar broadcasts
enum AvatarSenderType {
  contact,
  topic,
  privateGroup,
}

/// Avatar broadcast message model
/// Used to transmit avatar updates across the network
class AvatarBroadcastMessage {
  final String senderId;
  final AvatarSenderType senderType;
  final String avatarBase64;
  final String avatarExt;
  final int timestamp;
  final Map<String, dynamic> metadata;

  AvatarBroadcastMessage({
    required this.senderId,
    required this.senderType,
    required this.avatarBase64,
    required this.avatarExt,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderType': senderType.index,
      'avatar': {
        'type': 'base64',
        'data': avatarBase64,
        'ext': avatarExt,
      },
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  /// Create from JSON map
  factory AvatarBroadcastMessage.fromJson(Map<String, dynamic> json) {
    return AvatarBroadcastMessage(
      senderId: json['senderId'] as String,
      senderType: AvatarSenderType.values[json['senderType'] as int],
      avatarBase64: (json['avatar'] as Map<String, dynamic>)['data'] as String,
      avatarExt: (json['avatar'] as Map<String, dynamic>)['ext'] as String,
      timestamp: json['timestamp'] as int,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
    );
  }

  /// Serialize to base64-encoded JSON string for transmission
  String encode() {
    final jsonString = jsonEncode(toJson());
    return base64Encode(utf8.encode(jsonString));
  }

  /// Deserialize from base64-encoded JSON string
  static AvatarBroadcastMessage? decode(String encoded) {
    try {
      final jsonString = utf8.decode(base64Decode(encoded));
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AvatarBroadcastMessage.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Get sender type as string
  String get senderTypeString {
    switch (senderType) {
      case AvatarSenderType.contact:
        return 'contact';
      case AvatarSenderType.topic:
        return 'topic';
      case AvatarSenderType.privateGroup:
        return 'private_group';
    }
  }

  @override
  String toString() {
    return 'AvatarBroadcastMessage(senderId: $senderId, senderType: $senderTypeString, timestamp: $timestamp)';
  }
}

/// Avatar cache entry for storing received avatars
class AvatarCacheEntry {
  final String id;
  final AvatarSenderType type;
  final String filePath;
  final int cachedAt;
  final int expiresAt;

  AvatarCacheEntry({
    required this.id,
    required this.type,
    required this.filePath,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// Check if cache entry is expired
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'filePath': filePath,
      'cachedAt': cachedAt,
      'expiresAt': expiresAt,
    };
  }

  /// Create from JSON map
  factory AvatarCacheEntry.fromJson(Map<String, dynamic> json) {
    return AvatarCacheEntry(
      id: json['id'] as String,
      type: AvatarSenderType.values[json['type'] as int],
      filePath: json['filePath'] as String,
      cachedAt: json['cachedAt'] as int,
      expiresAt: json['expiresAt'] as int,
    );
  }

  @override
  String toString() {
    return 'AvatarCacheEntry(id: $id, type: $type, filePath: $filePath)';
  }
}
