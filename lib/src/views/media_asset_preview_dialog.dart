import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/media_asset_config.dart';
import '../controllers/media_asset_preview_controller.dart';
import '../models/media_asset_models.dart';
import '../services/media_file_size_formatter.dart';
import '../theme/media_asset_theme.dart';
import 'image_asset_preview.dart';
import 'video_asset_preview.dart';

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

  @override
  State<MediaAssetPreviewDialog> createState() =>
      _MediaAssetPreviewDialogState();
}

class _MediaAssetPreviewDialogState extends State<MediaAssetPreviewDialog> {
  late final MediaAssetPreviewController _controller;
  late final TransformationController _transformationController;
  late final FocusNode _focusNode;
  final GlobalKey<VideoAssetPreviewState> _videoKey =
      GlobalKey<VideoAssetPreviewState>();

  MediaAssetLibraryConfig get _config {
    return widget.config ?? MediaAssetLibraryScope.of(context);
  }

  @override
  void initState() {
    super.initState();
    _controller = MediaAssetPreviewController(
      assets: widget.assets,
      initialAsset: widget.asset,
    );
    _transformationController = TransformationController();
    _focusNode = FocusNode(debugLabel: 'media_asset_preview_dialog');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(MediaAssetPreviewDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id ||
        oldWidget.assets.length != widget.assets.length) {
      _controller.replaceAssets(widget.assets, widget.asset);
      _resetImageView();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _transformationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openAt(int index) {
    _controller.openAt(index);
    _resetImageView();
  }

  void _zoomBy(double factor) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor)
        .clamp(
          MediaAssetPreviewController.minScale,
          MediaAssetPreviewController.maxScale,
        )
        .toDouble();
    final scaleRatio = nextScale / currentScale;
    final nextMatrix = _transformationController.value.clone()
      ..scaleByDouble(scaleRatio, scaleRatio, 1, 1);
    _transformationController.value = nextMatrix;
    _controller.zoomBy(factor);
  }

  void _resetImageView() {
    _transformationController.value = Matrix4.identity();
    _controller.resetZoom();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }

    final key = event.logicalKey;
    final asset = _controller.currentAsset;
    final imageShortcuts = _config.imageShortcuts;
    final videoShortcuts = _config.videoShortcuts;
    final closeKeys = asset.type == MediaAssetType.image
        ? imageShortcuts.closeKeys
        : videoShortcuts.closeKeys;

    if (closeKeys.contains(key)) {
      Navigator.of(context).pop();
      return;
    }

    if (asset.type == MediaAssetType.image) {
      if (imageShortcuts.zoomInKeys.contains(key)) {
        _zoomBy(1.25);
        return;
      }
      if (imageShortcuts.zoomOutKeys.contains(key)) {
        _zoomBy(0.8);
        return;
      }
      if (imageShortcuts.resetZoomKeys.contains(key)) {
        _resetImageView();
        return;
      }
      if (_config.enablePreviewNavigation &&
          imageShortcuts.previousKeys.contains(key)) {
        _openAt(_controller.currentIndex - 1);
        return;
      }
      if (_config.enablePreviewNavigation &&
          imageShortcuts.nextKeys.contains(key)) {
        _openAt(_controller.currentIndex + 1);
        return;
      }
    }

