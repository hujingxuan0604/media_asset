# 独立图片视频素材库 Package 方案

## 定位

重新实现一个完全独立的 Flutter package，用于管理和预览图片、视频素材。它不依赖当前项目中的任何模型、服务、颜色、布局或业务逻辑，可被任意 Flutter 项目通过 pub 或 path 依赖引用。

建议包名：

```yaml
name: media_asset
description: A configurable Flutter image and video asset library with grid, preview, drag-drop, and shortcuts.
```

第一版只支持：

- 图片素材
- 视频素材

暂不支持：

- 音频
- 文档
- 项目/片段/镜头等业务概念
- 业务存储格式
- AI 生成流程

## 设计原则

- 完全独立，不 import 使用方项目内的任何文件。
- package 只提供通用素材库能力。
- 数据、存储、导入、删除、下载由使用方接入。
- 支持全局配置，也支持组件级覆盖。
- 支持配置可用文件类型。
- 图片快捷键和视频快捷键分开配置。
- UI 默认可用，但提供主题和 builder 定制能力。
- 只支持桌面端，不支持移动端平台。
- 严格使用 MVC 分层，Model、View、Controller 职责分离。
- View 只负责渲染和转发用户事件，不直接处理素材校验、选择状态、预览状态和文件逻辑。

## 代码规范

实现时按照独立 package 的工程规范执行：

- 公开 API 必须通过 `lib/media_asset.dart` 导出。
- `src/` 内部文件可以互相引用，但 example 和外部项目只能引用 package 入口文件。
- 类名统一使用 `MediaAsset` 前缀，避免和调用方项目命名冲突。
- 配置类、模型类优先使用不可变对象，字段使用 `final`。
- View 层不直接读写文件，不直接处理业务数据持久化。
- Controller 层不 import 具体页面样式，不构建复杂 UI。
- Service 层只处理纯逻辑，例如扩展名识别、文件过滤、文件大小格式化。
- 回调命名统一使用 `onXxx`，状态输入统一通过构造参数传入。
- 不在库内使用调用方项目的 Toast、路由、主题、日志工具。
- 不在 View 中写大段条件逻辑；复杂判断沉到 controller 或 service。
- 不把多个职责塞进单个组件，View 可以拆小，但配置类和模型类按聚合策略放在少量文件中。

## MVC 分层

### Model

Model 层只描述数据和轻量规则，不包含 UI、文件 IO、播放器控制逻辑。

```text
lib/src/models/media_asset_models.dart
  MediaAsset
  MediaAssetType
  MediaAssetAction
  RejectedMediaFile
  RejectedMediaFileReason
```

### View

View 层负责 Flutter Widget 渲染，只接收状态和回调。

```text
lib/src/views/media_asset.dart
lib/src/views/media_asset_grid.dart
lib/src/views/media_asset_tile.dart
lib/src/views/media_asset_drop_zone.dart
lib/src/views/media_asset_preview_dialog.dart
lib/src/views/image_asset_preview.dart
lib/src/views/video_asset_preview.dart
lib/src/views/media_asset_toolbar.dart
```

View 层允许做：

- 根据传入状态渲染 UI。
- 把点击、双击、拖拽、键盘事件转发给 controller 或外部回调。
- 使用 theme/config 决定视觉样式。

View 层不允许做：

- 文件扩展名判断。
- 文件大小校验。
- 维护复杂选择逻辑。
- 控制预览素材索引切换规则。
- 处理导入、删除、下载的业务流程。

### Controller

Controller 层负责交互状态和用户动作编排，不负责具体 UI 绘制。

```text
lib/src/controllers/media_asset_controller.dart
lib/src/controllers/media_asset_selection_controller.dart
lib/src/controllers/media_asset_preview_controller.dart
```

建议职责：

