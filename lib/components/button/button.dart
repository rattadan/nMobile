import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';

class Button extends StatelessWidget {
  final Widget? child;
  final String? text;
  final double? fontSize;
  final Color? fontColor;
  final FontWeight? fontWeight;
  final bool outline;
  final bool disabled;
  final VoidCallback? onPressed;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;

  Button({
    this.child,
    this.text,
    this.fontSize,
    this.fontColor,
    this.fontWeight,
    this.onPressed,
    this.outline = false,
    this.disabled = false,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (this.width == null && this.height == null) {
      return _getButton();
    }
    return SizedBox(
      width: this.width,
      height: this.height,
      child: _getButton(),
    );
  }

  Widget _getButton() {
    Widget child = this.child != null
        ? this.child!
        : Text(
            this.text ?? "",
            style: TextStyle(
              fontSize: this.fontSize ?? application.theme.buttonFontSize,
              color: this.disabled
                  ? application.theme.fontColor2
                  : (this.fontColor ?? application.theme.fontLightColor),
              fontWeight: this.fontWeight ?? FontWeight.w600,
            ),
          );

    var btnStyle = ButtonStyle(
      padding: WidgetStateProperty.resolveWith((states) =>
          this.padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      shape: WidgetStateProperty.resolveWith((states) => RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          )),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (this.disabled) {
          return application.theme.backgroundColor2;
        }
        if (states.contains(WidgetState.pressed)) {
          return this.backgroundColor != null
              ? (this.backgroundColor!.withValues(alpha: 0.8))
              : application.theme.primaryColor.withValues(alpha: 0.8);
        }
        if (states.contains(WidgetState.hovered)) {
          return this.backgroundColor != null
              ? (this.backgroundColor!.withValues(alpha: 0.9))
              : application.theme.primaryColor.withValues(alpha: 0.9);
        }
        return this.backgroundColor ??
            (this.outline ? null : application.theme.primaryColor);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.1);
        }
        return null;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return 2;
        }
        if (states.contains(WidgetState.hovered)) {
          return 4;
        }
        return this.outline ? 0 : 2;
      }),
      shadowColor: WidgetStateProperty.resolveWith((states) {
        return this.backgroundColor != null
            ? this.backgroundColor!.withValues(alpha: 0.3)
            : application.theme.primaryColor.withValues(alpha: 0.3);
      }),
    );

    if (this.borderColor != null) {
      Color color = this.disabled
          ? application.theme.backgroundColor2
          : this.borderColor!;
      btnStyle = btnStyle.copyWith(
          side: WidgetStateProperty.resolveWith(
              (state) => BorderSide(color: color)));
    }

    return this.outline
        ? OutlinedButton(
            child: child,
            onPressed: this.disabled ? null : this.onPressed,
            style: btnStyle,
          )
        : TextButton(
            child: child,
            onPressed: this.disabled ? null : this.onPressed,
            style: btnStyle,
          );
  }
}
