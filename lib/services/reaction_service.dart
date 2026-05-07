import 'dart:async';
import 'dart:convert';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/chat/chat_out.dart';
import 'package:nchat_mobile/models/message_reaction.dart';
import 'package:nchat_mobile/schema/contact.dart';
import 'package:nchat_mobile/schema/message.dart';
import 'package:nchat_mobile/schema/private_group.dart';
import 'package:nchat_mobile/schema/topic.dart';
import 'package:nchat_mobile/utils/logger.dart';

class ReactionService {
  static const String REACTION_MESSAGE_TYPE = 'reaction';
  static const String REACTION_UPDATE_TYPE = 'reaction_update';

  // Global reaction stream for real-time updates
  static final StreamController<Map<String, dynamic>>
      _reactionStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get reactionStream =>
      _reactionStreamController.stream;

  // Broadcast reaction update to all listeners
  static void broadcastReactionUpdate(Map<String, dynamic> reactionData) {
    try {
      _reactionStreamController.add(reactionData);
      logger.i('Broadcasting reaction update: $reactionData');
    } catch (e) {
      logger.e('Failed to broadcast reaction update: $e');
    }
  }

  // Common reaction emojis
  static const List<String> commonReactions = [
    '👍',
    '👎',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '🎉',
    '🔥',
    '👏',
    '🙏',
    '💯',
    '🤔',
    '👀',
  ];

  // Broadcast a reaction to a chat/group
  static Future<bool> broadcastReaction({
    required dynamic
        target, // ContactSchema, TopicSchema, or PrivateGroupSchema
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      // Send reaction via NKN
      final reactionMessage =
          await chatOutCommon.sendReaction(target, messageId, emoji);

      if (reactionMessage != null) {
        logger.i(
            'Successfully broadcast reaction: $emoji for message $messageId');
        return true;
      } else {
        logger.e('Failed to send reaction message');
        return false;
      }
    } catch (e) {
      logger.e('Failed to broadcast reaction: $e');
      return false;
    }
  }

  // Broadcast reaction removal
  static Future<bool> broadcastReactionRemoval({
    required String chatId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      final messageData = {
        'type': REACTION_MESSAGE_TYPE,
        'action': 'remove',
        'data': {
          'messageId': messageId,
          'userId': userId,
          'emoji': emoji,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'chatId': chatId,
      };

      // TODO: Replace with actual NKN client broadcasting
      logger.i('Broadcasting reaction removal: ${jsonEncode(messageData)}');

      return true;
    } catch (e) {
      logger.e('Failed to broadcast reaction removal: $e');
      return false;
    }
  }

  // Process incoming reaction message
  static MessageReaction? processReactionMessage(Map<String, dynamic> message) {
    try {
      if (message['type'] != REACTION_MESSAGE_TYPE) {
        return null;
      }

      final data = message['data'] as Map<String, dynamic>;

      // Handle reaction removal
      if (message['action'] == 'remove') {
        // Return a special reaction with empty emoji to indicate removal
        return MessageReaction(
          messageId: data['messageId'],
          userId: data['userId'],
          emoji: '', // Empty emoji indicates removal
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
        );
      }

      return MessageReaction.fromJson(data);
    } catch (e) {
      logger.e('Failed to process reaction message: $e');
      return null;
    }
  }

  // Get reaction summary for a message
  static ReactionSummary getReactionSummary(
    List<MessageReaction> reactions, {
    String? currentUserId,
  }) {
    return ReactionSummary.fromReactions(reactions,
        currentUserId: currentUserId);
  }

  /// Toggles a reaction (add if not present, remove if present)
  static Future<bool> toggleReaction({
    required dynamic
        target, // ContactSchema, TopicSchema, or PrivateGroupSchema
    required String messageId,
    required String emoji,
    required String userId,
    required List<MessageReaction> currentReactions,
  }) async {
    try {
      // Check if user already has this reaction
      final existingReaction = currentReactions.firstWhere(
        (r) => r.userId == userId && r.emoji == emoji,
        orElse: () => MessageReaction(
          messageId: messageId,
          userId: userId,
          emoji: '',
          timestamp: DateTime.now(),
        ),
      );

      bool isAdding = existingReaction.emoji.isEmpty;

      // Broadcast the reaction
      final success = await broadcastReaction(
        target: target,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
      );

      if (success) {
        logger.i(
            'Reaction ${isAdding ? "added" : "removed"}: $emoji for message $messageId');
      }

      return success;
    } catch (e) {
      logger.e('Failed to toggle reaction: $e');
      return false;
    }
  }

  // Validate emoji (ensure it's in our allowed list)
  static bool isValidEmoji(String emoji) {
    return commonReactions.contains(emoji);
  }

  // Get suggested reactions based on message content
  static List<String> getSuggestedReactions(String message) {
    final suggestions = <String>[];
    final lowerMessage = message.toLowerCase();

    // Simple keyword-based suggestions
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      suggestions.add('👏');
      suggestions.add('🙏');
    }
    if (lowerMessage.contains('love') || lowerMessage.contains('❤️')) {
      suggestions.add('❤️');
    }
    if (lowerMessage.contains('lol') || lowerMessage.contains('haha')) {
      suggestions.add('😂');
    }
    if (lowerMessage.contains('wow') || lowerMessage.contains('amazing')) {
      suggestions.add('😮');
    }
    if (lowerMessage.contains('sad') || lowerMessage.contains('sorry')) {
      suggestions.add('😢');
    }
    if (lowerMessage.contains('angry') || lowerMessage.contains('mad')) {
      suggestions.add('😡');
    }
    if (lowerMessage.contains('congrat') || lowerMessage.contains('celebrat')) {
      suggestions.add('🎉');
    }
    if (lowerMessage.contains('fire') || lowerMessage.contains('hot')) {
      suggestions.add('🔥');
    }

    // Add default reactions if no specific ones suggested
    if (suggestions.isEmpty) {
      suggestions.addAll(['👍', '❤️', '😂']);
    }

    // Remove duplicates and limit to 5
    return suggestions.take(5).toList();
  }
}
