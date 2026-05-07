class MessageReaction {
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime timestamp;

  MessageReaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'emoji': emoji,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      messageId: json['messageId'],
      userId: json['userId'],
      emoji: json['emoji'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  MessageReaction copyWith({
    String? messageId,
    String? userId,
    String? emoji,
    DateTime? timestamp,
  }) {
    return MessageReaction(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageReaction &&
        other.messageId == messageId &&
        other.userId == userId &&
        other.emoji == emoji;
  }

  @override
  int get hashCode => messageId.hashCode ^ userId.hashCode ^ emoji.hashCode;

  @override
  String toString() {
    return 'MessageReaction(messageId: $messageId, userId: $userId, emoji: $emoji, timestamp: $timestamp)';
  }
}

class ReactionSummary {
  final Map<String, int> emojiCounts;
  final Set<String> userReactions;
  final int totalCount;

  ReactionSummary({
    required this.emojiCounts,
    required this.userReactions,
    required this.totalCount,
  });

  factory ReactionSummary.fromReactions(List<MessageReaction> reactions, {String? currentUserId}) {
    final Map<String, int> counts = {};
    final Set<String> userReactedEmojis = {};

    for (final reaction in reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
      
      if (currentUserId != null && reaction.userId == currentUserId) {
        userReactedEmojis.add(reaction.emoji);
      }
    }

    return ReactionSummary(
      emojiCounts: counts,
      userReactions: userReactedEmojis,
      totalCount: reactions.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emojiCounts': emojiCounts,
      'userReactions': userReactions.toList(),
      'totalCount': totalCount,
    };
  }

  factory ReactionSummary.fromJson(Map<String, dynamic> json) {
    return ReactionSummary(
      emojiCounts: Map<String, int>.from(json['emojiCounts']),
      userReactions: Set<String>.from(json['userReactions']),
      totalCount: json['totalCount'],
    );
  }

  List<String> get mostPopularEmojis {
    final sorted = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(3).toList();
  }
}
