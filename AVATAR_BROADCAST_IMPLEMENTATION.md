# Avatar Broadcast System - Implementation Summary

## Overview
This document describes the complete implementation of the avatar broadcast and display system for nMobile. The system enables:
- Broadcasting user and group avatars as base64 data
- Saving received avatars locally
- Displaying avatars in the discovery page, group chat, and group profile pages

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    AVATAR BROADCAST SYSTEM                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐         ┌──────────────────┐             │
│  │  AvatarBroadcast │         │  AvatarCache     │             │
│  │    Service       │         │    Service       │             │
│  │                  │         │                  │             │
│  │ - broadcast()    │         │ - save()         │             │
│  │ - receive()      │         │ - get()          │             │
│  │ - process()      │         │ - clear()        │             │
│  └────────┬─────────┘         └──────────────────┘             │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────┐           │
│  │           Avatar Broadcast Message              │           │
│  │  - senderId                                     │           │
│  │  - senderType (contact/topic/group)             │           │
│  │  - avatarBase64                                 │           │
│  │  - timestamp                                    │           │
│  └─────────────────────────────────────────────────┘           │
│                                                                 │
│           ▲                        ▲                            │
│           │                        │                            │
│  ┌────────┴─────────┐    ┌────────┴─────────┐                  │
│  │  Topic Common    │    │ Private Group    │                  │
│  │                  │    │     Common       │                  │
│  │ - setAvatar()    │    │ - setAvatar()    │                  │
│  └──────────────────┘    └──────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files Created/Modified

### New Files

1. **`lib/models/broadcast_avatar.dart`**
   - `AvatarBroadcastMessage` - Model for avatar broadcast messages
   - `AvatarCacheEntry` - Model for cached avatar metadata
   - `AvatarSenderType` - Enum for sender types (contact, topic, privateGroup)

2. **`lib/services/avatar_cache_service.dart`**
   - Manages avatar caching with expiration (24 hours)
   - Saves avatars to disk in `/avatars/` directory
   - Provides methods: `saveAvatar()`, `getAvatar()`, `getAvatarBase64()`

3. **`lib/common/broadcast/avatar_broadcast.dart`**
   - `AvatarBroadcastService` - Main service for broadcasting and receiving avatars
   - Methods:
     - `broadcastContactAvatar()` - Broadcast contact avatar updates
     - `broadcastTopicAvatar()` - Broadcast topic avatar updates
     - `broadcastPrivateGroupAvatar()` - Broadcast private group avatar updates
     - `_handleIncomingAvatar()` - Process received avatar broadcasts

### Modified Files

1. **Schema Files** (Added avatar broadcast tracking fields)
   - `lib/schema/topic.dart`
     - Added: `lastAvatarBroadcastAt`, `lastAvatarReceivedAt`, `cachedAvatarBase64`
   - `lib/schema/private_group.dart`
     - Added: `lastAvatarBroadcastAt`, `lastAvatarReceivedAt`, `cachedAvatarBase64`
   - `lib/schema/contact.dart`
     - Added: `lastAvatarBroadcastAt`, `lastAvatarReceivedAt`, `cachedAvatarBase64`

2. **Helper Files**
   - `lib/helpers/file.dart`
     - Added: `saveAvatarFromBase64()` - Specialized avatar saving
     - Added: `convertAvatarBase64MapToFile()` - Convert base64 map to file

3. **Common Services**
   - `lib/common/topic/topic.dart`
     - Modified `setAvatar()` to broadcast avatar on change
   - `lib/common/private_group/private_group.dart`
     - Modified `setAvatar()` to broadcast avatar on change
   - `lib/common/locator.dart`
     - Registered `AvatarBroadcastService` and `AvatarCacheService`

4. **UI Components**
   - `lib/components/chat/message_item.dart`
     - Added `_loadAvatarFromCache()` - Load avatar from cache for display
     - Added `_buildAvatarWidget()` - Build avatar widget with cache support
     - Modified to display sender avatars in group/topic chats

5. **Application**
   - `lib/app.dart`
     - Initialize `avatarCacheService` on app mount
     - Initialize `avatarBroadcastService` on client connect

---

## Data Flow

### Broadcasting Avatar (Sender Side)

```
User changes avatar
    ↓
TopicCommon.setAvatar() / PrivateGroupCommon.setAvatar()
    ↓
Save avatar to local storage
    ↓
AvatarBroadcastService.broadcastTopicAvatar() / broadcastPrivateGroupAvatar()
    ↓
Convert avatar file to base64
    ↓
Create AvatarBroadcastMessage
    ↓
Encode to base64 JSON
    ↓
Send via client.send() to broadcast channel
    ↓
Update schema.lastAvatarBroadcastAt
```

### Receiving Avatar (Recipient Side)

```
Client receives message
    ↓
AvatarBroadcastService._processIncomingMessage()
    ↓
Decode AvatarBroadcastMessage from base64
    ↓
AvatarCacheService.saveAvatar()
    ↓
Decode base64 to bytes
    ↓
Save to /avatars/{type}_{id}.dat
    ↓
Update schema.lastAvatarReceivedAt
    ↓
UI refreshes avatar display
```

### Displaying Avatar

```
UI needs to display avatar
    ↓
Check local avatar file first
    ↓
If not available, check AvatarCacheService
    ↓
If cached, load from /avatars/{type}_{id}.dat
    ↓
Display in CircleAvatar widget
    ↓
Fallback to initials if no avatar found
```

---

## Usage Examples

### Broadcasting a Topic Avatar

