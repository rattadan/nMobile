# Horizontal Action Slideout - Implementation Guide

## Overview

This document describes the **Horizontal Action Slideout** feature implemented in nMobile. This feature provides a persistent bottom menu bar with a swipeable horizontal modal slideout containing page-specific actions.

## Architecture

```
┌─────────────────────────────────────┐
│         Page Content                │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  Horizontal Action Slideout         │  ← Swipeable horizontally
│  [Action1] [Action2] [Action3]...   │    Expandable/collapsible
├─────────────────────────────────────┤
│  Bottom Navigation Bar              │  ← Persistent
│  [Chat]        [Settings]           │
└─────────────────────────────────────┘
```

## File Structure

```
lib/
├── app.dart                              # Main app widget with slideout state management
├── components/layout/
│   ├── horizontal_action_slideout.dart   # Main slideout widget component
│   ├── slideout_controller_provider.dart # Provider for child-screen communication
│   └── nav.dart                          # Enhanced bottom navigation with slideout support
└── screens/
    ├── chat/home.dart                    # Chat page with slideout integration
    └── settings/home.dart                # Settings page with slideout integration
```

## Key Components

### 1. `HorizontalActionSlideout` Widget
**Location:** `lib/components/layout/horizontal_action_slideout.dart`

A stateful widget that provides:
- Horizontal scrollable action items
- Expandable/collapsible height (min: 60px, max: 120px)
- Drag handle with visual feedback
- Swipe/tap to expand/collapse
- Customizable action items

**Parameters:**
```dart
HorizontalActionSlideout({
  required List<SlideoutActionItem> items,
  required bool isVisible,
  Function(bool isVisible)? onVisibilityChanged,
  double minHeight = 60,
  double maxHeight = 120,
})
```

### 2. `SlideoutActionItem` Class
**Location:** `lib/components/layout/horizontal_action_slideout.dart`

Represents a single action button in the slideout:

```dart
SlideoutActionItem({
  required String label,      // Display text
  IconData? icon,             // Optional icon
  Color? color,               // Optional custom color
  required VoidCallback onTap, // Tap handler
})
```

### 3. `SlideoutControllerProvider`
**Location:** `lib/components/layout/slideout_controller_provider.dart`

An `InheritedWidget` that allows child screens to communicate with the parent `AppScreen`:

```dart
SlideoutControllerProvider.of(context)?.updateSlideoutContent(pageIndex, widget);
SlideoutControllerProvider.of(context)?.updateSlideoutVisibility(pageIndex, isVisible);
```

### 4. `SlideoutControllerMixin`
**Location:** `lib/components/layout/slideout_controller_provider.dart`

A mixin to simplify slideout control in screen widgets:

```dart
class _MyScreenState extends State<MyScreen> with SlideoutControllerMixin {
  @override
  void initState() {
    super.initState();
    updateSlideoutContent(_buildSlideout());
  }
  
  void _onAction() {
    updateSlideoutVisibility(true);
  }
}
```

## Usage Guide

### Adding Slideout to a New Page

#### Step 1: Add Imports
```dart
import 'package:nmobile/components/layout/horizontal_action_slideout.dart';
import 'package:nmobile/components/layout/slideout_controller_provider.dart';
```

#### Step 2: Add Mixin to State Class
```dart
class _MyScreenState extends BaseStateFulWidgetState<MyScreen>
    with AutomaticKeepAliveClientMixin, SlideoutControllerMixin {
  
  bool _isSlideoutVisible = false;
  List<SlideoutActionItem> _actions = [];
  
  // ...
}
```

#### Step 3: Initialize Actions in `initState`
```dart
@override
void initState() {
  super.initState();
  
  _initializeActions();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      updateSlideoutContent(_buildSlideout());
    }
  });
}

void _initializeActions() {
  _actions = [
    SlideoutActionItem(
      label: 'Action 1',
      icon: Icons.add,
      color: Colors.blue,
      onTap: () => _handleAction1(),
    ),
    SlideoutActionItem(
      label: 'Action 2',
      icon: Icons.search,
      color: Colors.green,
      onTap: () => _handleAction2(),
    ),
    // Add more actions as needed
  ];
}
```

#### Step 4: Build Slideout Widget
```dart
Widget _buildSlideout() {
  return HorizontalActionSlideout(
    items: _actions,
    isVisible: _isSlideoutVisible,
    onVisibilityChanged: (isVisible) {
      setState(() {
        _isSlideoutVisible = isVisible;
      });
    },
  );
}
```