```text
MediaAssetLibraryController
  协调导入、删除、下载、双击预览等素材库级动作。

MediaAssetSelectionController
  维护 selectedAssetIds、全选、反选、清空选择、单个切换。

MediaAssetPreviewController
  维护当前预览索引、上一个/下一个、当前素材类型、图片缩放状态、视频播放动作入口。
```

### Service

Service 层承接纯逻辑，保持可单元测试。

```text
lib/src/services/media_file_type_service.dart
lib/src/services/media_file_size_formatter.dart
```

建议职责：

```text
MediaFileTypeService
  根据 MediaAssetFileTypeConfig 判断文件是否支持，并返回拒绝原因。

MediaFileSizeFormatter
  将 int 字节数格式化为 B / KB / MB / GB。
```

### 数据流

组件采用单向数据流：

```text
外部项目传入 assets/config/selectedAssetIds
  -> View 渲染素材库
  -> 用户点击、双击、拖拽、快捷键
  -> View 转发事件
  -> Controller 更新内部交互状态或调用外部回调
  -> 外部项目更新 assets/selectedAssetIds
  -> View 重新渲染
```

导入流程：

```text
DropZone View 收到文件路径
  -> MediaAssetLibraryController.handleImportFiles
  -> MediaFileTypeService.validateFiles
  -> 不支持文件通过 onRejectedFiles 返回
  -> 支持文件通过 onImportFiles 返回给调用方
  -> 调用方复制文件并生成 MediaAsset
  -> 调用方重新传入 assets
```

预览流程：

```text
Tile View 双击
  -> MediaAssetLibraryController.handlePreview
  -> 打开 MediaAssetPreviewDialog
  -> MediaAssetPreviewController 管理当前索引
  -> ImageAssetPreview / VideoAssetPreview 只渲染当前素材
```

选择流程：

```text
Tile View 点击选择框
  -> MediaAssetSelectionController.toggle
  -> 生成新的 selectedAssetIds
  -> onSelectionChanged 返回给调用方
```

## 文件聚合策略

为避免 package 内部出现大量只有一个类的小文件，第一版采用“按职责聚合”的文件组织方式：

```text
media_asset_config.dart
  放所有配置类：全局配置、文件类型配置、图片快捷键、视频快捷键。

media_asset_models.dart
  放所有轻量模型和规则：素材模型、素材类型、素材动作、拒绝文件原因、导入校验结果。

media_asset_theme.dart
  放所有主题相关类：主题数据、InheritedTheme、默认颜色解析。
```

不建议继续拆成：

```text
media_asset_file_type_config.dart
media_asset_shortcuts.dart
media_asset_type.dart
media_asset_action.dart
```

这样调用方只需要引用 package 入口文件，package 内部也只在必要位置引用 2 到 3 个聚合文件。

## 推荐目录结构

```text
media_asset/
  lib/
    media_asset.dart

    src/
      config/
        media_asset_config.dart

      models/
        media_asset_models.dart

      controllers/
        media_asset_controller.dart
        media_asset_selection_controller.dart
        media_asset_preview_controller.dart

      views/
        media_asset.dart
        media_asset_grid.dart
        media_asset_tile.dart
        media_asset_drop_zone.dart
        media_asset_preview_dialog.dart
        image_asset_preview.dart
        video_asset_preview.dart
        media_asset_toolbar.dart

      theme/
        media_asset_theme.dart

      services/
        media_file_type_service.dart
        media_file_size_formatter.dart

  example/
    lib/main.dart

  test/
  README.md
  CHANGELOG.md
  LICENSE
  pubspec.yaml
```

## Public API

统一从入口文件导出：

```dart
export 'src/config/media_asset_config.dart';
export 'src/models/media_asset_models.dart';
export 'src/theme/media_asset_theme.dart';
export 'src/views/media_asset.dart';
export 'src/views/media_asset_preview_dialog.dart';
```

使用方只 import：

```dart
import 'package:media_asset/media_asset.dart';
```

`media_asset_config.dart` 统一包含所有配置类，避免调用方和内部实现到处引用多个 config 文件：

