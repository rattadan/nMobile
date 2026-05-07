import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/button/button.dart';
import 'package:nchat_mobile/components/dialog/loading.dart';
import 'package:nchat_mobile/components/text/form_text.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/components/tip/toast.dart';
import 'package:nchat_mobile/helpers/file.dart';
import 'package:nchat_mobile/helpers/media_picker.dart';
import 'package:nchat_mobile/helpers/validation.dart';
import 'package:nchat_mobile/schema/popular_channel.dart';
import 'package:nchat_mobile/schema/topic.dart';
import 'package:nchat_mobile/schema/wallet.dart';
import 'package:nchat_mobile/screens/chat/messages.dart';
import 'package:nchat_mobile/storages/topic.dart';
import 'package:nchat_mobile/theme/theme.dart';
import 'package:nchat_mobile/utils/asset.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';
import 'package:nchat_mobile/common/discovery/public_group_storage.dart';
import 'package:nchat_mobile/common/discovery/public_group_discovery.dart';
import 'dart:convert';
import 'dart:io';

class ChatTopicSearchLayout extends BaseStateFulWidget {
  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState
    extends BaseStateFulWidgetState<ChatTopicSearchLayout> with Tag {
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool _formValid = false;

  TextEditingController _topicController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  // Group avatar image
  File? _selectedGroupAvatar;

  // Category selection
  String _selectedCategory = 'General';

  // Available categories
  static const List<Map<String, String>> CATEGORIES = [
    {'id': 'General', 'name': ' General', 'emoji': '💬'},
    {'id': 'Technology', 'name': ' Technology', 'emoji': '💻'},
    {'id': 'Gaming', 'name': ' Gaming', 'emoji': '🎮'},
    {'id': 'Music', 'name': ' Music', 'emoji': '🎵'},
    {'id': 'Art', 'name': ' Art', 'emoji': '🎨'},
    {'id': 'Sports', 'name': ' Sports', 'emoji': '⚽'},
    {'id': 'Education', 'name': ' Education', 'emoji': '📚'},
    {'id': 'Business', 'name': ' Business', 'emoji': '💼'},
    {'id': 'Health', 'name': ' Health', 'emoji': '🏥'},
    {'id': 'Food', 'name': ' Food', 'emoji': '🍔'},
    {'id': 'Travel', 'name': ' Travel', 'emoji': '✈️'},
    {'id': 'Crypto', 'name': ' Crypto', 'emoji': '₿'},
  ];

  @override
  void onRefreshArguments() {}

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectGroupAvatar() async {
    try {
      WalletSchema? wallet;
      for (int i = 0; i < 3; i++) {
        wallet = await walletCommon.getDefault();
        if (wallet != null) break;
        if (i < 2) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      if (wallet == null) {
        Toast.show('Please wait a moment and try again');
        return;
      }

      String groupAvatarPath = await Path.getRandomFile(
          clientCommon.getPublicKey(), DirType.profile,
          subPath: 'groups/temp', fileExt: FileHelper.DEFAULT_IMAGE_EXT);
      String? groupAvatarLocalPath = Path.convert2Local(groupAvatarPath);
      if (groupAvatarPath.isEmpty ||
          groupAvatarLocalPath == null ||
          groupAvatarLocalPath.isEmpty) {
        Toast.show('Failed to prepare image storage');
        return;
      }

      application.inSystemSelecting = true;

      File? picked = await MediaPicker.pickImage(
        cropRectangle: false, // circle crop
        maxSize: Settings.sizeAvatarMax,
        bestSize: Settings.sizeAvatarBest,
        savePath: groupAvatarPath,
      );

      application.inSystemSelecting = false;

      if (picked == null) {
        return;
      }

      setState(() {
        _selectedGroupAvatar = picked;
      });

      Toast.show('Group photo selected!');
    } catch (e) {
      logger.e("Error selecting group avatar: $e");
      Toast.show('Failed to select photo');
    }
  }

  Future<bool> createOrJoinTopic(String? topicName) async {
    if (topicName == null || topicName.isEmpty) return false;
    if (Navigator.of(this.context).canPop()) Navigator.pop(this.context);

    double? fee = await topicCommon.getTopicSubscribeFee(Settings.appContext);
    if (fee == null) return false;
    Loading.show();

    TopicSchema? _topic = await topicCommon.subscribe(topicName,
        fetchSubscribers: true, fee: fee);

    if (_topic == null) {
      Loading.dismiss();
      return false;
    }

    // Store metadata for public groups
    if (!_topic.isPrivate) {
      _topic.data['description'] = _descriptionController.text.trim();
      _topic.data['category'] = _selectedCategory;
      _topic.data['tags'] = [];

      // Save group avatar if selected
      if (_selectedGroupAvatar != null) {
        try {
          final String avatarCompletePath = _selectedGroupAvatar!.path;
          final String? avatarLocalPath =
              Path.convert2Local(avatarCompletePath);
          logger.i(
              "ChatTopicSearch - Selected avatar path: $avatarCompletePath, localPath: $avatarLocalPath");
          if (avatarLocalPath != null) {
            // Set avatar on topic schema (this is what displayAvatarPath uses)
            _topic.avatar = _selectedGroupAvatar;

            // Also save to data for persistence
            WalletSchema? wallet = await walletCommon.getDefault();
            if (wallet != null) {
              await contactCommon.setSelfAvatar(wallet.address, avatarLocalPath,
                  notify: false);
              _topic.data['groupAvatar'] = avatarLocalPath;
              logger.i(
                  "Group avatar saved to topic.avatar and data: $avatarLocalPath");

              // Persist into discovery.db so lists/broadcasts can reuse without re-encoding
              try {
                final bytes = await _selectedGroupAvatar!.readAsBytes();
                final b64 = base64Encode(bytes);
                await PublicGroupStorage.instance.upsertGroup(
                  PublicGroupInfo(
                    topicId: _topic.topicId,
                    name: _topic.data['name'] ?? _topic.topicId,
                    description: _topic.data['description'] ?? '',
                    category: _topic.data['category'] ?? 'general',
                    subscriberCount: _topic.count,
                    avatarPath: avatarCompletePath,
                    avatar: null,
                    metadata: _topic.data,
                  ),
                  avatarBase64: b64,
                );
                logger.i(
                    "ChatTopicSearch - Saved group avatar to discovery.db: ${_topic.topicId} (base64: ${b64.length} chars)");
              } catch (e) {
                logger.w(
                    "ChatTopicSearch - Failed to persist avatar to discovery.db: $e");
              }
            } else {
              logger.w("ChatTopicSearch - Wallet is null, cannot save avatar");
            }
          } else {
            logger.w("ChatTopicSearch - avatarLocalPath is null");
          }
        } catch (e) {
          logger.e("Error saving group avatar: $e");
        }
      } else {
        logger.w(
            "ChatTopicSearch - _selectedGroupAvatar is NULL, no avatar to save");
      }

      await TopicStorage.instance.setData(_topic.topicId, _topic.data);
      logger.i(
          "ChatTopicSearch - Topic data saved, groupAvatar: ${_topic.data['groupAvatar']}, topic.avatar: ${_topic.avatar?.path}");

      // Announce the new public group
      String? description = _topic.data['description'] as String?;
      String? category = _topic.data['category'] as String?;
      String? avatarPath = _topic.data['groupAvatar'] as String?;

      logger.i("ChatTopicSearch - Announcing group: ${_topic.topicId}");
      logger.i(
          "ChatTopicSearch - description: $description, category: $category, avatarPath: $avatarPath");
      logger.i(
          "ChatTopicSearch - _selectedGroupAvatar: ${_selectedGroupAvatar != null ? 'exists' : 'null'}");
      logger.i(
          "ChatTopicSearch - topic.avatar: ${_topic.avatar != null ? 'exists' : 'null'}");

      // Get avatar file - try multiple approaches
      File? avatarFile;

      // First priority: use topic.avatar (the correct field)
      if (_topic.avatar != null && await _topic.avatar!.exists()) {
        avatarFile = _topic.avatar;
        logger.i(
            "ChatTopicSearch - Using topic.avatar file: ${avatarFile!.path}");
      }
      // Second priority: use the originally picked file if it exists
      else if (_selectedGroupAvatar != null &&
          await _selectedGroupAvatar!.exists()) {
        avatarFile = _selectedGroupAvatar;
        logger.i(
            "ChatTopicSearch - Using originally picked avatar file: ${avatarFile!.path}");
      }
      // Third priority: try to get from saved path
      else if (avatarPath != null && avatarPath.isNotEmpty) {
        String? completePath = Path.convert2Complete(avatarPath);
        logger.i(
            "ChatTopicSearch - Trying saved avatarPath: $avatarPath -> completePath: $completePath");
        if (completePath != null && completePath.isNotEmpty) {
          avatarFile = File(completePath);
          bool exists = await avatarFile.exists();
          logger.i(
              "ChatTopicSearch - Saved avatarFile exists: $exists, path: ${avatarFile.path}");
          if (!exists) {
            avatarFile = null;
            logger.w(
                "ChatTopicSearch - Avatar file does not exist at path: $completePath");
          }
        } else {
          logger.w(
              "ChatTopicSearch - Could not convert avatar path to complete path: $avatarPath");
        }
      }

      if (avatarFile == null) {
        logger.w("ChatTopicSearch - No avatar file available for broadcast");
      } else {
        logger.i(
            "ChatTopicSearch - Avatar file ready for broadcast: ${avatarFile.path}");
      }

      await topicCommon.discoveryService.announceGroup(
        _topic,
        description: description,
        category: category,
        avatarPath: avatarPath,
        avatarFile: avatarFile,
      );
    }

    Loading.dismiss();
    ChatMessagesScreen.go(Settings.appContext, _topic);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    SkinTheme _theme = application.theme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: () {
        _formValid = (_formKey.currentState as FormState).validate();
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Name field
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(width: 20),
                Label(
                  Settings.locale((s) => s.name),
                  type: LabelType.bodyRegular,
                  color: _theme.fontColor1,
                  textAlign: TextAlign.start,
                ),
                Spacer(),
                SizedBox(width: 20),
              ],
            ),
            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: FormText(
                controller: _topicController,
                hintText: Settings.locale((s) => s.input_name),
                validator: Validator.of(context).required(),
              ),
            ),
            SizedBox(height: 16),

            // Description field
            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: FormText(
                controller: _descriptionController,
                hintText: 'Enter group description (optional)',
                maxLines: 3,
                minLines: 1,
              ),
            ),
            SizedBox(height: 16),

