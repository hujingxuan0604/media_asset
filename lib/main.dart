import 'dart:io';

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
            onImportFiles: (candidates) async {
              final now = DateTime.now();
              setState(() {
                _assets.addAll(
                  candidates.map((candidate) {
                    return MediaAsset(
                      id: '${now.microsecondsSinceEpoch}-${candidate.path}',
                      name: candidate.name,
                      filePath: candidate.path,
                      type: candidate.type,
                      fileSize: candidate.fileSize,
                      contentHash: candidate.contentHash,
                      createdAt: now,
                    );
                  }),
                );
              });
            },
            onResolveImportSources: _resolveImportSources,
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

  Future<List<LocalMediaImportSource>> _resolveImportSources(
    List<LocalMediaImportSource> sources,
  ) async {
    final resolved = <LocalMediaImportSource>[];
    for (final source in sources) {
      if (source.contentHash != null || !source.exists || !source.isReadable) {
        resolved.add(source);
        continue;
      }

      try {
        final file = File(source.path);
        final stat = await file.stat();
        if (stat.type != FileSystemEntityType.file) {
          resolved.add(source);
          continue;
        }

        resolved.add(
          source.copyWith(
            fileSize: source.fileSize ?? stat.size,
            contentHash:
                '${file.absolute.path}|${stat.size}|${stat.modified.microsecondsSinceEpoch}',
          ),
        );
      } catch (_) {
        resolved.add(source);
      }
    }
    return resolved;
  }
}
