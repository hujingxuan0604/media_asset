import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_asset/media_asset.dart';

void main() {
  runApp(const MediaAssetExampleApp());
}

class MediaAssetExampleApp extends StatelessWidget {
  const MediaAssetExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'media_asset example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MediaAssetExamplePage(),
    );
  }
}

class MediaAssetExamplePage extends StatefulWidget {
  const MediaAssetExamplePage({super.key});

  @override
  State<MediaAssetExamplePage> createState() => _MediaAssetExamplePageState();
}

class _MediaAssetExamplePageState extends State<MediaAssetExamplePage> {
  final List<MediaAsset> _assets = [];
  final List<MediaAsset> _moduleAssets = [];
  final Set<String> _selectedAssetIds = {};
  final Set<String> _customSelectedAssetIds = {};
  double _moduleHeight = 280;
  bool _moduleCollapsed = false;

  static const _config = MediaAssetLibraryConfig(
    importConfig: MediaAssetImportConfig(
      fileTypes: MediaAssetFileTypeConfig(
        imageExtensions: {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'},
        videoExtensions: {'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'},
        maxImageFileSize: 30 * 1024 * 1024,
        maxVideoFileSize: 1024 * 1024 * 1024,
      ),
    ),
    text: MediaAssetTextConfig(
      emptyTitle: '拖入图片或视频文件',
      emptyDescription: '示例不会复制文件，只把本地路径转换成 MediaAsset 用于预览。',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('media_asset example'),
          actions: [
            TextButton.icon(
              onPressed: _loadSampleAssets,
              icon: const Icon(Icons.auto_awesome_motion_outlined, size: 18),
              label: const Text('示例数据'),
            ),
            TextButton.icon(
              onPressed: _assets.isEmpty ? null : _clearAll,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: const Text('清空'),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_customize_outlined), text: '工作台'),
              Tab(icon: Icon(Icons.tune_outlined), text: '便捷参数'),
              Tab(icon: Icon(Icons.visibility_outlined), text: '只读模式'),
              Tab(icon: Icon(Icons.brush_outlined), text: '自定义外观'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: MediaAssetLibraryScope(
            config: _config,
            child: MediaAssetTheme(
              data: const MediaAssetThemeData(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: TabBarView(
                children: [
                  _buildWorkbenchExample(),
                  _buildConvenienceExample(),
                  _buildReadOnlyExample(),
                  _buildCustomExample(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkbenchExample() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final library = MediaAssetLibrary(
          title: '项目素材库',
          assets: _assets,
          height: constraints.maxWidth < 820 ? 360 : null,
          selectedAssetIds: _selectedAssetIds,
          onSelectionChanged: _replaceSelection,
          onImportFiles: _handleImportFiles,
          onRejectedFiles: _handleRejectedFiles,
          onResolveImportSources: _resolveImportSources,
          onDeleteAsset: _deleteAsset,
          onDeleteSelectedAssets: _deleteAssets,
          onRevealAssetInFolder: (asset) {
            _showMessage('在文件夹中显示：${asset.name}');
          },
        );
        final target = _ModuleDropTarget(
          assets: _moduleAssets,
          height: _moduleHeight,
          isCollapsed: _moduleCollapsed,
          onHeightChanged: _changeModuleHeight,
          onToggleCollapsed: _toggleModuleCollapsed,
          onAcceptAsset: _addToModule,
        );

        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              Expanded(child: library),
              const SizedBox(height: 16),
              target,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: library),
            const SizedBox(width: 20),
            SizedBox(width: 280, child: target),
          ],
        );
      },
    );
  }

  Widget _buildConvenienceExample() {
    final assets = _showcaseAssets;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 880;
        final children = [
          _ExamplePanel(
            title: '固定高度 + 折叠',
            subtitle: 'height / collapsible',
            child: MediaAssetLibrary(
              title: '三视图',
              assets: assets.take(4).toList(),
              height: 240,
              collapsible: true,
            ),
          ),
          _ExamplePanel(
            title: '自定义缩略图尺寸',
            subtitle: 'config.layout.thumbnailSize',
            child: MediaAssetLibrary(
              title: '分镜素材',
              assets: assets,
              height: 240,
              config: const MediaAssetLibraryConfig(
                layout: MediaAssetLayoutConfig(thumbnailSize: Size(86, 62)),
              ),
            ),
          ),
        ];

        if (isNarrow) {
          return ListView.separated(
            itemCount: children.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => children[index],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }

  Widget _buildReadOnlyExample() {
    final assets = _showcaseAssets;

    return LayoutBuilder(
      builder: (context, constraints) {
        final library = MediaAssetLibrary(
          title: '审核素材',
          assets: assets,
          height: constraints.maxWidth < 760 ? 320 : null,
          config: const MediaAssetLibraryConfig(
            interaction: MediaAssetInteractionConfig(
              enableDragDrop: false,
              enableMultiSelection: false,
              enableAssetDragging: false,
              enableContextMenu: false,
              enabledActions: {},
            ),
            layout: MediaAssetLayoutConfig(thumbnailSize: Size(120, 86)),
            text: MediaAssetTextConfig(
              emptyTitle: '暂无审核素材',
              emptyDescription: '只读场景可以关闭拖拽、选择、右键菜单和素材拖出。',
            ),
          ),
        );

        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              Expanded(child: library),
              const SizedBox(height: 16),
              _ReadOnlySummary(assets: assets),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: library),
            const SizedBox(width: 16),
            SizedBox(width: 260, child: _ReadOnlySummary(assets: assets)),
          ],
        );
      },
    );
  }

  Widget _buildCustomExample() {
    final assets = _showcaseAssets;

    return ListView(
      children: [
        _ExamplePanel(
          title: '自定义工具栏 + 选择标记',
          subtitle: 'toolbarBuilder / selectionBadgeBuilder',
          child: MediaAssetLibrary(
            title: '精选资产',
            assets: assets,
            height: 260,
            selectedAssetIds: _customSelectedAssetIds,
            onSelectionChanged: _replaceCustomSelection,
            toolbarBuilder: (context, state) {
              return _CustomToolbar(
                state: state,
                onClearSelection: () => _replaceCustomSelection({}),
              );
            },
            selectionBadgeBuilder: (context, asset, state) {
              return _CustomSelectionBadge(selected: state.isBatchSelected);
            },
            dragFeedbackBuilder: (context, asset, state) {
              return _CustomDragFeedback(asset: asset);
            },
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(thumbnailSize: Size(112, 80)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ExamplePanel(
          title: '完全自定义 Tile',
          subtitle: 'tileBuilder',
          child: MediaAssetLibrary(
            title: '文件清单',
            assets: assets,
            height: 220,
            tileBuilder: (context, asset, state) {
              return _CustomAssetTile(asset: asset, state: state);
            },
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(thumbnailSize: Size(118, 72)),
              interaction: MediaAssetInteractionConfig(
                enableContextMenu: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<MediaAsset> get _showcaseAssets {
    if (_assets.isNotEmpty) {
      return _assets;
    }
    return _sampleAssets();
  }

  List<MediaAsset> _sampleAssets() {
    final imagePath = _repoFilePath('web/icons/Icon-192.png');
    final thumbnailPath = File(imagePath).existsSync() ? imagePath : null;
    final createdAt = DateTime(2026, 1, 1, 9);
    return [
      MediaAsset(
        id: 'sample-front',
        name: 'front_view.png',
        filePath: imagePath,
        thumbnailPath: thumbnailPath,
        type: MediaAssetType.image,
        fileSize: 148 * 1024,
        contentHash: 'sample-front',
        width: 1920,
        height: 1080,
        createdAt: createdAt.add(const Duration(minutes: 1)),
      ),
      MediaAsset(
        id: 'sample-side',
        name: 'side_view.png',
        filePath: imagePath,
        thumbnailPath: thumbnailPath,
        type: MediaAssetType.image,
        fileSize: 172 * 1024,
        contentHash: 'sample-side',
        width: 1920,
        height: 1080,
        createdAt: createdAt.add(const Duration(minutes: 2)),
      ),
      MediaAsset(
        id: 'sample-motion',
        name: 'turntable_preview.mp4',
        filePath: '/tmp/turntable_preview.mp4',
        thumbnailPath: thumbnailPath,
        type: MediaAssetType.video,
        fileSize: 18 * 1024 * 1024,
        contentHash: 'sample-motion',
        duration: const Duration(seconds: 24),
        createdAt: createdAt.add(const Duration(minutes: 3)),
      ),
      MediaAsset(
        id: 'sample-texture',
        name: 'material_reference.webp',
        filePath: imagePath,
        thumbnailPath: thumbnailPath,
        type: MediaAssetType.image,
        fileSize: 624 * 1024,
        contentHash: 'sample-texture',
        width: 2048,
        height: 2048,
        createdAt: createdAt.add(const Duration(minutes: 4)),
      ),
      MediaAsset(
        id: 'sample-blocking',
        name: 'camera_blocking.mov',
        filePath: '/tmp/camera_blocking.mov',
        thumbnailPath: thumbnailPath,
        type: MediaAssetType.video,
        fileSize: 42 * 1024 * 1024,
        contentHash: 'sample-blocking',
        duration: const Duration(seconds: 38),
        createdAt: createdAt.add(const Duration(minutes: 5)),
      ),
      MediaAsset(
        id: 'sample-poster',
        name: 'poster_crop.jpg',
        filePath: imagePath,
        thumbnailPath: thumbnailPath,
        type: MediaAssetType.image,
        fileSize: 384 * 1024,
        contentHash: 'sample-poster',
        width: 1440,
        height: 1920,
        createdAt: createdAt.add(const Duration(minutes: 6)),
      ),
    ];
  }

  String _repoFilePath(String relativePath) {
    final current = Directory.current.path;
    final candidates = ['$current/$relativePath', '$current/../$relativePath'];

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    return candidates.first;
  }

  void _loadSampleAssets() {
    final existingIds = _assets.map((asset) => asset.id).toSet();
    final samples = _sampleAssets()
        .where((asset) => !existingIds.contains(asset.id))
        .toList();
    if (samples.isEmpty) {
      _showMessage('示例数据已经在项目素材库中');
      return;
    }

    setState(() {
      _assets.addAll(samples);
    });
    _showMessage('已添加 ${samples.length} 个示例素材');
  }

  Future<void> _handleImportFiles(
    List<ValidatedMediaAssetImport> candidates,
  ) async {
    final now = DateTime.now();
    final imported = candidates.map((candidate) {
      return MediaAsset(
        id: '${now.microsecondsSinceEpoch}-${candidate.path}',
        name: candidate.name,
        filePath: candidate.path,
        type: candidate.type,
        fileSize: candidate.fileSize,
        contentHash: candidate.contentHash,
        createdAt: now,
      );
    }).toList();

    setState(() {
      _assets.addAll(imported);
    });

    _showMessage('已导入 ${imported.length} 个素材');
  }

  Future<List<LocalMediaImportSource>> _resolveImportSources(
    List<LocalMediaImportSource> sources,
  ) async {
    final resolved = <LocalMediaImportSource>[];
    for (final source in sources) {
      resolved.add(await _resolveImportSource(source));
    }
    return resolved;
  }

  Future<LocalMediaImportSource> _resolveImportSource(
    LocalMediaImportSource source,
  ) async {
    if (source.contentHash != null || !source.exists || !source.isReadable) {
      return source;
    }

    try {
      final file = File(source.path);
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        return source;
      }

      return source.copyWith(
        fileSize: source.fileSize ?? stat.size,
        contentHash:
            '${file.absolute.path}|${stat.size}|${stat.modified.microsecondsSinceEpoch}',
      );
    } catch (_) {
      return source;
    }
  }

  void _handleRejectedFiles(List<RejectedMediaFile> files) {
    final message = files
        .map((file) {
          return '${_fileName(file.path)}：${_rejectionLabel(file.reason)}';
        })
        .join('\n');
    _showMessage(message);
  }

  void _replaceSelection(Set<String> selectedAssetIds) {
    setState(() {
      _selectedAssetIds
        ..clear()
        ..addAll(selectedAssetIds);
    });
  }

  void _replaceCustomSelection(Set<String> selectedAssetIds) {
    setState(() {
      _customSelectedAssetIds
        ..clear()
        ..addAll(selectedAssetIds);
    });
  }

  void _deleteAsset(MediaAsset asset) {
    setState(() {
      _assets.removeWhere((item) => item.id == asset.id);
      _moduleAssets.removeWhere((item) => item.id == asset.id);
      _selectedAssetIds.remove(asset.id);
      _customSelectedAssetIds.remove(asset.id);
    });
  }

  void _deleteAssets(List<MediaAsset> assets) {
    final ids = assets.map((asset) => asset.id).toSet();
    setState(() {
      _assets.removeWhere((asset) => ids.contains(asset.id));
      _moduleAssets.removeWhere((asset) => ids.contains(asset.id));
      _selectedAssetIds.removeAll(ids);
      _customSelectedAssetIds.removeAll(ids);
    });
  }

  void _clearAll() {
    setState(() {
      _assets.clear();
      _moduleAssets.clear();
      _selectedAssetIds.clear();
      _customSelectedAssetIds.clear();
    });
  }

  void _addToModule(MediaAsset asset) {
    if (_moduleAssets.any((item) => item.id == asset.id)) {
      _showMessage('${asset.name} 已在其他模块中');
      return;
    }

    setState(() {
      _moduleAssets.add(asset);
    });
    _showMessage('已添加到其他模块：${asset.name}');
  }

  void _changeModuleHeight(double delta) {
    setState(() {
      _moduleHeight = (_moduleHeight + delta).clamp(180, 520);
    });
  }

  void _toggleModuleCollapsed() {
    setState(() {
      _moduleCollapsed = !_moduleCollapsed;
    });
  }

  String _fileName(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }

  String _rejectionLabel(RejectedMediaFileReason reason) {
    switch (reason) {
      case RejectedMediaFileReason.unsupportedType:
        return '不支持的文件类型';
      case RejectedMediaFileReason.imageTooLarge:
        return '图片超过大小限制';
      case RejectedMediaFileReason.videoTooLarge:
        return '视频超过大小限制';
      case RejectedMediaFileReason.missing:
        return '文件不存在';
      case RejectedMediaFileReason.unreadable:
        return '文件无法读取';
      case RejectedMediaFileReason.emptyFile:
        return '空文件';
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ExamplePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ExamplePanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReadOnlySummary extends StatelessWidget {
  final List<MediaAsset> assets;

  const _ReadOnlySummary({required this.assets});

  @override
  Widget build(BuildContext context) {
    final imageCount = assets
        .where((asset) => asset.type == MediaAssetType.image)
        .length;
    final videoCount = assets.length - imageCount;
    final totalBytes = assets.fold<int>(
      0,
      (sum, asset) => sum + asset.fileSize,
    );

    return _ExamplePanel(
      title: '接入侧摘要',
      subtitle: '组件外部仍然完全掌控数据',
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.image_outlined,
            label: '图片',
            value: '$imageCount',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.videocam_outlined,
            label: '视频',
            value: '$videoCount',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.storage_outlined,
            label: '总大小',
            value: _formatBytes(totalBytes),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CustomToolbar extends StatelessWidget {
  final MediaAssetToolbarState state;
  final VoidCallback onClearSelection;

  const _CustomToolbar({required this.state, required this.onClearSelection});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.collections_bookmark_outlined,
              size: 17,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${state.title} · ${state.assetCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (state.selectedCount > 0) ...[
            Text(
              '已选 ${state.selectedCount}',
              style: TextStyle(color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '清空选择',
              onPressed: onClearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomSelectionBadge extends StatelessWidget {
  final bool selected;

  const _CustomSelectionBadge({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? colorScheme.primary : colorScheme.outline,
        ),
      ),
      child: Icon(
        selected ? Icons.check_rounded : Icons.add_rounded,
        size: 14,
        color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CustomDragFeedback extends StatelessWidget {
  final MediaAsset asset;

  const _CustomDragFeedback({required this.asset});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              asset.type == MediaAssetType.video
                  ? Icons.movie_creation_outlined
                  : Icons.image_outlined,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                asset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomAssetTile extends StatelessWidget {
  final MediaAsset asset;
  final MediaAssetTileState state;

  const _CustomAssetTile({required this.asset, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVideo = asset.type == MediaAssetType.video;

    return Container(
      width: state.tileExtent,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isVideo
                  ? colorScheme.secondaryContainer
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVideo ? Icons.play_arrow_rounded : Icons.image_outlined,
              color: isVideo
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${asset.extensionLabel} · ${_formatBytes(asset.fileSize)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final text = value >= 10 || unitIndex == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text ${units[unitIndex]}';
}

class _ModuleDropTarget extends StatelessWidget {
  final List<MediaAsset> assets;
  final double height;
  final bool isCollapsed;
  final ValueChanged<MediaAsset> onAcceptAsset;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onToggleCollapsed;

  const _ModuleDropTarget({
    required this.assets,
    required this.height,
    required this.isCollapsed,
    required this.onAcceptAsset,
    required this.onHeightChanged,
    required this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: isCollapsed ? 32 : height,
      child: DragTarget<MediaAsset>(
        onAcceptWithDetails: (details) => onAcceptAsset(details.data),
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primaryContainer.withValues(alpha: 0.42)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '三视图',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _ModuleHeaderButton(
                          icon: Icons.add_rounded,
                          tooltip: '导入素材',
                          onTap: null,
                        ),
                        const SizedBox(width: 6),
                        _ModuleHeaderButton(
                          icon: isCollapsed
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          tooltip: isCollapsed ? '展开模块' : '折叠模块',
                          onTap: onToggleCollapsed,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 12),
                  if (assets.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          '拖入素材',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: assets.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final asset = assets[index];
                          return Row(
                            children: [
                              Icon(
                                asset.type == MediaAssetType.video
                                    ? Icons.videocam_outlined
                                    : Icons.image_outlined,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  asset.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  _ResizeHandle(onDragDelta: onHeightChanged),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModuleHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ModuleHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: onTap == null
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final ValueChanged<double> onDragDelta;

  const _ResizeHandle({required this.onDragDelta});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) => onDragDelta(details.delta.dy),
        child: SizedBox(
          height: 16,
          child: Center(
            child: Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
