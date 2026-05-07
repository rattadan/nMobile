import 'package:flutter/material.dart';
import 'package:nchat_mobile/components/contact/avatar.dart';
import 'package:nchat_mobile/components/text/label.dart';
import 'package:nchat_mobile/schema/contact.dart';

class ContactHeader extends StatelessWidget {
  final ContactSchema contact;
  final Widget body;
  final double avatarRadius;
  final bool dark;
  final GestureTapCallback? onTap;

  ContactHeader({
    required this.contact,
    required this.body,
    this.avatarRadius = 24,
    this.dark = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String name = this.contact.displayName;
    return GestureDetector(
      onTap: () {
        if (this.onTap != null) this.onTap!();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ContactAvatar(
              contact: this.contact,
              radius: this.avatarRadius,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Label(
                  name,
                  type: LabelType.h3,
                  dark: this.dark,
                ),
                this.body,
              ],
            ),
          )
        ],
      ),
    );
  }
}
