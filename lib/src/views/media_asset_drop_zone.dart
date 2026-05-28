import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../theme/media_asset_theme.dart';

class MediaAssetDropZone extends StatefulWidget {
  final MediaAssetLibraryConfig config;
  final bool enabled;
  final bool hasAssets;
  final Widget child;
  final ValueChanged<List<XFile>>? onFilesDropped;
  final VoidCallback? onAddPressed;

  const MediaAssetDropZone({
    super.key,
    required this.config,
    required this.enabled,
    required this.hasAssets,
    required this.child,
    this.onFilesDropped,
    this.onAddPressed,
  });

  @override
  State<MediaAssetDropZone> createState() => _MediaAssetDropZoneState();
}

class _MediaAssetDropZoneState extends State<MediaAssetDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        widget.onFilesDropped?.call(details.files);
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: _DropOverlay(
                  title: widget.config.dropActiveTitle,
                  compact: widget.hasAssets,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MediaAssetEmptyDropZone extends StatelessWidget {
  final MediaAssetLibraryConfig config;
  final bool isActive;
  final VoidCallback? onAddPressed;

  const MediaAssetEmptyDropZone({
    super.key,
    required this.config,
    required this.isActive,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: isActive
            ? theme.primary(context).withValues(alpha: 0.08)
            : theme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? theme.primary(context) : theme.border(context),
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.primary(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.perm_media_outlined,
              size: 25,
              color: theme.primary(context),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isActive ? config.dropActiveTitle : config.emptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.emptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: theme.mutedText(context),
            ),
          ),
          if (onAddPressed != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: const Text('导入素材'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  final String title;
  final bool compact;

  const _DropOverlay({required this.title, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.primary(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary(context), width: 1.4),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 9 : 12,
          ),
          decoration: BoxDecoration(
            color: theme.surface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border(context)),
            boxShadow: theme.shadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.file_download_outlined, color: theme.primary(context)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.text(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
