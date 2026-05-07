import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/blocs/wallet/wallet_bloc.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/application.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/dialog/bottom.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/layout/horizontal_action_slideout.dart';
import 'package:nchat_mobile/components/layout/slideout_controller_provider.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/common/discovery/public_group_discovery.dart';
import 'package:nchat_mobile/screens/chat/messages.dart';
import 'package:nchat_mobile/screens/topic/profile.dart';
import 'package:nchat_mobile/schema/contact.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/schema/topic.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/components/tip/toast.dart';

class NewDiscoveryScreen extends BaseStateFulWidget {
  static const String routeName = '/discovery/new';

  static go(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  _NewDiscoveryScreenState createState() => _NewDiscoveryScreenState();
}

class _NewDiscoveryScreenState
    extends BaseStateFulWidgetState<NewDiscoveryScreen>
    with SlideoutControllerMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PublicGroupInfo> _discoveredGroups = [];
  List<PublicGroupInfo> _filteredGroups = [];
  bool _isLoading = false;
  String? _selectedCategory;
  StreamSubscription? _groupsSubscription;

  // Discovery service instance
  final PublicGroupDiscoveryService discoveryService =
      locator.get<PublicGroupDiscoveryService>();

  // Slideout state
  bool _isSlideoutExpanded = false;
  double _slideoutHeight = 40; // Closed height (just handle)
  final double _minHeight = 40; // Handle height
  final double _maxHeight =
      196; // Fully expanded height (reduced from 200 to prevent overflow)
  List<SlideoutActionItem> _actions = [];

