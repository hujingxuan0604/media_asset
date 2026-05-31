import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';
import 'media_asset_context_menu.dart';
import 'media_asset_tile_preview.dart';

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

typedef MediaAssetSelectionBadgeBuilder =
    Widget Function(
      BuildContext context,
      MediaAsset asset,
      MediaAssetTileState state,
    );

typedef MediaAssetTileDragFeedbackBuilder =
    Widget Function(
      BuildContext context,
      MediaAsset asset,
      MediaAssetTileState state,
    );

class MediaAssetTileState {
  final bool isBatchSelected;
  final int duplicateHighlightToken;
  final double? tileExtent;
  final MediaAssetLibraryConfig config;

  const MediaAssetTileState({
    required this.isBatchSelected,
    required this.config,
    this.duplicateHighlightToken = 0,
    this.tileExtent,
  });
}

class MediaAssetTile extends StatefulWidget {
  final MediaAsset asset;
  final MediaAssetTileState state;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onDelete;
  final VoidCallback? onRevealInFolder;
  final MediaAssetMenuBuilder? menuBuilder;
  final MediaAssetSelectionBadgeBuilder? selectionBadgeBuilder;
  final MediaAssetTileDragFeedbackBuilder? dragFeedbackBuilder;
  final bool enableAssetDragging;

  const MediaAssetTile({
    super.key,
    required this.asset,
    required this.state,
    required this.onTap,
    required this.onDoubleTap,
    this.onToggleSelection,
    this.onDelete,
    this.onRevealInFolder,
    this.menuBuilder,
    this.selectionBadgeBuilder,
    this.dragFeedbackBuilder,
    this.enableAssetDragging = false,
  });

  @override
  State<MediaAssetTile> createState() => _MediaAssetTileState();
}

