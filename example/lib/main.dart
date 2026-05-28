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
  final Set<String> _selectedAssetIds = {};

  static const _config = MediaAssetLibraryConfig(
    fileTypes: MediaAssetFileTypeConfig(
      imageExtensions: {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'},
      videoExtensions: {'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'},
      maxImageFileSize: 30 * 1024 * 1024,
      maxVideoFileSize: 1024 * 1024 * 1024,
    ),
    emptyTitle: '拖入图片或视频文件',
    emptyDescription: '示例不会复制文件，只把本地路径转换成 MediaAsset 用于预览。',
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
            child: MediaAssetLibrary(
              title: '示例素材库',
              assets: _assets,
              selectedAssetIds: _selectedAssetIds,
              onSelectionChanged: _replaceSelection,
              onImportFiles: _handleImportFiles,
              onRejectedFiles: _handleRejectedFiles,
              onDeleteAsset: _deleteAsset,
              onDeleteSelectedAssets: _deleteAssets,
              onDownloadAsset: (asset) {
                _showMessage('下载回调：${asset.name}');
              },
              onDownloadSelectedAssets: (assets) {
                _showMessage('下载回调：${assets.length} 个素材');
              },
              onAddPressed: () {
                _showMessage('请把图片或视频文件拖到素材库区域');
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleImportFiles(List<String> paths) async {
    final now = DateTime.now();
    final imported = paths.map((path) {
      final file = File(path);
      final name = _fileName(path);
      final type = _typeForPath(path);

      return MediaAsset(
        id: '${now.microsecondsSinceEpoch}-${file.path}',
        name: name,
        filePath: path,
        type: type,
        fileSize: file.existsSync() ? file.lengthSync() : 0,
        createdAt: now,
      );
    }).toList();

    setState(() {
      _assets.addAll(imported);
    });

    _showMessage('已导入 ${imported.length} 个素材');
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
      _selectedAssetIds.remove(asset.id);
    });
  }

  void _deleteAssets(List<MediaAsset> assets) {
    final ids = assets.map((asset) => asset.id).toSet();
    setState(() {
      _assets.removeWhere((asset) => ids.contains(asset.id));
      _selectedAssetIds.removeAll(ids);
    });
  }

  void _clearAll() {
    setState(() {
      _assets.clear();
      _selectedAssetIds.clear();
    });
  }

  MediaAssetType _typeForPath(String path) {
    final extension = _extension(path);
    const videoExtensions = {'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'};
    return videoExtensions.contains(extension)
        ? MediaAssetType.video
        : MediaAssetType.image;
  }

  String _fileName(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }

  String _extension(String path) {
    final name = _fileName(path);
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return '';
    }
    return name.substring(dotIndex + 1).toLowerCase();
  }

  String _rejectionLabel(RejectedMediaFileReason reason) {
    switch (reason) {
      case RejectedMediaFileReason.unsupportedType:
        return '不支持的文件类型';
      case RejectedMediaFileReason.imageTooLarge:
        return '图片超过大小限制';
      case RejectedMediaFileReason.videoTooLarge:
        return '视频超过大小限制';
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
