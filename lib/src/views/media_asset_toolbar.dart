import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';

typedef MediaAssetToolbarBuilder =
    Widget Function(BuildContext context, MediaAssetToolbarState state);

class MediaAssetToolbarState {
  final String title;
  final List<MediaAsset> assets;
  final List<MediaAsset> selectedAssets;
  final bool allSelected;
  final MediaAssetLibraryConfig config;
  final bool isCollapsed;
  final bool isCollapsible;
  final VoidCallback? onAddPressed;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onToggleCollapsed;

  const MediaAssetToolbarState({
    required this.title,
    required this.assets,
    required this.selectedAssets,
    required this.allSelected,
    required this.config,
    this.isCollapsed = false,
    this.isCollapsible = false,
    this.onAddPressed,
    this.onSelectAll,
    this.onClearSelection,
    this.onDeleteSelected,
    this.onToggleCollapsed,
  });

  int get assetCount => assets.length;

  int get selectedCount => selectedAssets.length;
}

class MediaAssetToolbar extends StatelessWidget {
  final MediaAssetToolbarState state;

  const MediaAssetToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final config = state.config;
    final assetCount = state.assetCount;
    final selectedCount = state.selectedCount;
    final canSelect =
        config.interaction.enableMultiSelection &&
        config.interaction.isActionEnabled(MediaAssetAction.select) &&
        assetCount > 0;

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: _ToolbarTitleArea(
              title: state.title,
              tooltip: selectedCount > 0
                  ? '已选择 $selectedCount / $assetCount'
                  : '共 $assetCount 个素材',
              onTap: state.isCollapsible ? state.onToggleCollapsed : null,
            ),
          ),
          if (selectedCount > 0) ...[
            _ToolbarIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: config.text.deleteSelectedTooltip,
              onTap: state.onDeleteSelected,
              color: theme.danger(context),
            ),
            const SizedBox(width: 8),
          ],
          if (canSelect)
            _ToolbarIconButton(
              icon: state.allSelected
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank_outlined,
              tooltip: state.allSelected
                  ? config.text.clearSelectionTooltip
                  : config.text.selectAllTooltip,
              onTap: state.allSelected
                  ? state.onClearSelection
                  : state.onSelectAll,
            ),
          if (state.onAddPressed != null) ...[
            const SizedBox(width: 8),
            _ToolbarIconButton(
              icon: Icons.add_rounded,
              tooltip: config.text.importButtonLabel,
              onTap: state.onAddPressed,
              color: theme.primary(context),
            ),
          ],
          if (state.isCollapsible) ...[
            const SizedBox(width: 6),
            _ToolbarIconButton(
              icon: state.isCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              tooltip: state.isCollapsed ? '展开模块' : '折叠模块',
              onTap: state.onToggleCollapsed,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarTitleArea extends StatelessWidget {
  final String title;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarTitleArea({
    required this.title,
    required this.tooltip,
    this.onTap,
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
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.text(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
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
            child: Icon(
              icon,
              size: 17,
              color: onTap == null
                  ? theme.mutedText(context).withValues(alpha: 0.45)
                  : color ?? theme.mutedText(context),
            ),
          ),
        ),
      ),
    );
  }
}