```text
media_asset_config.dart
  MediaAssetLibraryConfig
  MediaAssetFileTypeConfig
  ImagePreviewShortcuts
  VideoPreviewShortcuts
```

内部其他文件如果需要配置，也只引用：

```dart
import '../config/media_asset_config.dart';
```

同理，模型、枚举、动作类型等稳定的 value classes 统一放在：

```text
media_asset_models.dart
  MediaAsset
  MediaAssetType
  MediaAssetAction
  RejectedMediaFile
  RejectedMediaFileReason
  MediaImportValidationResult
```

内部其他文件如果需要素材模型或规则，也只引用：

```dart
import '../models/media_asset_models.dart';
```

## 数据模型

所有模型、枚举、规则类统一放在：

```text
lib/src/models/media_asset_models.dart
```

这个文件只放轻量数据结构，不放 Widget、不放控制器、不放文件 IO。第一版建议包含素材类型、素材动作、拒绝原因、导入校验结果和素材数据本身。

### 素材类型

第一版只保留图片和视频：

```dart
enum MediaAssetType {
  image,
  video,
}
```

### 素材动作

```dart
enum MediaAssetAction {
  preview,
  select,
  delete,
  download,
}
```

### 拒绝文件原因

```dart
enum RejectedMediaFileReason {
  unsupportedType,
  imageTooLarge,
  videoTooLarge,
}

class RejectedMediaFile {
  final String path;
  final RejectedMediaFileReason reason;

  const RejectedMediaFile({
    required this.path,
    required this.reason,
  });
}
```

### 导入校验结果

```dart
class MediaImportValidationResult {
  final List<String> acceptedPaths;
  final List<RejectedMediaFile> rejectedFiles;

  const MediaImportValidationResult({
    required this.acceptedPaths,
    required this.rejectedFiles,
  });
}
```

### 素材数据

```dart
class MediaAsset {
  final String id;
  final String name;
  final String filePath;
  final MediaAssetType type;
  final int fileSize;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? thumbnailPath;
  final Duration? duration;
  final int? width;
  final int? height;
  final Object? extra;

  const MediaAsset({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    required this.fileSize,
    required this.createdAt,
    this.updatedAt,
    this.thumbnailPath,
    this.duration,
    this.width,
    this.height,
    this.extra,
  });
}
```

`extra` 用于让业务方挂载自己的原始对象，例如数据库记录、项目素材 ID、云端 URL 等。

## 全局配置

所有配置类统一放在：

```text
lib/src/config/media_asset_config.dart
```

这个文件只负责配置声明，不放 UI、不放文件 IO。这样 package 内部和使用方都能通过一个稳定入口获得全部配置类型，避免出现多个配置文件互相引用。

提供全局默认配置：

```dart
class MediaAssetLibraryConfig {
  final MediaAssetFileTypeConfig fileTypes;
  final ImagePreviewShortcuts imageShortcuts;
  final VideoPreviewShortcuts videoShortcuts;
  final bool enableDragDrop;
  final bool enableMultiSelection;
  final bool enablePreviewNavigation;
  final Duration previewAnimationDuration;

  const MediaAssetLibraryConfig({
    this.fileTypes = const MediaAssetFileTypeConfig(),
    this.imageShortcuts = const ImagePreviewShortcuts(),
    this.videoShortcuts = const VideoPreviewShortcuts(),
    this.enableDragDrop = true,
    this.enableMultiSelection = true,
    this.enablePreviewNavigation = true,
    this.previewAnimationDuration = const Duration(milliseconds: 150),
  });
}
```

支持通过组件传入：

```dart
MediaAssetLibrary(
  config: const MediaAssetLibraryConfig(),
  assets: assets,
)
```

也支持用 inherited widget 做全局配置：

```dart
MediaAssetLibraryScope(
  config: const MediaAssetLibraryConfig(),
  child: MyApp(),
)
```

