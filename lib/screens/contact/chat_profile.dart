import 'package:nchat_mobile/common/settings.dart';
import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/components/contact/avatar.dart';
import 'package:nchat_mobile/components/layout/header.dart';
import 'package:nchat_mobile/components/layout/horizontal_action_slideout.dart';
import 'package:nchat_mobile/components/layout/layout.dart';
import 'package:nchat_mobile/components/layout/nav.dart';
import 'package:nchat_mobile/components/layout/slideout_controller_provider.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/schema/contact.dart';
import 'package:nchat_mobile/utils/util.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ContactChatProfileScreen extends BaseStateFulWidget {
  static final String routeName = "/contact/chat_profile";
  static final String argContactSchema = "contact_schema";

  static Future go(BuildContext? context, ContactSchema schema) {
    if (context == null) return Future.value(null);
    return Navigator.pushNamed(context, routeName, arguments: {
      argContactSchema: schema,
    });
  }

  final Map<String, dynamic>? arguments;

  ContactChatProfileScreen({Key? key, this.arguments}) : super(key: key);

  @override
  ContactChatProfileScreenState createState() => new ContactChatProfileScreenState();
}

class ContactChatProfileScreenState extends BaseStateFulWidgetState<ContactChatProfileScreen>
    with SlideoutControllerMixin {
  late ContactSchema _contact;
  
  // Slideout state
  bool _isSlideoutVisible = false;
  List<SlideoutActionItem> _actions = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize slideout actions
    _initializeActions();
    
    // Set initial slideout content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        updateSlideoutContent(_buildSlideout());
      }
    });
  }
  
  void _initializeActions() {
    _actions = [
      SlideoutActionItem(
        label: 'Copy Address',
        icon: Icons.content_copy,
        color: Colors.blue,
        onTap: () {
          Util.copyText(_contact.address);
        },
      ),
      SlideoutActionItem(
        label: 'Share QR',
        icon: Icons.share,
        color: Colors.green,
        onTap: () {
          // TODO: Implement share QR
          Util.copyText(_contact.address);
        },
      ),
      SlideoutActionItem(
        label: 'Chat',
        icon: Icons.chat,
        color: Colors.purple,
        onTap: () {
          // Navigate back to chat
          Navigator.pop(context);
        },
      ),
    ];
  }
  
  @override
  void dispose() {
    updateSlideoutContent(SizedBox.shrink());
    super.dispose();
  }

  @override
  void onRefreshArguments() {
    _contact = widget.arguments?[ContactChatProfileScreen.argContactSchema];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content with padding for bottom nav
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 56, // Height of bottom nav bar
            child: Layout(
              headerColor: application.theme.backgroundColor4,
              header: Header(
                title: Settings.locale((s) => s.d_chat_address, ctx: context),
                backgroundColor: application.theme.backgroundColor4,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 30, bottom: 30, left: 20, right: 20),
                child: Column(
                  children: <Widget>[
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.resolveWith((states) => EdgeInsets.all(16)),
                        backgroundColor: WidgetStateProperty.resolveWith((states) => application.theme.backgroundLightColor),
                        shape: WidgetStateProperty.resolveWith(
                          (states) => RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      onPressed: () {
                        Util.copyText(this._contact.address);
                      },
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Label(
                                Settings.locale((s) => s.d_chat_address, ctx: context),
                                type: LabelType.bodyRegular,
                                color: application.theme.fontColor1,
                              ),
                              Icon(
                                Icons.content_copy,
                                color: application.theme.fontColor2,
                                size: 18,
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          Label(
                            this._contact.address,
                            type: LabelType.bodyRegular,
                            color: application.theme.fontColor2,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.only(left: 16, right: 16, top: 30, bottom: 30),
                      child: Column(
                        children: <Widget>[
                          ContactAvatar(
                            contact: this._contact,
                            radius: 24,
                          ),
                          SizedBox(height: 20),
                          this._contact.address.isNotEmpty
                              ? Center(
                                  child: QrImageView(
                                    data: this._contact.address,
                                    backgroundColor: application.theme.backgroundLightColor,
                                    foregroundColor: application.theme.primaryColor,
                                    version: QrVersions.auto,
                                    size: 240.0,
                                  ),
                                )
                              : SizedBox.shrink(),
                          SizedBox(height: 20),
                          Label(
                            Settings.locale((s) => s.scan_show_me_desc, ctx: context),
                            type: LabelType.bodyRegular,
                            color: application.theme.fontColor2,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            softWrap: true,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PhysicalModel(
              color: Theme.of(context).scaffoldBackgroundColor,
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              child: Nav(
                currentIndex: 0, // Always show chat tab as active
                screens: [],
                controller: PageController(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the horizontal slideout widget
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
}
