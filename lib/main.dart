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
            assets: const [],
            selectedAssetIds: _selectedAssetIds,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedAssetIds
                  ..clear()
                  ..addAll(ids);
              });
            },
          ),
        ),
      ),
    );
  }
}
