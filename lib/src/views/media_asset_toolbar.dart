import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';

class MediaAssetToolbar extends StatelessWidget {
  final String title;
  final int assetCount;
  final int selectedCount;
  final bool allSelected;
  final MediaAssetLibraryConfig config;
  final VoidCallback? onAddPressed;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCopySelectedPaths;
  final VoidCallback? onDeleteSelected;

  const MediaAssetToolbar({
    super.key,
    required this.title,
    required this.assetCount,
    required this.selectedCount,
    required this.allSelected,
    required this.config,
    this.onAddPressed,
    this.onSelectAll,
    this.onClearSelection,
    this.onCopySelectedPaths,
    this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final canSelect =
        config.interaction.enableMultiSelection &&
        config.interaction.isActionEnabled(MediaAssetAction.select) &&
        assetCount > 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.text(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                selectedCount > 0
                    ? '已选择 $selectedCount / $assetCount'
                    : '共 $assetCount 个素材',
                style: TextStyle(fontSize: 12, color: theme.mutedText(context)),
              ),
            ],
          ),
        ),
        if (selectedCount > 0) ...[
          _ToolbarIconButton(
            icon: Icons.content_copy_outlined,
            tooltip: config.text.copySelectedPathsTooltip,
            onTap: onCopySelectedPaths,
          ),
          const SizedBox(width: 8),
          _ToolbarIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: config.text.deleteSelectedTooltip,
            onTap: onDeleteSelected,
            color: theme.danger(context),
          ),
          const SizedBox(width: 8),
        ],
        if (canSelect)
          _ToolbarIconButton(
            icon: allSelected
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank_outlined,
            tooltip: allSelected
                ? config.text.clearSelectionTooltip
                : config.text.selectAllTooltip,
            onTap: allSelected ? onClearSelection : onSelectAll,
          ),
        if (onAddPressed != null) ...[
          const SizedBox(width: 8),
          _ToolbarIconButton(
            icon: Icons.add_photo_alternate_outlined,
            tooltip: config.text.importButtonLabel,
            onTap: onAddPressed,
            color: theme.primary(context),
          ),
        ],
      ],
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
