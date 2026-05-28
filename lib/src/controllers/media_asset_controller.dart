import 'package:cross_file/cross_file.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../services/media_file_type_service.dart';

typedef MediaAssetImportCallback = Future<void> Function(List<String> paths);
typedef MediaAssetRejectedCallback =
    void Function(List<RejectedMediaFile> files);
typedef MediaAssetActionCallback =
    void Function(MediaAssetAction action, MediaAsset asset);

class MediaAssetLibraryController {
  final MediaAssetLibraryConfig config;
  final MediaAssetImportCallback? onImportFiles;
  final MediaAssetRejectedCallback? onRejectedFiles;
  final MediaAssetActionCallback? onAssetAction;

  const MediaAssetLibraryController({
    required this.config,
    this.onImportFiles,
    this.onRejectedFiles,
    this.onAssetAction,
  });

  Future<MediaImportValidationResult> handleImportFiles(
    List<MediaAssetFileCandidate> files,
  ) async {
    final service = MediaFileTypeService(config.fileTypes);
    final result = service.validateFiles(files);

    if (result.hasRejectedFiles) {
      onRejectedFiles?.call(result.rejectedFiles);
    }
    if (result.hasAcceptedFiles) {
      await onImportFiles?.call(result.acceptedPaths);
    }

    return result;
  }

  Future<MediaImportValidationResult> handleDroppedFiles(
    List<XFile> files,
  ) async {
    final candidates = <MediaAssetFileCandidate>[];
    for (final file in files) {
      candidates.add(
        MediaAssetFileCandidate(
          path: file.path,
          fileSize: await _safeLength(file),
        ),
      );
    }
    return handleImportFiles(candidates);
  }

  void handleAction(MediaAssetAction action, MediaAsset asset) {
    onAssetAction?.call(action, asset);
  }

  Future<int?> _safeLength(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }
}
