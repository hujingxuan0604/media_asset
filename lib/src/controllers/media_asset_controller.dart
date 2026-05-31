import 'package:cross_file/cross_file.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import 'media_asset_action_dispatcher.dart';
import 'media_asset_import_controller.dart';

class MediaAssetLibraryController {
  final MediaAssetLibraryConfig config;
  final List<MediaAsset> assets;
  final MediaAssetImportCallback? onImportFiles;
  final MediaAssetRejectedCallback? onRejectedFiles;
  final MediaAssetImportSourceResolver? onResolveImportSources;
  final MediaAssetActionCallback? onAssetAction;

  const MediaAssetLibraryController({
    required this.config,
    this.assets = const [],
    this.onImportFiles,
    this.onRejectedFiles,
    this.onResolveImportSources,
    this.onAssetAction,
  });

  Future<MediaImportValidationResult> handleImportFiles(
    List<LocalMediaImportSource> files,
  ) async {
    return MediaAssetImportController(
      config: config,
      assets: assets,
      onImportFiles: onImportFiles,
      onRejectedFiles: onRejectedFiles,
      onResolveImportSources: onResolveImportSources,
    ).handleImportFiles(files);
  }

  Future<MediaImportValidationResult> handleDroppedFiles(
    List<XFile> files,
  ) async {
    return MediaAssetImportController(
      config: config,
      assets: assets,
      onImportFiles: onImportFiles,
      onRejectedFiles: onRejectedFiles,
      onResolveImportSources: onResolveImportSources,
    ).handleDroppedFiles(files);
  }

  void handleAction(MediaAssetAction action, MediaAsset asset) {
    MediaAssetActionDispatcher(
      onAssetAction: onAssetAction,
    ).dispatch(action, asset);
  }
}