class _MediaAssetTileState extends State<MediaAssetTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _duplicateHighlightController;
  Timer? _hideDeleteTimer;
  bool _isPreviewHovering = false;
  bool _isDeleteHovering = false;

  bool get _showDeleteButton =>
      widget.onDelete != null && (_isPreviewHovering || _isDeleteHovering);

  @override
  void initState() {
    super.initState();
    _duplicateHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.state.duplicateHighlightToken > 0) {
      _startDuplicateHighlight();
    }
  }

  @override
  void didUpdateWidget(MediaAssetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.duplicateHighlightToken > 0 &&
        widget.state.duplicateHighlightToken !=
            oldWidget.state.duplicateHighlightToken) {
      _startDuplicateHighlight();
    }
  }

  @override
  void dispose() {
    _duplicateHighlightController.dispose();
    _hideDeleteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final canShowMenu = widget.state.config.interaction.enableContextMenu;

    return AnimatedBuilder(
      animation: _duplicateHighlightController,
      builder: (context, child) {
        final baseBorderColor = theme.border(context);
        final pulse = _duplicateHighlightPulse;
        final borderColor = Color.lerp(
          baseBorderColor,
          theme.primary(context),
          pulse,
        )!;
        final borderWidth = 1.0 + pulse * 2.2;
        final layout = widget.state.config.layout;
        final tileBody = _buildTileBody(
          context: context,
          layout: layout,
          borderColor: borderColor,
          borderWidth: borderWidth,
          pulse: pulse,
          theme: theme,
          canShowMenu: canShowMenu,
        );

        return SizedBox(
          width: widget.state.tileExtent ?? layout.tileWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.enableAssetDragging
                  ? Draggable<MediaAsset>(
                      data: widget.asset,
                      feedback:
                          widget.dragFeedbackBuilder?.call(
                            context,
                            widget.asset,
                            widget.state,
                          ) ??
                          _MediaAssetDragFeedback(
                            asset: widget.asset,
                            state: widget.state,
                          ),
                      childWhenDragging: tileBody,
                      child: tileBody,
                    )
                  : tileBody,
              if (_showDeleteButton)
                Positioned(
                  top: -5,
                  right: -5,
                  child: MouseRegion(
                    onEnter: (_) => _handleDeleteHoverChanged(true),
                    onExit: (_) => _handleDeleteHoverChanged(false),
                    child: _FloatingActionBadge(
                      icon: Icons.close_rounded,
                      tooltip: widget.state.config.text.deleteAssetTooltip,
                      onTap: widget.onDelete,
                      size: 22,
                      iconSize: 14,
                    ),
                  ),
                ),
              if (widget.onToggleSelection != null)
                Positioned(
                  top: layout.tilePadding.top + 5,
                  right: layout.tilePadding.right + 5,
                  child: _SelectionBadgeHitTarget(
                    selected: widget.state.isBatchSelected,
                    onTap: widget.onToggleSelection,
                    child:
                        widget.selectionBadgeBuilder?.call(
                          context,
                          widget.asset,
                          widget.state,
                        ) ??
                        _DefaultSelectionBadge(
                          selected: widget.state.isBatchSelected,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTileBody({
    required BuildContext context,
    required MediaAssetLayoutConfig layout,
    required Color borderColor,
    required double borderWidth,
    required double pulse,
    required MediaAssetThemeData theme,
    required bool canShowMenu,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTapDown: canShowMenu
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        borderRadius: theme.borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: layout.tilePadding,
          decoration: BoxDecoration(
            color: theme.elevatedSurface(context),
            borderRadius: theme.borderRadius,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: pulse > 0
                ? [
                    BoxShadow(
                      color: theme
                          .primary(context)
                          .withValues(alpha: 0.26 * pulse),
                      blurRadius: 14 * pulse,
                      spreadRadius: 1.6 * pulse,
                    ),
                  ]
                : null,
          ),
          child: _buildGridContent(layout),
        ),
      ),
    );
  }

  Widget _buildGridContent(MediaAssetLayoutConfig layout) {
    return MouseRegion(
      onEnter: (_) => _handlePreviewHoverChanged(true),
      onExit: (_) => _handlePreviewHoverChanged(false),
      child: MediaAssetTilePreview(
        asset: widget.asset,
        height: layout.tilePreviewHeight,
        showMetadata: _isPreviewHovering,
      ),
    );
  }

  double get _duplicateHighlightPulse {
    final value = _duplicateHighlightController.value;
    return (1 - math.cos(value * math.pi * 6)) / 2;
  }

  void _startDuplicateHighlight() {
    _duplicateHighlightController.forward(from: 0);
  }

  void _handlePreviewHoverChanged(bool isHovering) {
    if (isHovering) {
      _hideDeleteTimer?.cancel();
      if (!_isPreviewHovering) {
        setState(() => _isPreviewHovering = true);
      }
      return;
    }

    _isPreviewHovering = false;
    _scheduleDeleteButtonHide();
  }

  void _handleDeleteHoverChanged(bool isHovering) {
    if (isHovering) {
      _hideDeleteTimer?.cancel();
      if (!_isDeleteHovering) {
        setState(() => _isDeleteHovering = true);
      }
      return;
    }

    _isDeleteHovering = false;
    _scheduleDeleteButtonHide();
  }

  void _scheduleDeleteButtonHide() {
    _hideDeleteTimer?.cancel();
    _hideDeleteTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _isPreviewHovering || _isDeleteHovering) {
        return;
      }
      setState(() {});
    });
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
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
        final controller = MediaAssetMenuController(
          position: position,
          canPreview: widget.onDoubleTap != null,
          canSelect: widget.onToggleSelection != null,
          canRevealInFolder: widget.onRevealInFolder != null,
          canDelete: widget.onDelete != null,
          onClose: () => navigator.pop(),
          onAction: (action) {
            navigator.pop();
            _handleMenuAction(context, action);
          },
        );
        final menu =
            widget.menuBuilder?.call(
              dialogContext,
              widget.asset,
              widget.state,
              controller,
            ) ??
            DefaultMediaAssetContextMenu(
              isBatchSelected: widget.state.isBatchSelected,
              controller: controller,
              config: widget.state.config,
            );

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Material(type: MaterialType.transparency, child: menu),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, MediaAssetAction action) {
    switch (action) {
      case MediaAssetAction.preview:
        widget.onDoubleTap?.call();
        break;
      case MediaAssetAction.select:
        widget.onToggleSelection?.call();
        break;
      case MediaAssetAction.revealInFolder:
        widget.onRevealInFolder?.call();
        break;
      case MediaAssetAction.delete:
        widget.onDelete?.call();
        break;
    }
  }
}

class _FloatingActionBadge extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const _FloatingActionBadge({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 24,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: onTap == null ? null : (_) => onTap!(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: theme.surface(context),
              shape: BoxShape.circle,
              border: Border.all(color: theme.border(context)),
              boxShadow: theme.shadow,
            ),
            child: Icon(icon, size: iconSize, color: theme.mutedText(context)),
          ),
        ),
      ),
    );
  }
}

class _SelectionBadgeHitTarget extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  const _SelectionBadgeHitTarget({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '取消选择' : '选择',
      child: MouseRegion(
        opaque: true,
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: onTap == null ? null : (_) => onTap!(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DefaultSelectionBadge extends StatelessWidget {
  final bool selected;

  const _DefaultSelectionBadge({required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected
            ? theme.primary(context)
            : Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Icon(
        selected ? Icons.check_rounded : Icons.add_rounded,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

class _MediaAssetDragFeedback extends StatelessWidget {
  final MediaAsset asset;
  final MediaAssetTileState state;

  const _MediaAssetDragFeedback({required this.asset, required this.state});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Transform.scale(
        scale: 0.98,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: MediaAssetTile(
            asset: asset,
            state: state,
            onTap: () {},
            onDoubleTap: () {},
          ),
        ),
      ),
    );
  }
}