组件级 `config` 优先级高于 `MediaAssetLibraryScope`。

推荐该文件最终结构：

```dart
import 'package:flutter/services.dart';

class MediaAssetLibraryConfig {
  final MediaAssetFileTypeConfig fileTypes;
  final ImagePreviewShortcuts imageShortcuts;
  final VideoPreviewShortcuts videoShortcuts;
  final bool enableDragDrop;
  final bool enableMultiSelection;
  final bool enablePreviewNavigation;
  final Duration previewAnimationDuration;

  const MediaAssetLibraryConfig({
    this.fileTypes = const MediaAssetFileTypeConfig(),
    this.imageShortcuts = const ImagePreviewShortcuts(),
    this.videoShortcuts = const VideoPreviewShortcuts(),
    this.enableDragDrop = true,
    this.enableMultiSelection = true,
    this.enablePreviewNavigation = true,
    this.previewAnimationDuration = const Duration(milliseconds: 150),
  });
}

class MediaAssetFileTypeConfig {
  final Set<String> imageExtensions;
  final Set<String> videoExtensions;
  final int? maxImageFileSize;
  final int? maxVideoFileSize;

  const MediaAssetFileTypeConfig({
    this.imageExtensions = const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
    },
    this.videoExtensions = const {
      'mp4',
      'mov',
      'm4v',
      'webm',
      'mkv',
      'avi',
    },
    this.maxImageFileSize,
    this.maxVideoFileSize,
  });
}

class ImagePreviewShortcuts {
  final LogicalKeyboardKey previous;
  final LogicalKeyboardKey next;
  final LogicalKeyboardKey close;
  final LogicalKeyboardKey zoomIn;
  final LogicalKeyboardKey zoomOut;
  final LogicalKeyboardKey resetZoom;
  final LogicalKeyboardKey fitToScreen;

  const ImagePreviewShortcuts({
    this.previous = LogicalKeyboardKey.arrowLeft,
    this.next = LogicalKeyboardKey.arrowRight,
    this.close = LogicalKeyboardKey.escape,
    this.zoomIn = LogicalKeyboardKey.equal,
    this.zoomOut = LogicalKeyboardKey.minus,
    this.resetZoom = LogicalKeyboardKey.digit0,
    this.fitToScreen = LogicalKeyboardKey.keyF,
  });
}

class VideoPreviewShortcuts {
  final LogicalKeyboardKey previous;
  final LogicalKeyboardKey next;
  final LogicalKeyboardKey close;
  final LogicalKeyboardKey playPause;
  final LogicalKeyboardKey seekBackward;
  final LogicalKeyboardKey seekForward;
  final LogicalKeyboardKey mute;
  final LogicalKeyboardKey fullscreen;
  final Duration seekStep;

  const VideoPreviewShortcuts({
    this.previous = LogicalKeyboardKey.arrowLeft,
    this.next = LogicalKeyboardKey.arrowRight,
    this.close = LogicalKeyboardKey.escape,
    this.playPause = LogicalKeyboardKey.space,
    this.seekBackward = LogicalKeyboardKey.keyJ,
    this.seekForward = LogicalKeyboardKey.keyL,
    this.mute = LogicalKeyboardKey.keyM,
    this.fullscreen = LogicalKeyboardKey.keyF,
    this.seekStep = const Duration(seconds: 5),
  });
}
```

## 支持文件类型配置

默认只允许图片和视频：

```dart
class MediaAssetFileTypeConfig {
  final Set<String> imageExtensions;
  final Set<String> videoExtensions;
  final int? maxImageFileSize;
  final int? maxVideoFileSize;

  const MediaAssetFileTypeConfig({
    this.imageExtensions = const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
    },
    this.videoExtensions = const {
      'mp4',
      'mov',
      'm4v',
      'webm',
      'mkv',
      'avi',
    },
    this.maxImageFileSize,
    this.maxVideoFileSize,
  });
}
```

