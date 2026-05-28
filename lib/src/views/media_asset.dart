import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../controllers/media_asset_controller.dart';
import '../controllers/media_asset_selection_controller.dart';
import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';
import 'media_asset_drop_zone.dart';
import 'media_asset_grid.dart';
import 'media_asset_preview_dialog.dart';
import 'media_asset_tile.dart';
import 'media_asset_toolbar.dart';

typedef MediaAssetBatchCallback = void Function(List<MediaAsset> assets);
typedef MediaAssetPreviewDialogBuilder =
    Widget Function(
      BuildContext context,
      MediaAsset asset,
      List<MediaAsset> assets,
    );

class MediaAssetLibrary extends StatefulWidget {
  final List<MediaAsset> assets;
  final Set<String> selectedAssetIds;
  final MediaAssetLibraryConfig? config;
  final MediaAssetThemeData? theme;
  final String title;
  final bool isLoading;
  final MediaAssetImportCallback? onImportFiles;
  final MediaAssetRejectedCallback? onRejectedFiles;
  final MediaAssetActionCallback? onAssetAction;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<MediaAsset>? onDeleteAsset;
  final ValueChanged<MediaAsset>? onDownloadAsset;
  final MediaAssetBatchCallback? onDeleteSelectedAssets;
  final MediaAssetBatchCallback? onDownloadSelectedAssets;
  final VoidCallback? onAddPressed;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final MediaAssetTileBuilder? tileBuilder;
  final MediaAssetMenuBuilder? menuBuilder;
  final MediaAssetPreviewDialogBuilder? previewDialogBuilder;

  const MediaAssetLibrary({
    super.key,
    required this.assets,
    this.selectedAssetIds = const {},
    this.config,
    this.theme,
    this.title = '素材库',
    this.isLoading = false,
    this.onImportFiles,
    this.onRejectedFiles,
    this.onAssetAction,
    this.onSelectionChanged,
    this.onDeleteAsset,
    this.onDownloadAsset,
    this.onDeleteSelectedAssets,
    this.onDownloadSelectedAssets,
    this.onAddPressed,
    this.loadingBuilder,
    this.emptyBuilder,
    this.tileBuilder,
    this.menuBuilder,
    this.previewDialogBuilder,
  });

  @override
  State<MediaAssetLibrary> createState() => _MediaAssetLibraryState();
}

class _MediaAssetLibraryState extends State<MediaAssetLibrary> {
  late final MediaAssetSelectionController _selectionController;
  String? _activeAssetId;

  @override
  void initState() {
    super.initState();
    _selectionController = MediaAssetSelectionController(
      selectedAssetIds: widget.selectedAssetIds,
    );
  }

