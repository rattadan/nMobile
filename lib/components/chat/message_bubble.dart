import 'package:flutter/material.dart';
import 'package:nchat_mobile/theme/app_theme.dart';
import 'package:nchat_mobile/models/message_reaction.dart';
import 'package:nchat_mobile/components/chat/message_reactions.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String? time;
  final bool showTime;
  final bool showStatus;
  final bool isRead;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final ReactionSummary? reactionSummary;
  final VoidCallback? onReactionTap;
  final String? messageId;

  const MessageBubble({
    Key? key,
    required this.message,
    this.isMe = false,
    this.time,
    this.showTime = true,
    this.showStatus = true,
    this.isRead = false,
    this.isSelected = false,
    this.onLongPress,
    this.reactionSummary,
    this.onReactionTap,
    this.messageId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: isMe
                    ? AppTheme.sentMessageBubble.copyWith(
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.7)
                            : theme.primaryColor,
                      )
                    : AppTheme.receivedMessageBubble.copyWith(
                        color: isSelected
                            ? (isDark ? Colors.grey[600] : Colors.grey[300])
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                      ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Message text
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Time and status
                    if (showTime || showStatus)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (time != null && showTime)
                            Text(
                              time!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isMe
                                    ? Colors.white.withOpacity(0.8)
                                    : theme.textTheme.bodySmall?.color,
                                fontSize: 10,
                              ),
                            ),
                          if (showStatus && isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: isRead
                                  ? const Color(0xFF53BDFB)
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ],
                      ),
                    // Reactions bar
                    if (reactionSummary != null)
                      MessageReactionsBar(
                        reactionSummary: reactionSummary!,
                        onTap: onReactionTap,
                        isMe: isMe,
                      ),
                  ],
                ),
              ),
            ),
            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
