import 'package:flutter/material.dart';
import 'package:nchat_mobile/models/message_reaction.dart';

class MessageReactionsBar extends StatelessWidget {
  final ReactionSummary reactionSummary;
  final VoidCallback? onTap;
  final bool isMe;

  const MessageReactionsBar({
    Key? key,
    required this.reactionSummary,
    this.onTap,
    this.isMe = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (reactionSummary.totalCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.grey[700]?.withOpacity(0.8)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.grey[600]?.withOpacity(0.5) ?? Colors.transparent
                : Colors.grey[300]?.withOpacity(0.5) ?? Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show top 3 most popular reactions
            ...reactionSummary.mostPopularEmojis.take(3).map((emoji) {
              final count = reactionSummary.emojiCounts[emoji] ?? 0;
              final isUserReaction = reactionSummary.userReactions.contains(emoji);
              
              return Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUserReaction 
                      ? theme.primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isUserReaction
                      ? Border.all(
                          color: theme.primaryColor.withOpacity(0.5),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (count > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        count.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isUserReaction 
                              ? theme.primaryColor
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            
            // Show total count if there are more reactions than displayed
            if (reactionSummary.totalCount > 3) ...[
              const SizedBox(width: 4),
              Text(
                '+${reactionSummary.totalCount - 3}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReactionPicker extends StatefulWidget {
  final List<String> availableEmojis;
  final Function(String) onReactionSelected;
  final String? currentReaction;

  const ReactionPicker({
    Key? key,
    required this.availableEmojis,
    required this.onReactionSelected,
    this.currentReaction,
  }) : super(key: key);

  @override
  _ReactionPickerState createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'React',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Emoji grid
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: widget.availableEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = widget.availableEmojis[index];
                  final isSelected = widget.currentReaction == emoji;
                  
                  return GestureDetector(
                    onTap: () {
                      widget.onReactionSelected(emoji);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.primaryColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: theme.primaryColor.withOpacity(0.5),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show reaction picker
void showReactionPicker({
  required BuildContext context,
  required List<String> emojis,
  required Function(String) onReactionSelected,
  String? currentReaction,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Reaction Picker',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: ReactionPicker(
          availableEmojis: emojis,
          onReactionSelected: onReactionSelected,
          currentReaction: currentReaction,
        ),
      );
    },
  );
}