  @override
  void didUpdateWidget(MediaAssetLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAssetIds != widget.selectedAssetIds) {
      _selectionController.replace(widget.selectedAssetIds);
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scopedConfig = widget.config ?? MediaAssetLibraryScope.of(context);
    final libraryTheme = widget.theme ?? MediaAssetTheme.of(context);

    return MediaAssetTheme(
      data: libraryTheme,
      child: Builder(
        builder: (context) {
          final orderedAssets = _orderedAssets;
          final controller = MediaAssetLibraryController(
            config: scopedConfig,
            onImportFiles: widget.onImportFiles,
            onRejectedFiles: widget.onRejectedFiles,
            onAssetAction: widget.onAssetAction,
          );

          final selectedAssets = _selectedAssetsFrom(orderedAssets);
          final allSelected =
              orderedAssets.isNotEmpty &&
              _selectionController.selectedAssetIds.length ==
                  orderedAssets.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scopedConfig.showToolbar) ...[
                MediaAssetToolbar(
                  title: widget.title,
                  assetCount: orderedAssets.length,
                  selectedCount: selectedAssets.length,
                  allSelected: allSelected,
                  config: scopedConfig,
                  onAddPressed: widget.onAddPressed,
                  onSelectAll: () => _emitSelection(
                    _selectionController.selectAll(
                      orderedAssets.map((asset) => asset.id),
                    ),
                  ),
                  onClearSelection: () =>
                      _emitSelection(_selectionController.clear()),
                  onDeleteSelected: widget.onDeleteSelectedAssets == null
                      ? null
                      : () => widget.onDeleteSelectedAssets!(selectedAssets),
                  onDownloadSelected: widget.onDownloadSelectedAssets == null
                      ? null
                      : () => widget.onDownloadSelectedAssets!(selectedAssets),
                ),
                const SizedBox(height: 12),
              ],
              MediaAssetDropZone(
                config: scopedConfig,
                enabled:
                    scopedConfig.enableDragDrop && widget.onImportFiles != null,
                hasAssets: orderedAssets.isNotEmpty,
                onAddPressed: widget.onAddPressed,
                onFilesDropped: controller.handleDroppedFiles,
                child: _buildBody(
                  context,
                  scopedConfig,
                  controller,
                  orderedAssets,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<MediaAsset> get _orderedAssets {
    final entries = widget.assets.asMap().entries.toList();
    entries.sort((a, b) {
      final createdAtComparison = b.value.createdAt.compareTo(
        a.value.createdAt,
      );
      if (createdAtComparison != 0) {
        return createdAtComparison;
      }
      return a.key.compareTo(b.key);
    });
    return entries.map((entry) => entry.value).toList(growable: false);
  }

  List<MediaAsset> _selectedAssetsFrom(List<MediaAsset> assets) {
    final selectedIds = _selectionController.selectedAssetIds;
    return assets
        .where((asset) => selectedIds.contains(asset.id))
        .toList(growable: false);
  }

  Widget _buildBody(
    BuildContext context,
    MediaAssetLibraryConfig config,
    MediaAssetLibraryController controller,
    List<MediaAsset> orderedAssets,
  ) {
    if (widget.isLoading) {
      return widget.loadingBuilder?.call(context) ?? const _DefaultLoading();
    }

    if (orderedAssets.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          MediaAssetEmptyDropZone(
            config: config,
            isActive: false,
            onAddPressed: widget.onAddPressed,
          );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 2, bottom: 12),
        child: AnimatedBuilder(
          animation: _selectionController,
          builder: (context, child) {
            return MediaAssetGrid(
              assets: orderedAssets,
              selectedAssetIds: _selectionController.selectedAssetIds,
              activeAssetId: _activeAssetId,
              config: config,
              tileBuilder: widget.tileBuilder,
              menuBuilder: widget.menuBuilder,
              onTapAsset: (asset) {
                setState(() => _activeAssetId = asset.id);
              },
              onPreviewAsset: (asset) {
                controller.handleAction(MediaAssetAction.preview, asset);
                _showPreview(context, asset, config, orderedAssets);
              },
              onToggleSelection: config.enableMultiSelection
                  ? (asset) =>
                        _emitSelection(_selectionController.toggle(asset.id))
                  : null,
              onDeleteAsset: widget.onDeleteAsset == null
                  ? null
                  : (asset) {
                      controller.handleAction(MediaAssetAction.delete, asset);
                      widget.onDeleteAsset!(asset);
                    },
              onDownloadAsset: widget.onDownloadAsset == null
                  ? null
                  : (asset) {
                      controller.handleAction(MediaAssetAction.download, asset);
                      widget.onDownloadAsset!(asset);
                    },
            );
          },
        ),
      ),
    );
  }

  void _emitSelection(Set<String> selectedAssetIds) {
    widget.onSelectionChanged?.call(selectedAssetIds);
  }

  Future<void> _showPreview(
    BuildContext context,
    MediaAsset asset,
    MediaAssetLibraryConfig config,
    List<MediaAsset> orderedAssets,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return widget.previewDialogBuilder?.call(
              context,
              asset,
              orderedAssets,
            ) ??
            MediaAssetPreviewDialog(
              asset: asset,
              assets: orderedAssets,
              config: config,
            );
      },
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}
