import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import 'media_asset_tile.dart';

typedef MediaAssetDragFeedbackBuilder = MediaAssetTileDragFeedbackBuilder;

class MediaAssetGrid extends StatelessWidget {
  final List<MediaAsset> assets;
  final Set<String> selectedAssetIds;
  final Map<String, int> duplicateHighlightTokens;
  final MediaAssetLibraryConfig config;
  final ValueChanged<MediaAsset> onTapAsset;
  final ValueChanged<MediaAsset> onPreviewAsset;
  final ValueChanged<MediaAsset>? onToggleSelection;
  final ValueChanged<MediaAsset>? onDeleteAsset;
  final ValueChanged<MediaAsset>? onRevealAssetInFolder;
  final MediaAssetTileBuilder? tileBuilder;
  final MediaAssetMenuBuilder? menuBuilder;
  final MediaAssetSelectionBadgeBuilder? selectionBadgeBuilder;
  final MediaAssetDragFeedbackBuilder? dragFeedbackBuilder;

  const MediaAssetGrid({
    super.key,
    required this.assets,
    required this.selectedAssetIds,
    required this.config,
    required this.onTapAsset,
    required this.onPreviewAsset,
    this.duplicateHighlightTokens = const {},
    this.onToggleSelection,
    this.onDeleteAsset,
    this.onRevealAssetInFolder,
    this.tileBuilder,
    this.menuBuilder,
    this.selectionBadgeBuilder,
    this.dragFeedbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final layout = config.layout;
    final itemHeight =
        layout.tilePreviewHeight + layout.tilePadding.vertical + 8;
    final assetIndexByKey = <Key, int>{
      for (final entry in assets.asMap().entries)
        ValueKey<String>(entry.value.id): entry.key,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : layout.tileWidth;
        final count =
            ((width + layout.itemSpacing) /
                    (layout.tileWidth + layout.itemSpacing))
                .floor();
        final crossAxisCount = count < 1 ? 1 : count;
        final tileExtent =
            (width - layout.itemSpacing * (crossAxisCount - 1)) /
            crossAxisCount;

        return GridView.builder(
          shrinkWrap: config.layout.shrinkWrap,
          physics: config.layout.shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : null,
          findChildIndexCallback: (key) => assetIndexByKey[key],
          padding: const EdgeInsets.only(top: 4, right: 2, bottom: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: itemHeight,
            mainAxisSpacing: layout.itemSpacing,
            crossAxisSpacing: layout.itemSpacing,
          ),
          itemCount: assets.length,
          itemBuilder: (context, index) =>
              _buildAssetTile(context, assets[index], tileExtent),
        );
      },
    );
  }

  Widget _buildAssetTile(
    BuildContext context,
    MediaAsset asset,
    double tileExtent,
  ) {
    final tileKey = ValueKey<String>(asset.id);
    final interaction = config.interaction;
    final state = MediaAssetTileState(
      isBatchSelected: selectedAssetIds.contains(asset.id),
      duplicateHighlightToken: duplicateHighlightTokens[asset.id] ?? 0,
      tileExtent: tileExtent,
      config: config,
    );
    final customTile = tileBuilder?.call(context, asset, state);
    if (customTile != null) {
      final keyedTile = KeyedSubtree(key: tileKey, child: customTile);
      if (!config.interaction.enableAssetDragging) {
        return keyedTile;
      }

      return Draggable<MediaAsset>(
        key: tileKey,
        data: asset,
        feedback: dragFeedbackBuilder?.call(context, asset, state) ?? keyedTile,
        childWhenDragging: keyedTile,
        child: keyedTile,
      );
    }

    return MediaAssetTile(
      key: tileKey,
      asset: asset,
      state: state,
      onTap: () => onTapAsset(asset),
      onDoubleTap: !interaction.isActionEnabled(MediaAssetAction.preview)
          ? null
          : () => onPreviewAsset(asset),
      onToggleSelection:
          onToggleSelection == null ||
              !interaction.isActionEnabled(MediaAssetAction.select)
          ? null
          : () => onToggleSelection!(asset),
      onDelete:
          onDeleteAsset == null ||
              !interaction.isActionEnabled(MediaAssetAction.delete)
          ? null
          : () => onDeleteAsset!(asset),
      onRevealInFolder:
          onRevealAssetInFolder == null ||
              !interaction.isActionEnabled(MediaAssetAction.revealInFolder)
          ? null
          : () => onRevealAssetInFolder!(asset),
      menuBuilder: menuBuilder,
      selectionBadgeBuilder: selectionBadgeBuilder,
      dragFeedbackBuilder: dragFeedbackBuilder,
      enableAssetDragging: config.interaction.enableAssetDragging,
    );
  }
}