#### Step 5: Clean Up in `dispose`
```dart
@override
void dispose() {
  updateSlideoutContent(SizedBox.shrink());
  super.dispose();
}
```

## Current Implementations

### Chat Home Screen Actions
**Location:** `lib/screens/chat/home.dart`

| Action | Icon | Color | Function |
|--------|------|-------|----------|
| New Group | `Icons.group_add` | Blue | Opens create channel dialog |
| Discover | `Icons.explore` | Green | Opens public group discovery |
| Scan QR | `Icons.qr_code_scanner` | Purple | QR scanner (TBD) |
| Broadcast | `Icons.campaign` | Orange | Shows broadcast menu |

### Settings Home Screen Actions
**Location:** `lib/screens/settings/home.dart`

| Action | Icon | Color | Function |
|--------|------|-------|----------|
| Wallet | `Icons.account_balance_wallet` | Blue | Navigate to wallet |
| Language | `Icons.language` | Green | Change language |
| Security | `Icons.security` | Purple | Security settings (TBD) |
| Develop | `Icons.developer_mode` | Orange | Developer settings |

## Customization

### Changing Slideout Dimensions
Edit default values in `HorizontalActionSlideout`:
```dart
HorizontalActionSlideout(
  minHeight: 80,  // Default: 60
  maxHeight: 150, // Default: 120
  // ...
)
```

### Styling Action Items
Each action item can be customized:
```dart
SlideoutActionItem(
  label: 'Custom Action',
  icon: Icons.star,
  color: Colors.amber, // Custom color
  onTap: () {
    // Custom action
  },
)
```

### Adding Dynamic Actions
Actions can be updated dynamically:
```dart
void _updateActionsBasedOnState() {
  setState(() {
    _actions = [
      // Conditional actions
      if (isLoggedIn)
        SlideoutActionItem(/* ... */),
      
      // Context-aware actions
      if (hasUnreadMessages)
        SlideoutActionItem(/* ... */),
    ];
    updateSlideoutContent(_buildSlideout());
  });
}
```

## State Management

### Page Navigation
When switching between pages (Chat ↔ Settings):
1. Each page maintains its own slideout content
2. Slideout visibility is tracked per page index
3. Content is automatically cleared when leaving a page

### Visibility States
```dart
Map<int, bool> _slideoutVisibility = {
  0: false, // Chat page
  1: false, // Settings page
};
```

## Best Practices

### DO ✅
- Keep action labels short (1-2 words)
- Use meaningful icons that represent the action
- Limit to 4-6 actions per page for usability
- Clear slideout content in `dispose()`
- Use `WidgetsBinding.instance.addPostFrameCallback` for initial setup

### DON'T ❌
- Don't add too many actions (causes horizontal overflow)
- Don't use complex widgets as actions
- Don't forget to clean up in `dispose()`
- Don't update slideout content before widget is mounted

## Troubleshooting

### Slideout Not Showing
1. Check if `updateSlideoutContent()` is called after widget is mounted
2. Verify actions list is not empty
3. Ensure `SlideoutControllerProvider` wraps the page

### Actions Not Responding to Taps
1. Verify `onTap` callback is properly defined
2. Check if action is being disposed prematurely
3. Ensure no gesture detectors are blocking taps

### State Not Updating
1. Wrap state changes in `setState()`
2. Check if widget is still mounted before updating
3. Verify mixin is properly included in state class

## Future Enhancements

Potential improvements for consideration:

1. **Gesture Controls**
   - Add swipe left/right to trigger first/last action
   - Long-press for action context menu

2. **Visual Customization**
   - Theme-aware colors
   - Custom action button shapes
   - Animated icon transitions

3. **Performance**
   - Lazy loading for action icons
   - Cache slideout content per page

4. **Accessibility**
   - Screen reader support
   - Keyboard navigation
   - Larger touch targets option

## Related Files

- **Message Schema:** `lib/schema/message.dart` - Defines message structure used in chat actions
- **Bottom Menu:** `lib/components/chat/bottom_menu.dart` - Legacy bottom menu (can be refactored)
- **Navigation:** `lib/components/layout/nav.dart` - Bottom navigation bar
- **App Entry:** `lib/app.dart` - Main app state management

## Version History

- **v1.0** (Feb 2026) - Initial implementation
  - Horizontal swipeable slideout
  - Page-specific actions
  - Expandable/collapsible design
  - Chat and Settings page integration

---

**Maintained by:** nMobile Development Team  
**Last Updated:** February 19, 2026
