import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../config/media_asset_config.dart';
import '../controllers/media_asset_action_dispatcher.dart';
import '../controllers/media_asset_controller.dart';
import '../controllers/media_asset_import_controller.dart';
import '../controllers/media_asset_selection_controller.dart';
import '../models/media_asset_models.dart';
import '../services/clipboard_path_service.dart';
import '../services/local_file_picker_service.dart';
import '../services/local_file_reveal_service.dart';
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
  final MediaAssetImportSourceResolver? onResolveImportSources;
  final MediaAssetActionCallback? onAssetAction;
  final MediaAssetActionErrorCallback? onActionError;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<MediaAsset>? onDeleteAsset;
  final ValueChanged<MediaAsset>? onRevealAssetInFolder;
  final MediaAssetBatchCallback? onDeleteSelectedAssets;
  final VoidCallback? onAddPressed;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final MediaAssetTileBuilder? tileBuilder;
  final MediaAssetMenuBuilder? menuBuilder;
  final MediaAssetDragFeedbackBuilder? dragFeedbackBuilder;
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
    this.onResolveImportSources,
    this.onAssetAction,
    this.onActionError,
    this.onSelectionChanged,
    this.onDeleteAsset,
    this.onRevealAssetInFolder,
    this.onDeleteSelectedAssets,
    this.onAddPressed,
    this.loadingBuilder,
    this.emptyBuilder,
    this.tileBuilder,
    this.menuBuilder,
    this.dragFeedbackBuilder,
    this.previewDialogBuilder,
  });

  @override
  State<MediaAssetLibrary> createState() => _MediaAssetLibraryState();
}

class _MediaAssetLibraryState extends State<MediaAssetLibrary> {
  late final MediaAssetSelectionController _selectionController;
  final Map<String, int> _duplicateHighlightTokens = {};

  @override
  void initState() {
    super.initState();
    _selectionController = MediaAssetSelectionController(
      selectedAssetIds: _validSelectedAssetIds(
        widget.selectedAssetIds,
        widget.assets,
      ),
    );
  }

