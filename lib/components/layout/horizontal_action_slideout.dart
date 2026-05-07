import 'package:flutter/material.dart';

/// A horizontal swipeable modal slideout that sits above the bottom menu bar
/// Contains page-specific actions that can be swiped horizontally
class HorizontalActionSlideout extends StatefulWidget {
  /// List of action items to display
  final List<SlideoutActionItem> items;

  /// Whether the slideout is currently visible
  final bool isVisible;

  /// Callback when slideout visibility changes
  final Function(bool isVisible)? onVisibilityChanged;

  /// Minimum height of the slideout
  final double minHeight;

  /// Maximum height of the slideout
  final double maxHeight;

  const HorizontalActionSlideout({
    Key? key,
    required this.items,
    this.isVisible = false,
    this.onVisibilityChanged,
    this.minHeight = 72,
    this.maxHeight = 180,
  }) : super(key: key);

  @override
  State<HorizontalActionSlideout> createState() =>
      _HorizontalActionSlideoutState();
}

class _HorizontalActionSlideoutState extends State<HorizontalActionSlideout> {
  late ScrollController _scrollController;
  bool _isExpanded = false;
  double _currentHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentHeight = widget.isVisible ? widget.minHeight : 0;
  }

  @override
  void didUpdateWidget(HorizontalActionSlideout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      _animateToHeight(widget.isVisible ? widget.minHeight : 0);
      widget.onVisibilityChanged?.call(widget.isVisible);
    }
  }

  void _animateToHeight(double targetHeight) {
    setState(() {
      _currentHeight = targetHeight;
    });
  }

  void _toggleExpanded() {
    final targetHeight = _isExpanded ? widget.minHeight : widget.maxHeight;
    setState(() {
      _isExpanded = !_isExpanded;
      _currentHeight = targetHeight;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: _currentHeight,
        child: _currentHeight > 0
            ? _buildSlideoutContent()
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSlideoutContent() {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle and expand/collapse indicator
            GestureDetector(
              onTap: _toggleExpanded,
              onVerticalDragUpdate: (details) {
                // Drag up to expand, down to collapse
                final delta = -details.delta.dy; // up is positive
                final minH = widget.minHeight;
                final maxH = widget.maxHeight;

                setState(() {
                  // If currently closed (height 0), only react to upward drags
                  if (_currentHeight == 0) {
                    if (delta <= 0) {
                      // dragging down on a closed sheet: ignore
                      return;
                    }
                    // First upward drag: start from minHeight
                    _currentHeight = minH;
                  }

                  // Once opened, keep height between min and max so it never vanishes
                  _currentHeight = (_currentHeight + delta).clamp(minH, maxH);

                  // Consider expanded if we're noticeably above minHeight
                  _isExpanded = _currentHeight > (minH + 10);
                });
              },
              onVerticalDragEnd: (details) {
                final minH = widget.minHeight;
                final maxH = widget.maxHeight;

                if (_currentHeight < (minH + maxH) / 2) {
                  // Snap to collapsed (min) state – never fully hidden
                  _isExpanded = false;
                  _animateToHeight(minH);
                  widget.onVisibilityChanged?.call(true);
                } else {
                  // Snap to fully expanded
                  _isExpanded = true;
                  _animateToHeight(maxH);
                  widget.onVisibilityChanged?.call(true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.hintColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Expand/collapse indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: theme.hintColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isExpanded
                              ? 'Swipe down to collapse'
                              : 'Swipe up for more actions',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Horizontal scrollable actions
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _buildActionItem(item, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(SlideoutActionItem item, int index) {
    final theme = Theme.of(context);
    final isLastItem = index == widget.items.length - 1;

    return Container(
      margin: EdgeInsets.only(right: isLastItem ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: item.color?.withValues(alpha: 0.1) ??
                  theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.color?.withValues(alpha: 0.2) ??
                    theme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                if (item.icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color?.withValues(alpha: 0.2) ??
                          theme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon!,
                        color: item.color ?? theme.primaryColor, size: 24),
                  ),
                if (item.icon != null) const SizedBox(height: 8),
                // Label
                Flexible(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: item.color ?? theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents an action item in the slideout
class SlideoutActionItem {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const SlideoutActionItem({
    required this.label,
    this.icon,
    this.color,
    required this.onTap,
  });
}
