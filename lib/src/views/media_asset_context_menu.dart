import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';

class MediaAssetMenuController {
  final Offset position;
  final bool canPreview;
  final bool canSelect;
  final bool canRevealInFolder;
  final bool canCopyPath;
  final bool canDelete;
  final VoidCallback _onClose;
  final ValueChanged<MediaAssetAction> _onAction;

  const MediaAssetMenuController({
    required this.position,
    required this.canPreview,
    required this.canSelect,
    required this.canRevealInFolder,
    required this.canCopyPath,
    required this.canDelete,
    required VoidCallback onClose,
    required ValueChanged<MediaAssetAction> onAction,
  }) : _onClose = onClose,
       _onAction = onAction;

  void close() => _onClose();

  void preview() {
    if (canPreview) {
      _onAction(MediaAssetAction.preview);
    }
  }

  void select() {
    if (canSelect) {
      _onAction(MediaAssetAction.select);
    }
  }

  void revealInFolder() {
    if (canRevealInFolder) {
      _onAction(MediaAssetAction.revealInFolder);
    }
  }

  void copyPath() {
    if (canCopyPath) {
      _onAction(MediaAssetAction.copyPath);
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
      case MediaAssetAction.revealInFolder:
        revealInFolder();
        break;
      case MediaAssetAction.copyPath:
        copyPath();
        break;
      case MediaAssetAction.delete:
        delete();
        break;
    }
  }
}

class DefaultMediaAssetContextMenu extends StatelessWidget {
  final bool isBatchSelected;
  final MediaAssetMenuController controller;
  final MediaAssetLibraryConfig config;

  const DefaultMediaAssetContextMenu({
    super.key,
    required this.isBatchSelected,
    required this.controller,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.elevatedSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border(context)),
          boxShadow: theme.shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.canPreview)
                _DefaultMenuItem(
                  icon: Icons.visibility_outlined,
                  label: config.text.previewActionLabel,
                  onTap: controller.preview,
                ),
              if (controller.canSelect)
                _DefaultMenuItem(
                  icon: isBatchSelected
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank_outlined,
                  label: isBatchSelected
                      ? config.text.cancelSelectActionLabel
                      : config.text.selectActionLabel,
                  onTap: controller.select,
                ),
              if (controller.canRevealInFolder)
                _DefaultMenuItem(
                  icon: Icons.folder_open_outlined,
                  label: config.text.revealInFolderActionLabel,
                  onTap: controller.revealInFolder,
                ),
              if (controller.canCopyPath)
                _DefaultMenuItem(
                  icon: Icons.content_copy_outlined,
                  label: config.text.copyPathActionLabel,
                  onTap: controller.copyPath,
                ),
              if (controller.canDelete) ...[
                const SizedBox(height: 5),
                Divider(height: 1, color: theme.border(context)),
                const SizedBox(height: 5),
                _DefaultMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: config.text.deleteActionLabel,
                  color: theme.danger(context),
                  onTap: controller.delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DefaultMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final foreground = color ?? theme.text(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
