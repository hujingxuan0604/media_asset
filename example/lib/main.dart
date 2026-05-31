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
    return Scaffold(
      appBar: AppBar(
        title: const Text('media_asset example'),
        actions: [
          TextButton.icon(
            onPressed: _assets.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('清空'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: MediaAssetLibraryScope(
          config: _config,
          child: MediaAssetTheme(
            data: const MediaAssetThemeData(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final library = MediaAssetLibrary(
                  title: '示例素材库',
                  assets: _assets,
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
                  onAcceptAsset: _addToModule,
                );

                if (constraints.maxWidth < 820) {
                  return Column(
                    children: [
                      Expanded(child: library),
                      const SizedBox(height: 16),
                      SizedBox(height: 180, child: target),
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
            ),
          ),
        ),
      ),
    );
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

  void _deleteAsset(MediaAsset asset) {
    setState(() {
      _assets.removeWhere((item) => item.id == asset.id);
      _moduleAssets.removeWhere((item) => item.id == asset.id);
      _selectedAssetIds.remove(asset.id);
    });
  }

  void _deleteAssets(List<MediaAsset> assets) {
    final ids = assets.map((asset) => asset.id).toSet();
    setState(() {
      _assets.removeWhere((asset) => ids.contains(asset.id));
      _moduleAssets.removeWhere((asset) => ids.contains(asset.id));
      _selectedAssetIds.removeAll(ids);
    });
  }

  void _clearAll() {
    setState(() {
      _assets.clear();
      _moduleAssets.clear();
      _selectedAssetIds.clear();
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

class _ModuleDropTarget extends StatelessWidget {
  final List<MediaAsset> assets;
  final ValueChanged<MediaAsset> onAcceptAsset;

  const _ModuleDropTarget({required this.assets, required this.onAcceptAsset});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<MediaAsset>(
      onAcceptWithDetails: (details) => onAcceptAsset(details.data),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(14),
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
              Row(
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '其他模块',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
            ],
          ),
        );
      },
    );
  }
}