  // Categories for filtering
  static const List<Map<String, String>> CATEGORIES = [
    {'id': 'all', 'name': 'All', 'icon': '🌍'},
    {'id': 'general', 'name': 'General', 'icon': '💬'},
    {'id': 'technology', 'name': 'Tech', 'icon': '💻'},
    {'id': 'business', 'name': 'Business', 'icon': '💼'},
    {'id': 'entertainment', 'name': 'Fun', 'icon': '🎬'},
    {'id': 'sports', 'name': 'Sports', 'icon': '⚽'},
    {'id': 'education', 'name': 'Learn', 'icon': '📚'},
    {'id': 'gaming', 'name': 'Gaming', 'icon': '🎮'},
  ];

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();
    _initializeActions();
    _startDiscovery();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _groupsSubscription?.cancel();
    super.dispose();
  }

  void _initializeActions() {
    _actions = [
      SlideoutActionItem(
        label: 'Search',
        icon: Icons.search,
        color: Color(0xFF34C759),
        onTap: _focusSearch,
      ),
      SlideoutActionItem(
        label: 'Refresh',
        icon: Icons.refresh,
        color: Color(0xFF5856D6),
        onTap: _refreshDiscovery,
      ),
      SlideoutActionItem(
        label: 'Broadcast all',
        icon: Icons.campaign,
        color: Color(0xFFFF9500),
        onTap: _broadcastMyGroups,
      ),
      SlideoutActionItem(
        label: 'Create Group',
        icon: Icons.group_add,
        color: Color(0xFF007AFF),
        onTap: _createNewGroup,
      ),
    ];
  }

  void _createNewGroup() {
    BottomDialog.of(context).showWithTitle(
      height: MediaQuery.of(context).size.height * 0.8,
      title: 'Create New Group',
      child: const SizedBox.shrink(),
    );
  }

  void _broadcastMyGroups() async {
    try {
      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning groups and preparing avatars...')),
      );

      // Trigger discovery service to scan local groups and convert avatars to base64
      await discoveryService.start();

      // Now broadcast all known groups (including avatars)
      await discoveryService.broadcastAllKnownGroups();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Broadcast complete with avatars!')),
      );
      logger.i('Discovery - Successfully broadcasted groups with avatars');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      logger.e('Error broadcasting groups: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to broadcast groups')),
      );
    }
  }

  void _focusSearch() {
    // Focus on search field
    FocusScope.of(context).requestFocus(FocusNode());
    // Small delay to ensure keyboard is up
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Subscribe to publicGroups topic
      logger.i("Subscribing to publicGroups topic...");
      await topicCommon.subscribe(
        PublicGroupDiscoveryService.DISCOVERY_TOPIC,
        fetchSubscribers: true,
      );
      logger.i("Subscribed to publicGroups topic");

      // Load cached groups
      await discoveryService.loadCache();
      logger.i("Discovery service cache loaded");

      // Refresh from channel messages
      await discoveryService.refreshDiscovery();

      // Listen to groups stream
      _groupsSubscription = discoveryService.groupsStream?.listen((groups) {
        if (mounted) {
          setState(() {
            _discoveredGroups = groups;
            _applyFilters();
          });
        }
      });

      // Initial load
      setState(() {
        _discoveredGroups = discoveryService.knownGroups;
        _applyFilters();
      });
    } catch (e) {
      logger.e("Error starting discovery service: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start discovery')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await discoveryService.refreshDiscovery();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refreshed discovery')),
      );
    } catch (e) {
      logger.e("Error refreshing discovery: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    String query = _searchController.text.trim().toLowerCase();
    String? category = _selectedCategory;

    List<PublicGroupInfo> filtered = _discoveredGroups;

    // Apply category filter
    if (category != null && category != 'all') {
      filtered = filtered.where((group) => group.category == category).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((group) {
        return group.name.toLowerCase().contains(query) ||
            (group.description?.toLowerCase().contains(query) ?? false) ||
            group.topicId.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredGroups = filtered;
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _applyFilters();
    });
  }

  Future<void> _joinGroup(PublicGroupInfo group) async {
    try {
      // Check if already subscribed
      TopicSchema? existingTopic = await topicCommon.query(group.topicId);

      if (existingTopic != null && existingTopic.joined) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Already joined this group')),
        );
        ChatMessagesScreen.go(context, existingTopic);
        return;
      }

      // Subscribe to topic
      await topicCommon.subscribe(group.topicId, fetchSubscribers: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${group.name}')),
      );

      // Navigate to chat
      TopicSchema? topic = await topicCommon.query(group.topicId);
      if (topic != null) {
        ChatMessagesScreen.go(context, topic);
      }
    } catch (e) {
      logger.e('Error joining group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join group')),
      );
    }
  }

  void _toggleSlideout() {
    setState(() {
      _isSlideoutExpanded = !_isSlideoutExpanded;
      _slideoutHeight = _isSlideoutExpanded ? _maxHeight : _minHeight;
    });
  }

  Widget _buildPersistentSlideout() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // More sensitive drag detection
        final newHeight =
            _slideoutHeight - (details.delta.dy * 1.5); // Increase sensitivity
        if (newHeight >= _minHeight && newHeight <= _maxHeight) {
          setState(() {
            _slideoutHeight = newHeight;
            _isSlideoutExpanded = newHeight > _minHeight + 20;
          });
        }
      },
      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (velocity > 300) {
          // Reduced threshold for easier closing
          // Swiped down quickly - close
          setState(() {
            _slideoutHeight = _minHeight;
            _isSlideoutExpanded = false;
          });
        } else if (velocity < -300) {
          // Reduced threshold for easier opening
          // Swiped up quickly - open
          setState(() {
            _slideoutHeight = _maxHeight;
            _isSlideoutExpanded = true;
          });
        } else {
          // Snap to nearest position
          final midPoint = (_minHeight + _maxHeight) / 2;
          if (_slideoutHeight < midPoint) {
            setState(() {
              _slideoutHeight = _minHeight;
              _isSlideoutExpanded = false;
            });
          } else {
            setState(() {
              _slideoutHeight = _maxHeight;
              _isSlideoutExpanded = true;
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _slideoutHeight,
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle - make it more tappable
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSlideoutExpanded = !_isSlideoutExpanded;
                  _slideoutHeight =
                      _isSlideoutExpanded ? _maxHeight : _minHeight;
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: 12), // Increased padding for easier tapping
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Actions (only show when expanded)
            if (_isSlideoutExpanded) ...[
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 0, 16, 12), // Reduced bottom padding from 16 to 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discovery actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 16 to 12
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionChip(
                          label: 'Search',
                          icon: Icons.search,
                          color: const Color(0xFF34C759),
                          onTap: _focusSearch,
                        ),
                        _buildActionChip(
                          label: 'Refresh',
                          icon: Icons.refresh,
                          color: const Color(0xFF5856D6),
                          onTap: _refreshDiscovery,
                        ),
                        _buildActionChip(
                          label: 'Broadcast all',
                          icon: Icons.campaign,
                          color: const Color(0xFFFF9500),
                          onTap: _broadcastMyGroups,
                        ),
                        _buildActionChip(
                          label: 'Create group',
                          icon: Icons.group_add,
                          color: const Color(0xFF007AFF),
                          onTap: _createNewGroup,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Reduced from 12 to 8
                    // Additional space for better scrolling when fully expanded
                    SizedBox(height: 8), // Reduced from 20 to 8
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark background
      body: Stack(
        children: [
          // Main content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 90, // Height of bottom nav
            child: ClipRect(
              child: Column(
                children: [
                  // Header with search
                  _buildHeader(),
                  // Category filters
                  _buildCategoryFilters(),
                  // Groups list
                  Expanded(
                    child: _buildGroupsList(),
                  ),
                ],
              ),
            ),
          ),
          // Persistent slideout - behind bottom nav
          Positioned(
            bottom: 146, // Exactly at the top edge of bottom nav
            left: 0,
            right: 0,
            child: _buildPersistentSlideout(),
          ),
          // Bottom navigation - on top (highest z-index)
          Positioned(
            bottom: 46,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Color(0xFF1E1E1E), // Dark header
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title and back button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: application.theme.fontColor1),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Discover Groups',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            application.theme.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2C2C2C), // Dark search bar
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF3C3C3C),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search groups...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: CATEGORIES.length,
        itemBuilder: (context, index) {
          final category = CATEGORIES[index];
          final isSelected = _selectedCategory == category['id'] ||
              (_selectedCategory == null && category['id'] == 'all');

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _selectCategory(category['id']),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? application.theme.primaryColor
                      : Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? application.theme.primaryColor
                        : Color(0xFF3C3C3C),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['icon']!,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 6),
                    Text(
                      category['name']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_isLoading && _filteredGroups.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(application.theme.primaryColor),
        ),
      );
    }

    if (_filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: Colors.white38,
            ),
            SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDiscovery,
      color: application.theme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredGroups.length,
        itemBuilder: (context, index) {
          return _buildGroupCard(_filteredGroups[index]);
        },
      ),
    );
  }

  Widget _buildGroupCard(PublicGroupInfo group) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF3C3C3C),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _joinGroup(group),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: application.theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: application.theme.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildGroupAvatar(group),
                  ),
                ),
                SizedBox(width: 12),
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (group.description != null &&
                          group.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          group.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Category badge
                          if (group.category != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: application.theme.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getCategoryEmoji(group.category) +
                                    ' ' +
                                    group.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: application.theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          // Subscriber count
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.white54,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${group.subscriberCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Join button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: application.theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(PublicGroupInfo group) {
    // Check if avatar path exists and is valid
    if (group.avatarPath != null && group.avatarPath!.isNotEmpty) {
      final avatarFile = File(group.avatarPath!);

      // Log avatar info for debugging
      logger.d(
          'Discovery - Loading avatar for ${group.name}: ${group.avatarPath}');

      return Image.file(
        avatarFile,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
        errorBuilder: (context, error, stackTrace) {
          logger
              .w('Discovery - Failed to load avatar for ${group.name}: $error');
          return _buildDefaultAvatar(group);
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    // No avatar path, show default
    logger.d('Discovery - No avatar path for ${group.name}, showing default');
    return _buildDefaultAvatar(group);
  }

  Widget _buildDefaultAvatar(PublicGroupInfo group) {
    return Container(
      width: 56,
      height: 56,
      color: application.theme.primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: application.theme.primaryColor,
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    final cat = CATEGORIES.firstWhere(
      (c) => c['id'] == category,
      orElse: () => {'icon': '💬'},
    );
    return cat['icon'] ?? '💬';
  }

  Widget _buildBottomNav() {
    Color _color = Colors.white54;
    Color _selectedColor = application.theme.primaryColor;

    return PhysicalModel(
      color: Color(0xFF1E1E1E), // Dark bottom nav
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF3C3C3C),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: 1, // Discovery is index 1
          selectedItemColor: _selectedColor,
          unselectedItemColor: _color,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pop();
            } else if (index == 1) {
              // Toggle slideout
              _toggleSlideout();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
          ],
        ),
      ),
    );
  }
}
