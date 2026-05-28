import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import 'media_asset_tile.dart';

class MediaAssetGrid extends StatelessWidget {
  final List<MediaAsset> assets;
  final Set<String> selectedAssetIds;
  final String? activeAssetId;
  final MediaAssetLibraryConfig config;
  final ValueChanged<MediaAsset> onTapAsset;
  final ValueChanged<MediaAsset> onPreviewAsset;
  final ValueChanged<MediaAsset>? onToggleSelection;
  final ValueChanged<MediaAsset>? onDeleteAsset;
  final ValueChanged<MediaAsset>? onDownloadAsset;
  final MediaAssetTileBuilder? tileBuilder;
  final MediaAssetMenuBuilder? menuBuilder;

  const MediaAssetGrid({
    super.key,
    required this.assets,
    required this.selectedAssetIds,
    required this.config,
    required this.onTapAsset,
    required this.onPreviewAsset,
    this.activeAssetId,
    this.onToggleSelection,
    this.onDeleteAsset,
    this.onDownloadAsset,
    this.tileBuilder,
    this.menuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: config.gridSpacing,
        runSpacing: config.gridSpacing,
        children: assets.map((asset) {
          final state = MediaAssetTileState(
            isSelected: activeAssetId == asset.id,
            isBatchSelected: selectedAssetIds.contains(asset.id),
            config: config,
          );
          final customTile = tileBuilder?.call(context, asset, state);
          if (customTile != null) {
            return customTile;
          }

          return MediaAssetTile(
            asset: asset,
            state: state,
            onTap: () => onTapAsset(asset),
            onDoubleTap: () => onPreviewAsset(asset),
            onToggleSelection: onToggleSelection == null
                ? null
                : () => onToggleSelection!(asset),
            onDelete: onDeleteAsset == null
                ? null
                : () => onDeleteAsset!(asset),
            onDownload: onDownloadAsset == null
                ? null
                : () => onDownloadAsset!(asset),
            menuBuilder: menuBuilder,
          );
        }).toList(),
      ),
    );
  }
}
