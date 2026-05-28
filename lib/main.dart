import 'package:flutter/material.dart';
import 'package:media_asset/media_asset.dart';

void main() {
  runApp(const MediaAssetDemoApp());
}

class MediaAssetDemoApp extends StatefulWidget {
  const MediaAssetDemoApp({super.key});

  @override
  State<MediaAssetDemoApp> createState() => _MediaAssetDemoAppState();
}

class _MediaAssetDemoAppState extends State<MediaAssetDemoApp> {
  final Set<String> _selectedAssetIds = {};
  final List<MediaAsset> _assets = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Asset Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Media Asset Demo')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: MediaAssetLibrary(
            assets: _assets,
            selectedAssetIds: _selectedAssetIds,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedAssetIds
                  ..clear()
                  ..addAll(ids);
              });
            },
            onImportFiles: (paths) async {
              final now = DateTime.now();
              setState(() {
                _assets.addAll(
                  paths.map((path) {
                    final name = path.split(RegExp(r'[/\\]')).last;
                    final lowerPath = path.toLowerCase();
                    final type =
                        const [
                          '.mp4',
                          '.mov',
                          '.m4v',
                          '.webm',
                          '.mkv',
                          '.avi',
                        ].any(lowerPath.endsWith)
                        ? MediaAssetType.video
                        : MediaAssetType.image;
                    return MediaAsset(
                      id: '${now.microsecondsSinceEpoch}-$path',
                      name: name,
                      filePath: path,
                      type: type,
                      fileSize: 0,
                      createdAt: now,
                    );
                  }),
                );
              });
            },
            onDeleteAsset: (asset) {
              setState(() {
                _assets.removeWhere((item) => item.id == asset.id);
                _selectedAssetIds.remove(asset.id);
              });
            },
            onDeleteSelectedAssets: (assets) {
              final ids = assets.map((asset) => asset.id).toSet();
              setState(() {
                _assets.removeWhere((asset) => ids.contains(asset.id));
                _selectedAssetIds.removeAll(ids);
              });
            },
          ),
        ),
      ),
    );
  }
}