使用方示例：

```dart
const MediaAssetLibraryConfig(
  fileTypes: MediaAssetFileTypeConfig(
    imageExtensions: {'png', 'jpg', 'jpeg', 'webp'},
    videoExtensions: {'mp4', 'mov'},
    maxImageFileSize: 20 * 1024 * 1024,
    maxVideoFileSize: 500 * 1024 * 1024,
  ),
)
```

文件类型识别规则：

- 通过扩展名判断。
- 扩展名不区分大小写。
- 不在配置中的文件应被拒绝。
- 被拒绝原因通过 `onRejectedFiles` 回调返回给使用方。

## 快捷键配置

图片和视频分开配置，互不影响。

### 图片快捷键

```dart
class ImagePreviewShortcuts {
  final LogicalKeyboardKey previous;
  final LogicalKeyboardKey next;
  final LogicalKeyboardKey close;
  final LogicalKeyboardKey zoomIn;
  final LogicalKeyboardKey zoomOut;
  final LogicalKeyboardKey resetZoom;
  final LogicalKeyboardKey fitToScreen;

  const ImagePreviewShortcuts({
    this.previous = LogicalKeyboardKey.arrowLeft,
    this.next = LogicalKeyboardKey.arrowRight,
    this.close = LogicalKeyboardKey.escape,
    this.zoomIn = LogicalKeyboardKey.equal,
    this.zoomOut = LogicalKeyboardKey.minus,
    this.resetZoom = LogicalKeyboardKey.digit0,
    this.fitToScreen = LogicalKeyboardKey.keyF,
  });
}
```

图片默认行为：

```text
Left        上一个素材
Right       下一个素材
Esc         关闭
=           放大
-           缩小
0           重置缩放
F           适配屏幕
```

### 视频快捷键

```dart
class VideoPreviewShortcuts {
  final LogicalKeyboardKey previous;
  final LogicalKeyboardKey next;
  final LogicalKeyboardKey close;
  final LogicalKeyboardKey playPause;
  final LogicalKeyboardKey seekBackward;
  final LogicalKeyboardKey seekForward;
  final LogicalKeyboardKey mute;
  final LogicalKeyboardKey fullscreen;
  final Duration seekStep;

  const VideoPreviewShortcuts({
    this.previous = LogicalKeyboardKey.arrowLeft,
    this.next = LogicalKeyboardKey.arrowRight,
    this.close = LogicalKeyboardKey.escape,
    this.playPause = LogicalKeyboardKey.space,
    this.seekBackward = LogicalKeyboardKey.keyJ,
    this.seekForward = LogicalKeyboardKey.keyL,
    this.mute = LogicalKeyboardKey.keyM,
    this.fullscreen = LogicalKeyboardKey.keyF,
    this.seekStep = const Duration(seconds: 5),
  });
}
```

视频默认行为：

```text
Left        上一个素材
Right       下一个素材
Esc         关闭
Space       播放/暂停
J           后退 5 秒
L           前进 5 秒
M           静音/取消静音
F           全屏/退出全屏
```

使用方示例：

```dart
const MediaAssetLibraryConfig(
  imageShortcuts: ImagePreviewShortcuts(
    zoomIn: LogicalKeyboardKey.numpadAdd,
    zoomOut: LogicalKeyboardKey.numpadSubtract,
  ),
  videoShortcuts: VideoPreviewShortcuts(
    playPause: LogicalKeyboardKey.space,
    seekBackward: LogicalKeyboardKey.arrowDown,
    seekForward: LogicalKeyboardKey.arrowUp,
    seekStep: Duration(seconds: 3),
  ),
)
```

## Controller 设计草案

Controller 使用普通 Dart 类或 `ChangeNotifier` 均可。第一版建议选择普通 Dart 类，降低状态魔法；需要通知 UI 时由 View 层通过 `setState` 或外部受控状态更新。

