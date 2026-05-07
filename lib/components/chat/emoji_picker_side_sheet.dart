import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerSideSheet extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final VoidCallback onClose;

  const EmojiPickerSideSheet({
    Key? key,
    required this.onEmojiSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  _EmojiPickerSideSheetState createState() => _EmojiPickerSideSheetState();
}

class _EmojiPickerSideSheetState extends State<EmojiPickerSideSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the animation when the widget is created
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _close, // Close when tapping outside
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Emoji',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _close,
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Emoji Picker
                  Expanded(
                    child: EmojiPicker(
                      onEmojiSelected: (Category? category, Emoji emoji) {
                        widget.onEmojiSelected(emoji.emoji);
                        // Don't close immediately to allow multiple selections
                      },
                      onBackspacePressed: () {
                        // Handle backspace if needed
                      },
                      config: Config(
                        height: MediaQuery.of(context).size.height * 0.6,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          columns: 8,
                          emojiSizeMax: 32.0,
                          verticalSpacing: 0,
                          horizontalSpacing: 0,
                          gridPadding: EdgeInsets.zero,
                          backgroundColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          initCategory: Category.RECENT,
                          backgroundColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          indicatorColor: theme.primaryColor,
                          iconColor: isDark ? Colors.white70 : Colors.black54,
                          iconColorSelected: theme.primaryColor,
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          backgroundColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[50],
                          buttonColor: isDark ? Colors.white70 : Colors.black54,
                          buttonIconColor:
                              isDark ? Colors.white70 : Colors.black54,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          buttonIconColor:
                              isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget to show the emoji picker side sheet
void showEmojiPickerSideSheet({
  required BuildContext context,
  required Function(String) onEmojiSelected,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Emoji Picker',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EmojiPickerSideSheet(
        onEmojiSelected: onEmojiSelected,
        onClose: () => Navigator.of(context).pop(),
      );
    },
  );
}