    if (asset.type == MediaAssetType.video) {
      if (videoShortcuts.playPauseKeys.contains(key)) {
        _videoKey.currentState?.togglePlayback();
        return;
      }
      if (videoShortcuts.seekBackwardKeys.contains(key)) {
        _videoKey.currentState?.seekBy(-videoShortcuts.seekStep);
        return;
      }
      if (videoShortcuts.seekForwardKeys.contains(key)) {
        _videoKey.currentState?.seekBy(videoShortcuts.seekStep);
        return;
      }
      if (_config.enablePreviewNavigation &&
          videoShortcuts.previousKeys.contains(key)) {
        _openAt(_controller.currentIndex - 1);
        return;
      }
      if (_config.enablePreviewNavigation &&
          videoShortcuts.nextKeys.contains(key)) {
        _openAt(_controller.currentIndex + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        insetPadding: const EdgeInsets.all(28),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
          decoration: BoxDecoration(
            color: theme.surface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border(context)),
            boxShadow: theme.shadow,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final asset = _controller.currentAsset;
              return Column(
                children: [
                  _buildHeader(context, asset),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: _buildPreviewArea(context, asset),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MediaAsset asset) {
    final theme = MediaAssetTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                _PreviewHeaderMeta(
                  asset: asset,
                  index: _controller.currentIndex + 1,
                  count: _controller.count,
                  imageScale: asset.type == MediaAssetType.image
                      ? _controller.imageScale
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (asset.type == MediaAssetType.image) ...[
            _PreviewActionButton(
              icon: Icons.remove,
              tooltip: '缩小',
              onTap: () => _zoomBy(0.8),
            ),
            const SizedBox(width: 6),
            _PreviewActionButton(
              icon: Icons.add,
              tooltip: '放大',
              onTap: () => _zoomBy(1.25),
            ),
            const SizedBox(width: 6),
            _PreviewActionButton(
              icon: Icons.center_focus_strong,
              tooltip: '重置',
              onTap: _resetImageView,
            ),
          ],
          const SizedBox(width: 6),
          _PreviewActionButton(
            icon: Icons.close,
            tooltip: '关闭',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context, MediaAsset asset) {
    return Stack(
      children: [
        Positioned.fill(
          child: asset.type == MediaAssetType.image
              ? ImageAssetPreview(
                  asset: asset,
                  transformationController: _transformationController,
                  minScale: MediaAssetPreviewController.minScale,
                  maxScale: MediaAssetPreviewController.maxScale,
                )
              : VideoAssetPreview(
                  key: _videoKey,
                  asset: asset,
                  seekStep: _config.videoShortcuts.seekStep,
                ),
        ),
        if (_config.enablePreviewNavigation && _controller.canNavigate) ...[
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: _PreviewNavigationButton(
                icon: Icons.chevron_left_rounded,
                tooltip: '上一个素材',
                onTap: () => _openAt(_controller.currentIndex - 1),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: _PreviewNavigationButton(
                icon: Icons.chevron_right_rounded,
                tooltip: '下一个素材',
                onTap: () => _openAt(_controller.currentIndex + 1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewHeaderMeta extends StatelessWidget {
  final MediaAsset asset;
  final int index;
  final int count;
  final double? imageScale;

  const _PreviewHeaderMeta({
    required this.asset,
    required this.index,
    required this.count,
    required this.imageScale,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[
      _PreviewMetaText(asset.type == MediaAssetType.video ? '视频预览' : '图片预览'),
      const _PreviewMetaDivider(),
      _PreviewMetaText(const MediaFileSizeFormatter().format(asset.fileSize)),
      const _PreviewMetaDivider(),
      _PreviewMetaText('$index/$count'),
    ];

    if (imageScale != null) {
      parts.addAll([
        const _PreviewMetaDivider(),
        _PreviewScaleBadge(scale: imageScale!),
      ]);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts,
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PreviewActionButton({
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
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.elevatedSurface(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.border(context)),
            ),
            child: Icon(icon, size: 16, color: theme.mutedText(context)),
          ),
        ),
      ),
    );
  }
}

class _PreviewNavigationButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PreviewNavigationButton({
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
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 64,
            decoration: BoxDecoration(
              color: theme.surface(context).withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.border(context)),
              boxShadow: theme.shadow,
            ),
            child: Icon(icon, size: 30, color: theme.text(context)),
          ),
        ),
      ),
    );
  }
}

class _PreviewMetaText extends StatelessWidget {
  final String text;

  const _PreviewMetaText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: MediaAssetTheme.of(context).mutedText(context),
      ),
    );
  }
}

class _PreviewMetaDivider extends StatelessWidget {
  const _PreviewMetaDivider();

  @override
  Widget build(BuildContext context) {
    return Text(
      '/',
      style: TextStyle(
        fontSize: 11,
        color: MediaAssetTheme.of(context).mutedText(context),
      ),
    );
  }
}

class _PreviewScaleBadge extends StatelessWidget {
  final double scale;

  const _PreviewScaleBadge({required this.scale});

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.primary(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${(scale * 100).round()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.primary(context),
        ),
      ),
    );
  }
}