  @override
  void didUpdateWidget(MediaAssetLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldSyncSelection =
        oldWidget.selectedAssetIds != widget.selectedAssetIds ||
        oldWidget.assets != widget.assets;
    if (!shouldSyncSelection) {
      return;
    }

    final incomingSelection =
        oldWidget.selectedAssetIds != widget.selectedAssetIds
        ? widget.selectedAssetIds
        : _selectionController.selectedAssetIds;
    final nextSelection = _validSelectedAssetIds(
      incomingSelection,
      widget.assets,
    );

    if (!_hasSameIds(_selectionController.selectedAssetIds, nextSelection)) {
      _selectionController.replace(nextSelection);
    }

    if (!_hasSameIds(incomingSelection, nextSelection)) {
      _emitSelectionAfterFrame(nextSelection);
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
            assets: orderedAssets,
            onImportFiles: widget.onImportFiles,
            onRejectedFiles: widget.onRejectedFiles,
            onResolveImportSources: widget.onResolveImportSources,
            onAssetAction: widget.onAssetAction,
          );

          final selectedAssets = _selectedAssetsFrom(orderedAssets);
          final onAddPressed =
              widget.onAddPressed ??
              (widget.onImportFiles == null
                  ? null
                  : () => unawaited(
                      _handleAddPressed(context, scopedConfig, controller),
                    ));
          final allSelected =
              orderedAssets.isNotEmpty &&
              _selectionController.selectedAssetIds.length ==
                  orderedAssets.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scopedConfig.layout.showToolbar) ...[
                MediaAssetToolbar(
                  title: widget.title,
                  assetCount: orderedAssets.length,
                  selectedCount: selectedAssets.length,
                  allSelected: allSelected,
                  config: scopedConfig,
                  onAddPressed: onAddPressed,
                  onSelectAll: () => _emitSelection(
                    _selectionController.selectAll(
                      orderedAssets.map((asset) => asset.id),
                    ),
                  ),
                  onClearSelection: () =>
                      _emitSelection(_selectionController.clear()),
                  onDeleteSelected:
                      widget.onDeleteSelectedAssets == null ||
                          !scopedConfig.interaction.isActionEnabled(
                            MediaAssetAction.delete,
                          )
                      ? null
                      : () => widget.onDeleteSelectedAssets!(selectedAssets),
                  onCopySelectedPaths:
                      selectedAssets.isEmpty ||
                          !scopedConfig.interaction.isActionEnabled(
                            MediaAssetAction.copyPath,
                          )
                      ? null
                      : () => _copySelectedAssetPaths(
                          context,
                          controller,
                          selectedAssets,
                        ),
                ),
                const SizedBox(height: 12),
              ],
              _buildLibraryBodyContainer(
                scopedConfig,
                MediaAssetDropZone(
                  config: scopedConfig,
                  enabled:
                      scopedConfig.interaction.enableDragDrop &&
                      widget.onImportFiles != null,
                  hasAssets: orderedAssets.isNotEmpty,
                  onAddPressed: onAddPressed,
                  onFilesDropped: (files) => _handleDroppedFiles(
                    context,
                    scopedConfig,
                    controller,
                    files,
                  ),
                  child: _buildBody(
                    context,
                    scopedConfig,
                    controller,
                    orderedAssets,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLibraryBodyContainer(
    MediaAssetLibraryConfig config,
    Widget child,
  ) {
    final height = config.layout.height;
    if (height != null) {
      return SizedBox(height: height, child: child);
    }

    if (config.layout.shrinkWrap) {
      return child;
    }

    return Expanded(child: child);
  }

  List<MediaAsset> get _orderedAssets {
    final scopedConfig = widget.config ?? MediaAssetLibraryScope.of(context);
    final entries = widget.assets.asMap().entries.toList();
    entries.sort((a, b) {
      final comparison =
          scopedConfig.layout.sortComparator?.call(a.value, b.value) ??
          _compareAssets(a.value, b.value, scopedConfig.layout.sortMode);
      if (comparison != 0) {
        return comparison;
      }
      return a.key.compareTo(b.key);
    });
    return entries.map((entry) => entry.value).toList(growable: false);
  }

  int _compareAssets(MediaAsset a, MediaAsset b, MediaAssetSortMode sortMode) {
    switch (sortMode) {
      case MediaAssetSortMode.manual:
        return 0;
      case MediaAssetSortMode.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
      case MediaAssetSortMode.createdAtAsc:
        return a.createdAt.compareTo(b.createdAt);
      case MediaAssetSortMode.nameAsc:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case MediaAssetSortMode.nameDesc:
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      case MediaAssetSortMode.fileSizeDesc:
        return b.fileSize.compareTo(a.fileSize);
      case MediaAssetSortMode.fileSizeAsc:
        return a.fileSize.compareTo(b.fileSize);
      case MediaAssetSortMode.typeAsc:
        return a.type.index.compareTo(b.type.index);
    }
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
            onAddPressed:
                widget.onAddPressed ??
                (widget.onImportFiles == null
                    ? null
                    : () => unawaited(
                        _handleAddPressed(context, config, controller),
                      )),
          );
    }

    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, child) {
        return MediaAssetGrid(
          assets: orderedAssets,
          selectedAssetIds: _selectionController.selectedAssetIds,
          duplicateHighlightTokens: _duplicateHighlightTokens,
          config: config,
          tileBuilder: widget.tileBuilder,
          menuBuilder: widget.menuBuilder,
          dragFeedbackBuilder: widget.dragFeedbackBuilder,
          onTapAsset: (_) {},
          onPreviewAsset: (asset) {
            controller.handleAction(MediaAssetAction.preview, asset);
            _showPreview(context, asset, config, orderedAssets);
          },
          onToggleSelection:
              config.interaction.enableMultiSelection &&
                  config.interaction.isActionEnabled(MediaAssetAction.select)
              ? (asset) => _emitSelection(_selectionController.toggle(asset.id))
              : null,
          onDeleteAsset: widget.onDeleteAsset == null
              ? null
              : (asset) {
                  controller.handleAction(MediaAssetAction.delete, asset);
                  widget.onDeleteAsset!(asset);
                },
          onRevealAssetInFolder: widget.onRevealAssetInFolder == null
              ? (asset) {
                  controller.handleAction(
                    MediaAssetAction.revealInFolder,
                    asset,
                  );
                  unawaited(
                    const LocalFileRevealService()
                        .reveal(asset.filePath)
                        .catchError((Object error, StackTrace stackTrace) {
                          widget.onActionError?.call(
                            MediaAssetAction.revealInFolder,
                            [asset],
                            error,
                            stackTrace,
                          );
                        }),
                  );
                }
              : (asset) {
                  controller.handleAction(
                    MediaAssetAction.revealInFolder,
                    asset,
                  );
                  widget.onRevealAssetInFolder!(asset);
                },
          onCopyAssetPath: (asset) {
            _copyAssetPath(context, controller, asset);
          },
        );
      },
    );
  }

  void _emitSelection(Set<String> selectedAssetIds) {
    widget.onSelectionChanged?.call(selectedAssetIds);
  }

  void _emitSelectionAfterFrame(Set<String> selectedAssetIds) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onSelectionChanged?.call(selectedAssetIds);
    });
  }

  Set<String> _validSelectedAssetIds(
    Set<String> selectedAssetIds,
    List<MediaAsset> assets,
  ) {
    final assetIds = assets.map((asset) => asset.id).toSet();
    return selectedAssetIds.where(assetIds.contains).toSet();
  }

  bool _hasSameIds(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  Future<void> _handleDroppedFiles(
    BuildContext context,
    MediaAssetLibraryConfig config,
    MediaAssetLibraryController controller,
    List<XFile> files,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await controller.handleDroppedFiles(files);
    if (!mounted || !result.hasDuplicateFiles) {
      return;
    }

    if (result.duplicateAssetIds.isNotEmpty) {
      setState(() {
        for (final assetId in result.duplicateAssetIds) {
          _duplicateHighlightTokens.update(
            assetId,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      });
    }

    if (messenger == null) {
      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            config.text.duplicateImportMessage(
              importedCount: result.acceptedPaths.length,
              duplicateCount: result.duplicatePaths.length,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleAddPressed(
    BuildContext context,
    MediaAssetLibraryConfig config,
    MediaAssetLibraryController controller,
  ) async {
    final files = await const LocalFilePickerService().pickFiles(
      config.importConfig.fileTypes,
    );
    if (files.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    await _handleDroppedFiles(context, config, controller, files);
  }

  void _copyAssetPath(
    BuildContext context,
    MediaAssetLibraryController controller,
    MediaAsset asset,
  ) {
    controller.handleAction(MediaAssetAction.copyPath, asset);
    _copyPathsToClipboard(
      context,
      [asset],
      config: controller.config,
      message: controller.config.text.copyPathSuccessMessage,
    );
  }

  void _copySelectedAssetPaths(
    BuildContext context,
    MediaAssetLibraryController controller,
    List<MediaAsset> assets,
  ) {
    if (assets.isEmpty) {
      return;
    }

    for (final asset in assets) {
      controller.handleAction(MediaAssetAction.copyPath, asset);
    }
    _copyPathsToClipboard(
      context,
      assets,
      config: controller.config,
      message: controller.config.text.copySelectedPathsSuccessMessage(
        assets.length,
      ),
    );
  }

  void _copyPathsToClipboard(
    BuildContext context,
    List<MediaAsset> assets, {
    required MediaAssetLibraryConfig config,
    required String message,
  }) {
    unawaited(
      const ClipboardPathService()
          .copyPaths(assets.map((asset) => asset.filePath))
          .catchError((Object error, StackTrace stackTrace) {
            widget.onActionError?.call(
              MediaAssetAction.copyPath,
              assets,
              error,
              stackTrace,
            );
          }),
    );
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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