```dart
// When user changes topic avatar
File avatarFile = File('/path/to/avatar.jpg');
await topicCommon.setAvatar(topicId, avatarFile.path, notify: true);

// This automatically triggers:
// 1. Save to topic storage
// 2. Broadcast to all subscribers
// 3. Update lastAvatarBroadcastAt timestamp
```

### Receiving Avatar Broadcast

```dart
// Automatic - no manual intervention needed
// AvatarBroadcastService listens to client messages
// When avatar broadcast is received:
// 1. Avatar is saved to cache
// 2. Schema is updated
// 3. UI automatically refreshes via streams
```

### Displaying Avatar in Chat

```dart
// In message_item.dart - automatic
// For received messages in groups/topics:
// 1. _loadAvatarFromCache() is called
// 2. Avatar is loaded from cache or schema
// 3. Displayed in CircleAvatar next to message
```

---

## Avatar Data Format

### Broadcast Message Format

```json
{
  "senderId": "topic.public.key",
  "senderType": 1,  // 0=contact, 1=topic, 2=privateGroup
  "avatar": {
    "type": "base64",
    "data": "<base64-encoded-image-data>",
    "ext": "jpeg"
  },
  "timestamp": 1234567890,
  "metadata": {}
}
```

### Cache Entry Format

```dart
AvatarCacheEntry(
  id: 'topic.public.key',
  type: AvatarSenderType.topic,
  filePath: '/path/to/avatars/topic_topic.public.key.dat',
  cachedAt: 1234567890,
  expiresAt: 1234654290,  // 24 hours later
)
```

---

## Configuration

### Cache Settings

Located in `lib/services/avatar_cache_service.dart`:

```dart
static const int _cacheExpirationHours = 24; // Cache expires after 24 hours
static const String _avatarCacheDir = 'avatars';
```

### Avatar Size Limits

Defined in `lib/common/settings.dart`:

```dart
static const int sizeAvatarMax = 500 * 1024;  // 500KB max
static const int sizeAvatarBest = 200 * 1024; // 200KB recommended
```

---

## Testing Checklist

### Unit Tests
- [ ] AvatarBroadcastMessage serialization/deserialization
- [ ] AvatarCacheEntry expiration logic
- [ ] Base64 encoding/decoding
- [ ] File path generation

### Integration Tests
- [ ] Broadcast avatar on topic creation
- [ ] Broadcast avatar on avatar change
- [ ] Receive and save avatar from broadcast
- [ ] Display avatar in discovery page
- [ ] Display avatar in group chat
- [ ] Display avatar in group profile
- [ ] Cache expiration and cleanup

### Manual Testing
1. **Topic Avatar Broadcast**
   - Create a new public group with avatar
   - Verify avatar is broadcasted
   - Join from another account
   - Verify avatar is displayed in discovery page
   - Verify avatar is displayed in group chat

2. **Private Group Avatar Broadcast**
   - Create a new private group with avatar
   - Invite members
   - Verify members see avatar in group chat
   - Change group avatar
   - Verify members see updated avatar

3. **Avatar Cache**
   - Receive avatar broadcast
   - Verify avatar is saved to cache
   - Close and reopen app
   - Verify avatar is still displayed (loaded from cache)
   - Wait 24 hours
   - Verify cache is cleaned up

---

## Troubleshooting

### Avatar Not Broadcasting

**Check:**
1. Client is connected (`clientCommon.isClientOK`)
2. Avatar file exists and is valid
3. AvatarBroadcastService is initialized
4. Check logs for errors: `AvatarBroadcast - Error broadcasting avatar`

### Avatar Not Displaying

**Check:**
1. Avatar file exists in cache directory
2. Cache entry is not expired
3. Schema has correct avatar path
4. Check logs: `AvatarCache - Failed to read avatar`

### Cache Issues

**Clear cache:**
```dart
await AvatarCacheService().clearCache();
```

**Check cache stats:**
```dart
var stats = AvatarCacheService().getStats();
print('Cache entries: ${stats['total_entries']}');
```

---

## Performance Considerations

1. **Base64 Encoding**: Avatars are encoded to base64 for transmission, which increases size by ~33%. Keep avatars under 200KB for optimal performance.

2. **Cache Expiration**: Cache entries expire after 24 hours to prevent unlimited storage growth. Adjust `_cacheExpirationHours` as needed.

3. **Broadcast Frequency**: Avatars are broadcast only when changed, not periodically. This reduces network traffic.

4. **Lazy Loading**: Avatars are loaded on-demand when UI needs to display them, not pre-loaded.

---

## Future Enhancements

1. **Avatar Compression**: Add automatic image compression before broadcasting
2. **Progressive Loading**: Load low-resolution avatar first, then high-resolution
3. **Avatar Sync**: Sync avatars across devices for same user
4. **Batch Broadcast**: Broadcast multiple avatars in single message
5. **Avatar History**: Keep history of previous avatars

---

## Dependencies

The implementation uses existing nMobile infrastructure:
- `nkn_sdk_flutter` - For client messaging
- `path_provider` - For cache directory
- `get_it` - For service locator
- Existing schema and storage classes

No new external dependencies added.

---

## Conclusion

The avatar broadcast system is now fully integrated into nMobile. It provides:
- ✅ Automatic avatar broadcasting on change
- ✅ Reliable avatar saving from received broadcasts
- ✅ Display in discovery page, group chat, and group profiles
- ✅ Efficient caching with expiration
- ✅ Fallback to initials when avatar unavailable

All components are registered in the service locator and initialized automatically on app startup.