### 选择控制器

```dart
class MediaAssetSelectionController {
  Set<String> toggle({
    required Set<String> selectedIds,
    required String assetId,
  }) {
    final next = Set<String>.from(selectedIds);
    if (next.contains(assetId)) {
      next.remove(assetId);
    } else {
      next.add(assetId);
    }
    return next;
  }

  Set<String> selectAll(List<MediaAsset> assets) {
    return assets.map((asset) => asset.id).toSet();
  }

  Set<String> clear() {
    return const {};
  }
}
```

### 预览控制器

```dart
class MediaAssetPreviewController {
  final List<MediaAsset> assets;
  int currentIndex;

  MediaAssetPreviewController({
    required MediaAsset initialAsset,
    required List<MediaAsset> assets,
  }) : assets = assets.where(_isPreviewable).toList(),
       currentIndex = _resolveInitialIndex(initialAsset, assets);

  MediaAsset get currentAsset => assets[currentIndex];

  bool get canNavigate => assets.length > 1;

  MediaAsset previous() {
    currentIndex = (currentIndex - 1 + assets.length) % assets.length;
    return currentAsset;
  }

  MediaAsset next() {
    currentIndex = (currentIndex + 1) % assets.length;
    return currentAsset;
  }
}
```

实现时注意：

- `_isPreviewable` 只允许图片和视频。
- `_resolveInitialIndex` 找不到初始素材时回退到 0。
- View 只调用 `previous()` / `next()`，不自己计算索引。

### 素材库控制器

```dart
class MediaAssetLibraryController {
  final MediaAssetFileTypeService fileTypeService;

  const MediaAssetLibraryController({
    required this.fileTypeService,
  });

  MediaImportValidationResult validateImportFiles({
    required List<String> paths,
    required MediaAssetLibraryConfig config,
  }) {
    return fileTypeService.validateFiles(
      paths: paths,
      config: config.fileTypes,
    );
  }
}
```

`MediaImportValidationResult` 放在 `media_asset_models.dart`：

```dart
class MediaImportValidationResult {
  final List<String> acceptedPaths;
  final List<RejectedMediaFile> rejectedFiles;

  const MediaImportValidationResult({
    required this.acceptedPaths,
    required this.rejectedFiles,
  });
}
```

## Service 设计草案

### 文件类型服务

```dart
class MediaAssetFileTypeService {
  MediaImportValidationResult validateFiles({
    required List<String> paths,
    required MediaAssetFileTypeConfig config,
  }) {
    // 只做纯校验：扩展名、图片大小限制、视频大小限制。
    // 不复制文件，不创建 MediaAsset，不弹 Toast。
  }
}
```

### 文件大小格式化

```dart
class MediaFileSizeFormatter {
  String format(int bytes) {
    // B / KB / MB / GB
  }
}
```

## 核心组件设计

### 素材库组件

```dart
class MediaAssetLibrary extends StatelessWidget {
  final List<MediaAsset> assets;
  final MediaAssetLibraryConfig? config;
  final Set<String> selectedAssetIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<MediaAsset>? onAssetTap;
  final ValueChanged<MediaAsset>? onAssetDoubleTap;
  final ValueChanged<List<MediaAsset>>? onDeleteAssets;
  final ValueChanged<List<MediaAsset>>? onDownloadAssets;
  final Future<void> Function(List<String> filePaths)? onImportFiles;
  final ValueChanged<List<RejectedMediaFile>>? onRejectedFiles;

  const MediaAssetLibrary({
    super.key,
    required this.assets,
    this.config,
    this.selectedAssetIds = const {},
    this.onSelectionChanged,
    this.onAssetTap,
    this.onAssetDoubleTap,
    this.onDeleteAssets,
    this.onDownloadAssets,
    this.onImportFiles,
    this.onRejectedFiles,
  });
}
```

默认双击行为：

