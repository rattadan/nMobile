import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/utils/asset.dart';

class Nav extends BaseStateFulWidget {
  PageController controller;
  List<Widget> screens;
  int currentIndex = 0;

  // Slideout content for each page
  final Map<int, Widget>? slideoutContent;
  // Whether slideout is visible for each page
  final Map<int, bool> slideoutVisibility;
  // Callback when slideout visibility changes
  final Function(int pageIndex, bool isVisible)? onSlideoutVisibilityChanged;

  Nav({
    required this.screens,
    required this.controller,
    this.currentIndex = 0,
    this.slideoutContent,
    this.slideoutVisibility = const {},
    this.onSlideoutVisibilityChanged,
  });

  @override
  _NavState createState() => new _NavState();
}

class _NavState extends BaseStateFulWidgetState<Nav> {
  var _theme = application.theme;

  @override
  void onRefreshArguments() {
    _theme = application.theme;
  }

  void _onItemTapped(int index) {
    setState(() {
      widget.currentIndex = index;
      widget.controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color _color = Theme.of(context).unselectedWidgetColor;
    Color _selectedColor = _theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slideout content area (if exists for current page)
        if (widget.slideoutContent != null &&
            widget.slideoutContent!.containsKey(widget.currentIndex))
          widget.slideoutContent![widget.currentIndex]!,

        // Bottom navigation bar
        BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Asset.iconSvg('chat', color: _color),
              activeIcon: Asset.iconSvg('chat', color: _selectedColor),
              label: Settings.locale((s) => s.menu_chat, ctx: context),
            ),
            BottomNavigationBarItem(
              icon: Asset.svg('ethereum-logo', color: _color),
              activeIcon: Asset.svg('ethereum-logo', color: _selectedColor),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Asset.iconSvg('settings', color: _color),
              activeIcon: Asset.iconSvg('settings', color: _selectedColor),
              label: Settings.locale((s) => s.menu_settings, ctx: context),
            ),
          ],
        ),
      ],
    );
  }
}
