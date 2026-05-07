import 'package:flutter/material.dart';

/// Provider that allows child screens to communicate with the parent AppScreen
/// for controlling the horizontal action slideout
class SlideoutControllerProvider extends InheritedWidget {
  final Function(int pageIndex, Widget content) updateSlideoutContent;
  final Function(int pageIndex, bool isVisible) updateSlideoutVisibility;
  final int currentPageIndex;

  const SlideoutControllerProvider({
    Key? key,
    required Widget child,
    required this.updateSlideoutContent,
    required this.updateSlideoutVisibility,
    required this.currentPageIndex,
  }) : super(key: key, child: child);

  static SlideoutControllerProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlideoutControllerProvider>();
  }

  @override
  bool updateShouldNotify(SlideoutControllerProvider oldWidget) {
    return updateSlideoutContent != oldWidget.updateSlideoutContent ||
        updateSlideoutVisibility != oldWidget.updateSlideoutVisibility ||
        currentPageIndex != oldWidget.currentPageIndex;
  }
}

/// Helper mixin for stateful widgets to easily access slideout controller
mixin SlideoutControllerMixin<T extends StatefulWidget> on State<T> {
  SlideoutControllerProvider? get _slideoutProvider => 
      SlideoutControllerProvider.of(context);
  
  int get currentPageIndex => _slideoutProvider?.currentPageIndex ?? 0;
  
  void updateSlideoutContent(Widget content) {
    _slideoutProvider?.updateSlideoutContent(currentPageIndex, content);
  }
  
  void updateSlideoutVisibility(bool isVisible) {
    _slideoutProvider?.updateSlideoutVisibility(currentPageIndex, isVisible);
  }
  
  @override
  void dispose() {
    // Clear slideout content when widget is disposed
    _slideoutProvider?.updateSlideoutContent(currentPageIndex, SizedBox.shrink());
    super.dispose();
  }
}
