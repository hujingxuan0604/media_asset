import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MediaAssetLibraryConfig {
  final MediaAssetFileTypeConfig fileTypes;
  final ImagePreviewShortcuts imageShortcuts;
  final VideoPreviewShortcuts videoShortcuts;
  final bool enableDragDrop;
  final bool enableMultiSelection;
  final bool enablePreviewNavigation;
  final bool enableContextMenu;
  final bool showToolbar;
  final Duration previewAnimationDuration;
  final double tileWidth;
  final double tilePreviewHeight;
  final double gridSpacing;
  final String emptyTitle;
  final String emptyDescription;
  final String dropActiveTitle;

  const MediaAssetLibraryConfig({
    this.fileTypes = const MediaAssetFileTypeConfig(),
    this.imageShortcuts = const ImagePreviewShortcuts(),
    this.videoShortcuts = const VideoPreviewShortcuts(),
    this.enableDragDrop = true,
    this.enableMultiSelection = true,
    this.enablePreviewNavigation = true,
    this.enableContextMenu = true,
    this.showToolbar = true,
    this.previewAnimationDuration = const Duration(milliseconds: 150),
    this.tileWidth = 112,
    this.tilePreviewHeight = 78,
    this.gridSpacing = 12,
    this.emptyTitle = '拖入图片或视频',
    this.emptyDescription = '支持图片和视频素材。导入后的文件处理由接入方完成。',
    this.dropActiveTitle = '释放以导入素材',
  });
}

class MediaAssetFileTypeConfig {
  final Set<String> imageExtensions;
  final Set<String> videoExtensions;
  final int? maxImageFileSize;
  final int? maxVideoFileSize;

  const MediaAssetFileTypeConfig({
    this.imageExtensions = const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'},
    this.videoExtensions = const {'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'},
    this.maxImageFileSize,
    this.maxVideoFileSize,
  });
}

class ImagePreviewShortcuts {
  final List<LogicalKeyboardKey> previousKeys;
  final List<LogicalKeyboardKey> nextKeys;
  final List<LogicalKeyboardKey> zoomInKeys;
  final List<LogicalKeyboardKey> zoomOutKeys;
  final List<LogicalKeyboardKey> resetZoomKeys;
  final List<LogicalKeyboardKey> closeKeys;

  const ImagePreviewShortcuts({
    this.previousKeys = const [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.pageUp,
    ],
    this.nextKeys = const [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.pageDown,
    ],
    this.zoomInKeys = const [LogicalKeyboardKey.equal, LogicalKeyboardKey.add],
    this.zoomOutKeys = const [
      LogicalKeyboardKey.minus,
      LogicalKeyboardKey.numpadSubtract,
    ],
    this.resetZoomKeys = const [LogicalKeyboardKey.digit0],
    this.closeKeys = const [LogicalKeyboardKey.escape],
  });
}

class VideoPreviewShortcuts {
  final List<LogicalKeyboardKey> previousKeys;
  final List<LogicalKeyboardKey> nextKeys;
  final List<LogicalKeyboardKey> playPauseKeys;
  final List<LogicalKeyboardKey> seekBackwardKeys;
  final List<LogicalKeyboardKey> seekForwardKeys;
  final List<LogicalKeyboardKey> closeKeys;
  final Duration seekStep;

  const VideoPreviewShortcuts({
    this.previousKeys = const [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.pageUp,
    ],
    this.nextKeys = const [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.pageDown,
    ],
    this.playPauseKeys = const [LogicalKeyboardKey.space],
    this.seekBackwardKeys = const [LogicalKeyboardKey.keyJ],
    this.seekForwardKeys = const [LogicalKeyboardKey.keyL],
    this.closeKeys = const [LogicalKeyboardKey.escape],
    this.seekStep = const Duration(seconds: 5),
  });
}

class MediaAssetLibraryScope extends InheritedWidget {
  final MediaAssetLibraryConfig config;

  const MediaAssetLibraryScope({
    super.key,
    required this.config,
    required super.child,
  });

  static MediaAssetLibraryConfig of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MediaAssetLibraryScope>();
    return scope?.config ?? const MediaAssetLibraryConfig();
  }

  @override
  bool updateShouldNotify(MediaAssetLibraryScope oldWidget) {
    return oldWidget.config != config;
  }
}
