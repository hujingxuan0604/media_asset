import 'dart:io';

import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../services/media_file_size_formatter.dart';
import '../theme/media_asset_theme.dart';

typedef MediaAssetTileBuilder =
    Widget Function(
      BuildContext context,
      MediaAsset asset,
      MediaAssetTileState state,
    );

typedef MediaAssetMenuBuilder =
    Widget Function(
      BuildContext context,
      MediaAsset asset,
      MediaAssetTileState state,
      MediaAssetMenuController controller,
    );

class MediaAssetMenuController {
  final Offset position;
  final bool canSelect;
  final bool canDownload;
  final bool canDelete;
  final VoidCallback _onClose;
  final ValueChanged<MediaAssetAction> _onAction;

  const MediaAssetMenuController._({
    required this.position,
    required this.canSelect,
    required this.canDownload,
    required this.canDelete,
    required VoidCallback onClose,
    required ValueChanged<MediaAssetAction> onAction,
  }) : _onClose = onClose,
       _onAction = onAction;

  void close() => _onClose();

  void preview() => _onAction(MediaAssetAction.preview);

  void select() {
    if (canSelect) {
      _onAction(MediaAssetAction.select);
    }
  }

  void download() {
    if (canDownload) {
      _onAction(MediaAssetAction.download);
    }
  }

  void delete() {
    if (canDelete) {
      _onAction(MediaAssetAction.delete);
    }
  }

  void perform(MediaAssetAction action) {
    switch (action) {
      case MediaAssetAction.preview:
        preview();
        break;
      case MediaAssetAction.select:
        select();
        break;
      case MediaAssetAction.download:
        download();
        break;
      case MediaAssetAction.delete:
        delete();
        break;
    }
  }
}

class MediaAssetTileState {
  final bool isSelected;
  final bool isBatchSelected;
  final MediaAssetLibraryConfig config;

  const MediaAssetTileState({
    required this.isSelected,
    required this.isBatchSelected,
    required this.config,
  });
}

class MediaAssetTile extends StatelessWidget {
  final MediaAsset asset;
  final MediaAssetTileState state;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final MediaAssetMenuBuilder? menuBuilder;

  const MediaAssetTile({
    super.key,
    required this.asset,
    required this.state,
    required this.onTap,
    required this.onDoubleTap,
    this.onToggleSelection,
    this.onDelete,
    this.onDownload,
    this.menuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final highlight = state.isSelected || state.isBatchSelected;
    final canShowMenu = state.config.enableContextMenu && menuBuilder != null;

    return SizedBox(
      width: state.config.tileWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onSecondaryTapDown: canShowMenu
                  ? (details) =>
                        _showContextMenu(context, details.globalPosition)
                  : null,
              borderRadius: theme.borderRadius,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: highlight
                      ? theme.primary(context).withValues(alpha: 0.08)
                      : theme.elevatedSurface(context),
                  borderRadius: theme.borderRadius,
                  border: Border.all(
                    color: highlight
                        ? theme.primary(context)
                        : theme.border(context),
                    width: highlight ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AssetPreviewFrame(
                      asset: asset,
                      height: state.config.tilePreviewHeight,
                      selected: state.isBatchSelected,
                      onToggleSelection: state.config.enableMultiSelection
                          ? onToggleSelection
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      const MediaFileSizeFormatter().format(asset.fileSize),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: -6,
              right: -6,
              child: _FloatingActionBadge(
                icon: Icons.close_rounded,
                tooltip: '删除素材',
                onTap: onDelete,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final builder = menuBuilder;
    if (builder == null) {
      return;
    }

    final barrierLabel = MaterialLocalizations.of(
      context,
    ).modalBarrierDismissLabel;

    await showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final navigator = Navigator.of(dialogContext);
        final controller = MediaAssetMenuController._(
          position: position,
          canSelect: onToggleSelection != null,
          canDownload: onDownload != null,
          canDelete: onDelete != null,
          onClose: () => navigator.pop(),
          onAction: (action) {
            navigator.pop();
            _handleMenuAction(action);
          },
        );

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Material(
                type: MaterialType.transparency,
                child: builder(dialogContext, asset, state, controller),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(MediaAssetAction action) {
    switch (action) {
      case MediaAssetAction.preview:
        onDoubleTap();
        break;
      case MediaAssetAction.select:
        onToggleSelection?.call();
        break;
      case MediaAssetAction.download:
        onDownload?.call();
        break;
      case MediaAssetAction.delete:
        onDelete?.call();
        break;
    }
  }
}

class _AssetPreviewFrame extends StatelessWidget {
  final MediaAsset asset;
  final double height;
  final bool selected;
  final VoidCallback? onToggleSelection;

  const _AssetPreviewFrame({
    required this.asset,
    required this.height,
    required this.selected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.surface(context),
            borderRadius: BorderRadius.circular(7),
          ),
          child: asset.type == MediaAssetType.image
              ? _ImageThumb(asset: asset)
              : _VideoThumb(asset: asset),
        ),
        if (asset.type == MediaAssetType.video)
          Positioned(
            left: 6,
            top: 6,
            child: _TypeBadge(label: asset.type.label),
          ),
        if (onToggleSelection != null)
          Positioned(
            top: 5,
            right: 5,
            child: _SelectionBadge(
              selected: selected,
              onTap: onToggleSelection,
            ),
          ),
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final MediaAsset asset;

  const _ImageThumb({required this.asset});

  @override
  Widget build(BuildContext context) {
    final sourcePath = asset.thumbnailPath ?? asset.filePath;
    final file = File(sourcePath);
    if (!file.existsSync()) {
      return const _BrokenPreview(icon: Icons.broken_image_outlined);
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return const _BrokenPreview(icon: Icons.broken_image_outlined);
      },
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final MediaAsset asset;

  const _VideoThumb({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final thumbnailPath = asset.thumbnailPath;

    if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
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
            child: _TypeBadge(label: asset.extensionLabel),
          ),
        ],
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const _SelectionBadge({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '取消选择' : '选择',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: selected
                ? MediaAssetTheme.of(context).primary(context)
                : Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            selected ? Icons.check_rounded : Icons.add_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FloatingActionBadge extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _FloatingActionBadge({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.surface(context),
              shape: BoxShape.circle,
              border: Border.all(color: theme.border(context)),
              boxShadow: theme.shadow,
            ),
            child: Icon(icon, size: 14, color: theme.mutedText(context)),
          ),
        ),
      ),
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