- 如果使用方提供 `onAssetDoubleTap`，调用使用方回调。
- 否则打开内置 `MediaAssetPreviewDialog`。

### 预览弹窗

```dart
class MediaAssetPreviewDialog extends StatefulWidget {
  final MediaAsset asset;
  final List<MediaAsset> assets;
  final MediaAssetLibraryConfig? config;

  const MediaAssetPreviewDialog({
    super.key,
    required this.asset,
    this.assets = const [],
    this.config,
  });

  static Future<void> show(
    BuildContext context, {
    required MediaAsset asset,
    List<MediaAsset> assets = const [],
    MediaAssetLibraryConfig? config,
  });
}
```

预览弹窗内部根据类型切换：

```text
MediaAssetType.image -> ImageAssetPreview
MediaAssetType.video -> VideoAssetPreview
```

## UI 配置

主题数据：

```dart
class MediaAssetLibraryThemeData {
  final Color? backgroundColor;
  final Color? surfaceColor;
  final Color? borderColor;
  final Color? primaryColor;
  final Color? dangerColor;
  final BorderRadiusGeometry tileBorderRadius;
  final BorderRadiusGeometry dialogBorderRadius;
  final double tileWidth;
  final double tilePreviewHeight;

  const MediaAssetLibraryThemeData({
    this.backgroundColor,
    this.surfaceColor,
    this.borderColor,
    this.primaryColor,
    this.dangerColor,
    this.tileBorderRadius = const BorderRadius.all(Radius.circular(8)),
    this.dialogBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.tileWidth = 96,
    this.tilePreviewHeight = 68,
  });
}
```

全局主题：

```dart
MediaAssetLibraryTheme(
  data: const MediaAssetLibraryThemeData(
    tileWidth: 100,
    tilePreviewHeight: 72,
  ),
  child: MediaAssetLibrary(...),
)
```

## 存储策略

package 不强制管理存储。它只关心：

- 当前素材列表 `assets`
- 用户导入了哪些文件
- 用户删除了哪些素材
- 用户下载了哪些素材
- 用户选择了哪些素材

业务方决定：

- 文件复制到哪里
- 数据保存到数据库、JSON、云端还是内存
- 素材 ID 如何生成
- 缩略图如何生成
- 视频转码是否需要处理

如果需要提供默认实现，可以在后续版本增加：

```dart
abstract class MediaAssetRepository {
  Future<List<MediaAsset>> listAssets();
  Future<List<MediaAsset>> importFiles(List<String> paths);
  Future<void> deleteAssets(Set<String> ids);
}
```

但第一版建议优先做纯 UI 受控组件，降低耦合。

## 依赖建议

`pubspec.yaml`：

