import 'package:flutter/material.dart';

class MediaAssetThemeData {
  final Color? surfaceColor;
  final Color? elevatedSurfaceColor;
  final Color? primaryColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? mutedTextColor;
  final Color? dangerColor;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadow;

  const MediaAssetThemeData({
    this.surfaceColor,
    this.elevatedSurfaceColor,
    this.primaryColor,
    this.borderColor,
    this.textColor,
    this.mutedTextColor,
    this.dangerColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shadow = const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
    ],
  });

  Color surface(BuildContext context) {
    return surfaceColor ?? Theme.of(context).colorScheme.surface;
  }

  Color elevatedSurface(BuildContext context) {
    return elevatedSurfaceColor ??
        Theme.of(context).colorScheme.surfaceContainer;
  }

  Color primary(BuildContext context) {
    return primaryColor ?? Theme.of(context).colorScheme.primary;
  }

  Color border(BuildContext context) {
    return borderColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.7);
  }

  Color text(BuildContext context) {
    return textColor ?? Theme.of(context).colorScheme.onSurface;
  }

  Color mutedText(BuildContext context) {
    return mutedTextColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.64);
  }

  Color danger(BuildContext context) {
    return dangerColor ?? Theme.of(context).colorScheme.error;
  }
}

class MediaAssetTheme extends InheritedTheme {
  final MediaAssetThemeData data;

  const MediaAssetTheme({super.key, required this.data, required super.child});

  static MediaAssetThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<MediaAssetTheme>();
    return theme?.data ?? const MediaAssetThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MediaAssetTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MediaAssetTheme oldWidget) {
    return oldWidget.data != data;
  }
}
