import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/media_asset_models.dart';

enum MediaAssetSortMode {
  manual,
  createdAtDesc,
  createdAtAsc,
  nameAsc,
  nameDesc,
  fileSizeDesc,
  fileSizeAsc,
  typeAsc,
}

enum MediaAssetDensity { compact, comfortable, spacious }

class MediaAssetLibraryConfig {
  final MediaAssetImportConfig importConfig;
  final MediaAssetInteractionConfig interaction;
  final MediaAssetLayoutConfig layout;
  final MediaAssetPreviewConfig preview;
  final MediaAssetTextConfig text;

  const MediaAssetLibraryConfig({
    this.importConfig = const MediaAssetImportConfig(),
    this.interaction = const MediaAssetInteractionConfig(),
    this.layout = const MediaAssetLayoutConfig(),
    this.preview = const MediaAssetPreviewConfig(),
    this.text = const MediaAssetTextConfig(),
  });
}

class MediaAssetImportConfig {
  final MediaAssetFileTypeConfig fileTypes;
  final bool preventDuplicateImport;

  const MediaAssetImportConfig({
    this.fileTypes = const MediaAssetFileTypeConfig(),
    this.preventDuplicateImport = true,
  });
}

class MediaAssetInteractionConfig {
  final bool enableDragDrop;
  final bool enableMultiSelection;
  final bool enableAssetDragging;
  final bool enableContextMenu;
  final Set<MediaAssetAction> enabledActions;

  const MediaAssetInteractionConfig({
    this.enableDragDrop = true,
    this.enableMultiSelection = true,
    this.enableAssetDragging = true,
    this.enableContextMenu = true,
    this.enabledActions = const {
      MediaAssetAction.preview,
      MediaAssetAction.select,
      MediaAssetAction.delete,
      MediaAssetAction.revealInFolder,
      MediaAssetAction.copyPath,
    },
  });

  bool isActionEnabled(MediaAssetAction action) {
    return enabledActions.contains(action);
  }
}

class MediaAssetLayoutConfig {
  final bool showToolbar;
  final double? height;
  final bool shrinkWrap;
  final MediaAssetDensity density;
  final Size thumbnailSize;
  final MediaAssetSortMode sortMode;
  final Comparator<MediaAsset>? sortComparator;

  const MediaAssetLayoutConfig({
    this.showToolbar = true,
    this.height,
    this.shrinkWrap = false,
    this.density = MediaAssetDensity.comfortable,
    this.thumbnailSize = const Size(96, 78),
    this.sortMode = MediaAssetSortMode.createdAtDesc,
    this.sortComparator,
  });

  double get tileWidth => thumbnailSize.width + tilePadding.horizontal;

  double get tilePreviewHeight => thumbnailSize.height;

  EdgeInsets get tilePadding {
    switch (density) {
      case MediaAssetDensity.compact:
        return const EdgeInsets.all(6);
      case MediaAssetDensity.comfortable:
        return const EdgeInsets.all(8);
      case MediaAssetDensity.spacious:
        return const EdgeInsets.all(10);
    }
  }

  double get itemSpacing {
    switch (density) {
      case MediaAssetDensity.compact:
        return 8;
      case MediaAssetDensity.comfortable:
        return 12;
      case MediaAssetDensity.spacious:
        return 16;
    }
  }
}

class MediaAssetPreviewConfig {
  final ImagePreviewShortcuts imageShortcuts;
  final VideoPreviewShortcuts videoShortcuts;
  final bool enableNavigation;
  final Duration animationDuration;

  const MediaAssetPreviewConfig({
    this.imageShortcuts = const ImagePreviewShortcuts(),
    this.videoShortcuts = const VideoPreviewShortcuts(),
    this.enableNavigation = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });
}

class MediaAssetTextConfig {
  final String emptyTitle;
  final String emptyDescription;
  final String dropActiveTitle;
  final String importButtonLabel;
  final String previewActionLabel;
  final String selectActionLabel;
  final String cancelSelectActionLabel;
  final String revealInFolderActionLabel;
  final String copyPathActionLabel;
  final String deleteActionLabel;
  final String copySelectedPathsTooltip;
  final String deleteSelectedTooltip;
  final String selectAllTooltip;
  final String clearSelectionTooltip;
  final String deleteAssetTooltip;
  final String copyPathSuccessMessage;
  final String copySelectedPathsSuccessMessageTemplate;
  final String duplicateImportMessageTemplate;
  final String imageLoadFailureMessage;
  final String videoMissingMessage;
  final String videoLoadFailureMessage;
  final String zoomOutTooltip;
  final String zoomInTooltip;
  final String resetZoomTooltip;
  final String closePreviewTooltip;
  final String previousAssetTooltip;
  final String nextAssetTooltip;
  final String imagePreviewLabel;
  final String videoPreviewLabel;

  const MediaAssetTextConfig({
    this.emptyTitle = '拖入图片或视频',
    this.emptyDescription = '支持图片和视频素材。导入后的文件处理由接入方完成。',
    this.dropActiveTitle = '释放以导入素材',
    this.importButtonLabel = '导入素材',
    this.previewActionLabel = '预览',
    this.selectActionLabel = '选择',
    this.cancelSelectActionLabel = '取消选择',
    this.revealInFolderActionLabel = '在文件夹中显示',
    this.copyPathActionLabel = '复制路径',
    this.deleteActionLabel = '删除',
    this.copySelectedPathsTooltip = '复制所选路径',
    this.deleteSelectedTooltip = '删除所选',
    this.selectAllTooltip = '全选',
    this.clearSelectionTooltip = '清空选择',
    this.deleteAssetTooltip = '删除素材',
    this.copyPathSuccessMessage = '已复制文件路径',
    this.copySelectedPathsSuccessMessageTemplate = '已复制 {count} 个文件路径',
    this.duplicateImportMessageTemplate =
        '导入 {imported} 个文件，重复 {duplicate} 个文件',
    this.imageLoadFailureMessage = '图片加载失败',
    this.videoMissingMessage = '视频文件不存在，无法预览',
    this.videoLoadFailureMessage = '视频加载失败，请检查文件是否可用',
    this.zoomOutTooltip = '缩小',
    this.zoomInTooltip = '放大',
    this.resetZoomTooltip = '重置',
    this.closePreviewTooltip = '关闭',
    this.previousAssetTooltip = '上一个素材',
    this.nextAssetTooltip = '下一个素材',
    this.imagePreviewLabel = '图片预览',
    this.videoPreviewLabel = '视频预览',
  });

  String duplicateImportMessage({
    required int importedCount,
    required int duplicateCount,
  }) {
    return duplicateImportMessageTemplate
        .replaceAll('{imported}', importedCount.toString())
        .replaceAll('{duplicate}', duplicateCount.toString());
  }

  String copySelectedPathsSuccessMessage(int count) {
    return copySelectedPathsSuccessMessageTemplate.replaceAll(
      '{count}',
      count.toString(),
    );
  }
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