```yaml
name: media_asset
description: A configurable Flutter image and video asset library.
version: 0.1.0

environment:
  sdk: ^3.5.0
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter
  path: ^1.9.0
  desktop_drop: ^0.7.0
  cross_file: ^0.3.5+2
  video_player: ^2.10.1
  fvp: ^0.35.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

说明：

- `desktop_drop` 用于桌面拖拽导入。
- `cross_file` 用于统一拖拽文件对象。
- `video_player` 用于视频播放。
- `fvp` 用于桌面端视频后端。
- 不依赖当前项目的任何包。

## 使用示例

```dart
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  List<MediaAsset> assets = [];
  Set<String> selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return MediaAssetLibraryScope(
      config: const MediaAssetLibraryConfig(
        fileTypes: MediaAssetFileTypeConfig(
          imageExtensions: {'png', 'jpg', 'jpeg', 'webp'},
          videoExtensions: {'mp4', 'mov'},
        ),
        videoShortcuts: VideoPreviewShortcuts(
          seekStep: Duration(seconds: 5),
        ),
      ),
      child: MediaAssetLibrary(
        assets: assets,
        selectedAssetIds: selectedIds,
        onSelectionChanged: (value) {
          setState(() => selectedIds = value);
        },
        onImportFiles: (paths) async {
          // 使用方负责复制文件、生成 ID、创建 MediaAsset。
        },
        onDeleteAssets: (items) {
          // 使用方负责删除数据和文件。
        },
      ),
    );
  }
}
```

## 开发路线

### 0.1.0

- 独立 package 工程。
- `MediaAsset` / `MediaAssetType`。
- `MediaAssetLibraryConfig`。
- MVC 目录骨架。
- `MediaAssetLibraryController`。
- `MediaAssetSelectionController`。
- `MediaAssetPreviewController`。
- `MediaFileTypeService`。
- `MediaFileSizeFormatter`。
- 支持图片和视频文件类型配置。
- 素材网格。
- 素材卡片。
- 拖拽导入。
- 双击预览。
- 图片预览。
- 视频预览。
- 图片/视频分离快捷键。

### 0.2.0

- 主题系统。
- 自定义 tile builder。
- 自定义 toolbar builder。
- 自定义 empty builder。
- 自定义 rejected file builder。
- Controller 对外 API 稳定。
- View 层重构检查，确保没有文件校验和选择状态逻辑泄漏。
- 更完整 example。

### 0.3.0

- 可选 repository 抽象。
- 缩略图扩展点。
- 视频错误状态优化。
- 移动端布局适配。
- Controller 和 service 的边界文档。
- 更多测试。

### 1.0.0

- API 稳定。
- 文档完整。
- example 完整。
- 发布到 pub.dev。

## 测试计划

单元测试：

- 文件扩展名识别。
- 文件类型配置过滤。
- 文件大小限制。
- 快捷键配置默认值。
- `MediaAssetSelectionController`：单选、取消、全选、清空。
- `MediaAssetPreviewController`：初始索引、上一个、下一个、边界循环。
- `MediaAssetLibraryController`：导入校验、拒绝文件回调、导入文件回调。
- `MediaFileTypeService`：扩展名大小写、未知扩展名、图片/视频大小限制。
- `MediaFileSizeFormatter`：B、KB、MB、GB 格式化。

Widget 测试：

- 素材网格渲染。
- 空状态渲染。
- 批量选择。
- 双击打开预览。
- 图片快捷键触发缩放。
- 视频快捷键触发播放、暂停、快进、快退。
- View 事件只触发回调，不直接修改外部 assets。
- DropZone 收到文件后只转发给 controller，不直接过滤文件。

手动测试：

- Windows 拖拽导入。
- Linux 拖拽导入。
- macOS 拖拽导入。
- 图片预览缩放和切换。
- 视频预览播放和切换。
- 大文件视频加载失败提示。

结构检查：

- `views/` 不 import `dart:io`。
- `views/` 不调用文件类型判断函数。
- `views/` 不直接修改 `selectedAssetIds`。
- `controllers/` 不 import theme 文件。
- `services/` 不 import Flutter Widget。
- `models/` 不 import Flutter UI。
- example 只 import `package:media_asset/media_asset.dart`。

## 发布清单

发布前确认：

- 不包含任何当前项目路径或 import。
- 不包含业务命名，例如 Project、Segment、Shot、StoryFlow。
- README 有完整使用示例。
- example 可以独立运行。
- LICENSE 已添加。
- CHANGELOG 已添加。
- public API 有注释。
- MVC 分层检查通过。
- View 和逻辑分离检查通过。
- `flutter analyze` 通过。
- `flutter test` 通过。
- dry-run 通过。

命令：

```bash
flutter pub publish --dry-run
flutter pub publish
```

## 最终边界

这个库只负责：

- 图片/视频素材展示。
- 图片/视频素材预览。
- 图片/视频文件类型过滤。
- 选择。
- 拖拽导入入口。
- 快捷键交互。

这个库不负责：

- 业务数据保存。
- 项目结构管理。
- 素材复制策略。
- 云端上传。
- AI 生成。
- 片段和镜头关系。