            // Category selector
            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    'Category',
                    type: LabelType.bodyRegular,
                    color: application.theme.fontColor1,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: application.theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: application.theme.backgroundColor2,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: application.theme.fontColor1),
                        items: CATEGORIES.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'],
                            child: Row(
                              children: [
                                Text(
                                  category['emoji']!,
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  category['name']!,
                                  style: TextStyle(
                                    color: application.theme.fontColor1,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Group avatar picker
            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _selectGroupAvatar,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: application.theme.backgroundLightColor,
                        border: Border.all(
                          color: application.theme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: _selectedGroupAvatar != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedGroupAvatar!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: application.theme.fontColor2,
                            ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _selectGroupAvatar,
                    child: Label(
                      "Add Group Photo (optional)",
                      type: LabelType.bodySmall,
                      color: application.theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Popular channels label
            Padding(
              padding: EdgeInsets.only(left: 16, top: 16),
              child: Label(
                Settings.locale((s) => s.popular_channels),
                type: LabelType.h4,
                textAlign: TextAlign.start,
              ),
            ),
            SizedBox(height: 10),

            // Popular channels list (fixed height)
            SizedBox(
              height: 200,
              child: _getPopularListView(),
            ),
            SizedBox(height: 10),

            // Continue button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 18, bottom: 18),
                child: Button(
                  width: double.infinity,
                  text: Settings.locale((s) => s.continue_text),
                  onPressed: () {
                    if (_formValid) createOrJoinTopic(_topicController.text);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPopularListView() {
    double itemHeight = 40;
    List<Widget> list = [];

    for (PopularChannel item in PopularChannel.defaultData()) {
      list.add(InkWell(
        onTap: () {
          createOrJoinTopic(item.topic);
        },
        child: Container(
          width: double.infinity,
          height: itemHeight,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: itemHeight,
                width: itemHeight,
                decoration: BoxDecoration(
                  color: item.titleBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Label(
                    item.title,
                    type: LabelType.h4,
                    color: item.titleColor,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Label(
                      item.topic,
                      type: LabelType.bodyRegular,
                      color: application.theme.fontColor1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Label(
                      item.desc,
                      height: 1,
                      type: LabelType.bodySmall,
                    ),
                  ],
                ),
              ),
              Asset.svg(
                'icons/chat',
                width: 24,
                color: application.theme.primaryColor,
              ),
            ],
          ),
        ),
      ));
    }
    return SingleChildScrollView(
      child: Column(
        children: list,
      ),
    );
  }
}
