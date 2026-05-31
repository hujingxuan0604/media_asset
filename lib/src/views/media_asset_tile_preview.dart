import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_asset_models.dart';
import '../services/media_file_size_formatter.dart';
import '../theme/media_asset_theme.dart';

class MediaAssetTilePreview extends StatelessWidget {
  final MediaAsset asset;
  final double height;
  final bool showMetadata;

  const MediaAssetTilePreview({
    super.key,
    required this.asset,
    required this.height,
    required this.showMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: ColoredBox(
          color: theme.surface(context),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.antiAlias,
            children: [
              asset.type == MediaAssetType.image
                  ? _ImageThumb(asset: asset)
                  : _VideoThumb(asset: asset),
              if (asset.type == MediaAssetType.video)
                Positioned(
                  left: 6,
                  top: 6,
                  child: _TypeBadge(label: asset.type.label),
                ),
              if (showMetadata)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _AssetMetadataOverlay(asset: asset),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetMetadataOverlay extends StatelessWidget {
  final MediaAsset asset;

  const _AssetMetadataOverlay({required this.asset});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 12, 7, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              const MediaFileSizeFormatter().format(asset.fileSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatefulWidget {
  final MediaAsset asset;

  const _ImageThumb({required this.asset});

  @override
  State<_ImageThumb> createState() => _ImageThumbState();
}

class _ImageThumbState extends State<_ImageThumb> {
  late Future<bool> _fileExists;

  String get _sourcePath {
    return widget.asset.thumbnailPath ?? widget.asset.filePath;
  }

  @override
  void initState() {
    super.initState();
    _fileExists = File(_sourcePath).exists();
  }

  @override
  void didUpdateWidget(_ImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPath = oldWidget.asset.thumbnailPath ?? oldWidget.asset.filePath;
    if (oldPath != _sourcePath) {
      _fileExists = File(_sourcePath).exists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _fileExists,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingPreview();
        }
        if (snapshot.data != true) {
          return const _BrokenPreview(icon: Icons.broken_image_outlined);
        }

        return Image.file(
          File(_sourcePath),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return const _BrokenPreview(icon: Icons.broken_image_outlined);
          },
        );
      },
    );
  }
}

class _VideoThumb extends StatefulWidget {
  final MediaAsset asset;

  const _VideoThumb({required this.asset});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late Future<bool> _thumbnailExists;

  String? get _thumbnailPath => widget.asset.thumbnailPath;

  @override
  void initState() {
    super.initState();
    _thumbnailExists = _checkThumbnailExists();
  }

  @override
  void didUpdateWidget(_VideoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.thumbnailPath != widget.asset.thumbnailPath) {
      _thumbnailExists = _checkThumbnailExists();
    }
  }

  Future<bool> _checkThumbnailExists() {
    final thumbnailPath = _thumbnailPath;
    if (thumbnailPath == null) {
      return Future.value(false);
    }
    return File(thumbnailPath).exists();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return FutureBuilder<bool>(
      future: _thumbnailExists,
      builder: (context, snapshot) {
        final thumbnailPath = _thumbnailPath;
        if (thumbnailPath != null &&
            snapshot.connectionState != ConnectionState.done) {
          return const _LoadingPreview();
        }
        if (snapshot.data == true && thumbnailPath != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(thumbnailPath), fit: BoxFit.cover),
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white),
              ),
            ],
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primary(context).withValues(alpha: 0.18),
                theme.elevatedSurface(context),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: 32,
                color: theme.text(context),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: _TypeBadge(label: widget.asset.extensionLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;

  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LoadingPreview extends StatelessWidget {
  const _LoadingPreview();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: MediaAssetTheme.of(context).surface(context));
  }
}

class _BrokenPreview extends StatelessWidget {
  final IconData icon;

  const _BrokenPreview({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, color: MediaAssetTheme.of(context).mutedText(context)),
    );
  }
}
