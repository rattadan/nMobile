import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/discovery/public_group_storage.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/common/discovery/public_group_discovery.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/chat/bottom_menu.dart';
import 'package:nchat_mobile/components/dialog/bottom.dart';
import 'package:nchat_mobile/components/layout/chat_topic_search.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/schema/topic.dart';
import 'package:nchat_mobile/screens/chat/messages.dart';
import 'package:nchat_mobile/utils/logger.dart';

class PublicGroupDiscoveryScreen extends BaseStateFulWidget {
  static const String routeName = '/discovery/public_groups';

  static go(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  _PublicGroupDiscoveryScreenState createState() =>
      _PublicGroupDiscoveryScreenState();
}

class _PublicGroupDiscoveryScreenState
    extends BaseStateFulWidgetState<PublicGroupDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PublicGroupInfo> _discoveredGroups = [];
  List<PublicGroupInfo> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _selectedCategory;

  // Discovery service instance
  final PublicGroupDiscoveryService discoveryService =
      locator.get<PublicGroupDiscoveryService>();

  // Categories for filtering
  static const List<Map<String, String>> CATEGORIES = [
    {'id': 'all', 'name': 'All', 'icon': '🌍'},
    {'id': 'general', 'name': 'General', 'icon': '💬'},
    {'id': 'technology', 'name': 'Technology', 'icon': '💻'},
    {'id': 'business', 'name': 'Business', 'icon': '💼'},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': '🎬'},
    {'id': 'sports', 'name': 'Sports', 'icon': '⚽'},
    {'id': 'education', 'name': 'Education', 'icon': '📚'},
    {'id': 'health', 'name': 'Health', 'icon': '🏥'},
    {'id': 'art', 'name': 'Art', 'icon': '🎨'},
    {'id': 'music', 'name': 'Music', 'icon': '🎵'},
    {'id': 'gaming', 'name': 'Gaming', 'icon': '🎮'},
    {'id': 'science', 'name': 'Science', 'icon': '🔬'},
  ];

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();
    _startDiscovery();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
      });
      discoveryService.queryGroups(query);
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Subscribe to publicGroups topic to receive messages
      logger.i("Subscribing to publicGroups topic...");
      await topicCommon.subscribe(
        PublicGroupDiscoveryService.DISCOVERY_TOPIC,
        fetchSubscribers: true,
      );
      logger.i("Subscribed to publicGroups topic");

      // Load cached groups (wait for it to complete)
      await discoveryService.loadCache();
      logger.i("Discovery service cache loaded");

      logger.i("Discovery service started");

      // Refresh from channel messages
      await _refreshDiscovery();
    } catch (e) {
      logger.e("Error starting discovery service: $e");
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
      // Read messages from publicGroups channel and process them
      logger.i("Refreshing discovery - reading messages from publicGroups");
      int count = await discoveryService.refreshDiscovery();
      logger.i("Refreshed discovery: processed $count groups");
    } catch (e) {
      logger.e("Error refreshing discovery: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _broadcastAllGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      logger.i("Manual broadcast triggered - broadcasting all known groups");

      // Get current known groups count
      int knownGroupsCount = discoveryService.knownGroups.length;
      logger.i("Known groups count: $knownGroupsCount");

      if (knownGroupsCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No known groups to broadcast. Join some groups first!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      await discoveryService.broadcastAllKnownGroups();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully broadcasted $knownGroupsCount groups!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.e("Error broadcasting all groups: $e");

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to broadcast groups: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup(PublicGroupInfo group) async {
    try {
      TopicSchema? topic =
          await topicCommon.subscribe(group.topicId, fetchSubscribers: true);
      if (topic != null) {
        ChatMessagesScreen.go(context, topic);
      }
    } catch (e) {
      logger.e("Error joining group ${group.topicId}: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join group: ${group.name}')),
      );
    }
  }

  List<PublicGroupInfo> get _filteredGroups {
    List<PublicGroupInfo> groups =
        _isSearching ? _searchResults : _discoveredGroups;

    if (_selectedCategory != null && _selectedCategory != 'all') {
      groups = groups
          .where((g) =>
              g.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .toList();
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Public Groups',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: application.theme.backgroundColor,
        foregroundColor: application.theme.fontColor1,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: application.theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.broadcast_on_personal,
                color: application.theme.primaryColor,
                size: 20,
              ),
              onPressed: _broadcastAllGroups,
              tooltip: 'Broadcast All Known Groups',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.add,
                color: Color(0xFF34C759),
                size: 20,
              ),
              onPressed: _showCreateGroupDialog,
              tooltip: 'Create Public Group',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: application.theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            application.theme.primaryColor),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: application.theme.primaryColor,
                      size: 20,
                    ),
              onPressed: _refreshDiscovery,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDiscovery,
        color: application.theme.primaryColor,
        backgroundColor: application.theme.backgroundColor,
        displacement: 40,
        edgeOffset: 20,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(
              child: StreamBuilder<List<PublicGroupInfo>>(
                stream: discoveryService.groupsStream,
                initialData: discoveryService.knownGroups,
                builder: (context, snapshot) {
                  // Check connection state and data availability
                  final isWaiting =
                      snapshot.connectionState == ConnectionState.waiting;
                  final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
                  final hasError = snapshot.hasError;

                  // Show loading only if waiting AND no data yet
                  if (isWaiting && !hasData && _isLoading) {
                    return _buildLoadingState();
                  }

                  // Show error if stream has error
                  if (hasError) {
                    logger.e("Discovery stream error: ${snapshot.error}");
                    return _buildEmptyState(
                        'Error loading groups. Please pull to refresh.');
                  }

                  // Use data from stream or fallback to _discoveredGroups
                  if (hasData) {
                    _discoveredGroups = snapshot.data!;
                  }

                  final groups = _filteredGroups;

                  if (groups.isEmpty) {
                    if (_isLoading) {
                      return _buildLoadingState();
                    }
                    return _buildEmptyState(
                        'No public groups discovered yet.\nPull to refresh or check back later.');
                  }

                  return _buildGroupsList(groups);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: application.theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showCreateGroupDialog,
          icon: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
          label: Text(
            'Create Group',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          backgroundColor: application.theme.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomNavigationBar: ChatBottomMenu(
        target: PublicGroupDiscoveryService.DISCOVERY_TOPIC,
        show: true, // Always visible
        onPicked: (List<Map<String, dynamic>> results) async {
          if (mounted) FocusScope.of(context).requestFocus(FocusNode());
          if (results.isEmpty) return;
          // Show toast since media sharing in discovery is informational
          Toast.show('Media selected: ${results.length} items');
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search public groups...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          filled: true,
          fillColor: application.theme.backgroundColor2,
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: CATEGORIES.length,
        itemBuilder: (context, index) {
          final category = CATEGORIES[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category['icon']!, style: TextStyle(fontSize: 16)),
                  SizedBox(width: 4),
                  Text(category['name']!),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category['id'] : null;
                });
              },
              backgroundColor: application.theme.backgroundColor2,
              selectedColor:
                  application.theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: application.theme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading public groups...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 64,
            color: application.theme.fontColor3,
          ),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: application.theme.fontColor3),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _refreshDiscovery,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _broadcastAllGroups,
                  icon: Icon(Icons.broadcast_on_personal),
                  label: Text('Broadcast All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(List<PublicGroupInfo> groups) {
    return Column(
      children: [
        // Broadcast button at the top of the list
        if (groups.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _broadcastAllGroups,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.broadcast_on_personal),
                    label: Text(_isLoading
                        ? 'Broadcasting...'
                        : 'Broadcast All Groups'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _refreshDiscovery,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        // Groups list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshDiscovery,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return _buildGroupTile(groups[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTile(PublicGroupInfo group) {
    logger.d(
        "DiscoveryScreen - Building group tile: ${group.topicId} - avatarPath: ${group.avatarPath}");

    return Dismissible(
      key: Key(group.topicId),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.ellipsis,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        _showGroupActionsModal(group);
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: _DiscoveryGroupAvatar(group: group),
          title: Text(
            group.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.description.isNotEmpty)
                Text(
                  group.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${group.subscriberCount} members',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      group.category,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Button(
            text: 'Join',
            width: 80,
            height: 32,
            onPressed: () => _joinGroup(group),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  void _showGroupActionsModal(PublicGroupInfo group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: application.theme.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: application.theme.fontColor4.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header with group info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    // Group avatar
                    _DiscoveryGroupAvatar(group: group, radius: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: application.theme.fontColor1,
                            ),
                          ),
                          if (group.description.isNotEmpty)
                            Text(
                              group.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: application.theme.fontColor3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.xmark,
                        color: application.theme.fontColor3,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Action options
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Enter Group
                    _buildActionOption(
                      icon: CupertinoIcons.pen,
                      title: 'Enter Group',
                      subtitle: 'Join and start chatting',
                      color: Color(0xFF007AFF),
                      onTap: () {
                        Navigator.of(context).pop();
                        _joinGroup(group);
                      },
                    ),

                    SizedBox(height: 12),

                    // Broadcast Group
                    _buildActionOption(
                      icon: CupertinoIcons.globe,
                      title: 'Broadcast Group',
                      subtitle: 'Share with discovery network',
                      color: Color(0xFF34C759),
                      onTap: () {
                        Navigator.of(context).pop();
                        _broadcastGroup(group);
                      },
                    ),

                    SizedBox(height: 12),

                    // Delete Group
                    _buildActionOption(
                      icon: CupertinoIcons.trash,
                      title: 'Delete Group',
                      subtitle: 'Remove from local database',
                      color: Color(0xFFFF3B30),
                      onTap: () {
                        Navigator.of(context).pop();
                        _deleteGroup(group);
                      },
                    ),
                  ],
                ),
              ),

              // Bottom padding
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: application.theme.fontColor1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: application.theme.fontColor3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: application.theme.fontColor4,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    BottomDialog.of(context).show(
      builder: (context) => ChatTopicSearchLayout(),
    );
  }

  void _broadcastGroup(PublicGroupInfo group) async {
    try {
      logger.i("Broadcasting group: ${group.topicId}");
      TopicSchema topic = TopicSchema(
        topicId: group.topicId,
        type: TopicType.public,
      );
      topic.data.addAll(group.metadata);

      await discoveryService.announceGroup(
        topic,
        description: group.description,
        category: group.category,
        avatarPath: group.avatarPath,
      );
      Toast.show("Group broadcasted successfully");
    } catch (e) {
      logger.e("Error broadcasting group: $e");
      Toast.show("Failed to broadcast group");
    }
  }

  void _deleteGroup(PublicGroupInfo group) async {
    try {
      logger.i("Deleting group from local database: ${group.topicId}");
      // Remove from the discovery service's known groups
      await discoveryService.clearCache();
      Toast.show("Group removed from local database");
    } catch (e) {
      logger.e("Error deleting group: $e");
      Toast.show("Failed to delete group");
    }
  }
}

class _DiscoveryGroupAvatar extends StatefulWidget {
  final PublicGroupInfo group;
  final double radius;

  const _DiscoveryGroupAvatar({
    required this.group,
    this.radius = 20,
  });

  @override
  State<_DiscoveryGroupAvatar> createState() => _DiscoveryGroupAvatarState();
}

class _DiscoveryGroupAvatarState extends State<_DiscoveryGroupAvatar> {
  String? _avatarPath;
  Uint8List? _avatarBytes;
  bool _fileError = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(covariant _DiscoveryGroupAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.topicId != widget.group.topicId ||
        oldWidget.group.avatarPath != widget.group.avatarPath) {
      _fileError = false;
      _avatarPath = null;
      _avatarBytes = null;
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    String? resolvedPath = widget.group.avatarPath;
    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      final file = File(resolvedPath);
      if (await file.exists()) {
        if (!mounted) return;
        setState(() {
          _avatarPath = resolvedPath;
          _avatarBytes = null;
        });
        return;
      }
    }

    final cached =
        await PublicGroupStorage.instance.query(widget.group.topicId);
    final cachedPath = cached?.info.avatarPath;
    if (cachedPath != null && cachedPath.isNotEmpty) {
      final file = File(cachedPath);
      if (await file.exists()) {
        if (!mounted) return;
        setState(() {
          _avatarPath = cachedPath;
          _avatarBytes = null;
        });
        return;
      }
    }

    final b64 = cached?.avatarBase64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        if (!mounted) return;
        setState(() {
          _avatarPath = null;
          _avatarBytes = bytes;
        });
        return;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _avatarPath = null;
      _avatarBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        widget.group.name.isNotEmpty ? widget.group.name : widget.group.topicId;

    if (!_fileError && _avatarPath != null && _avatarPath!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: application.theme.primaryColor.withValues(alpha: 0.1),
        backgroundImage: FileImage(File(_avatarPath!)),
        onBackgroundImageError: (Object exception, StackTrace? stackTrace) {
          if (!_fileError) {
            setState(() {
              _fileError = true;
              _avatarPath = null;
            });
            _loadAvatar();
          }
        },
      );
    }

    if (!_fileError && _avatarBytes != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: application.theme.primaryColor.withValues(alpha: 0.1),
        backgroundImage: MemoryImage(_avatarBytes!),
        onBackgroundImageError: (Object exception, StackTrace? stackTrace) {
          if (!_fileError) {
            setState(() {
              _fileError = true;
              _avatarBytes = null;
            });
          }
        },
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: application.theme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '#',
        style: TextStyle(
          color: application.theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: widget.radius >= 20 ? 16 : null,
        ),
      ),
    );
  }
}
