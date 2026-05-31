import 'dart:io';

import 'package:cross_file/cross_file.dart';

import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';
import '../services/media_file_type_service.dart';
import 'media_asset_duplicate_checker.dart';

typedef MediaAssetImportCallback =
    Future<void> Function(List<ValidatedMediaAssetImport> files);
typedef MediaAssetRejectedCallback =
    void Function(List<RejectedMediaFile> files);
typedef MediaAssetImportSourceResolver =
    Future<List<LocalMediaImportSource>> Function(
      List<LocalMediaImportSource> files,
    );

class MediaAssetImportController {
  final MediaAssetLibraryConfig config;
  final List<MediaAsset> assets;
  final MediaAssetImportCallback? onImportFiles;
  final MediaAssetRejectedCallback? onRejectedFiles;
  final MediaAssetImportSourceResolver? onResolveImportSources;
  final MediaAssetDuplicateChecker duplicateChecker;

  const MediaAssetImportController({
    required this.config,
    this.assets = const [],
    this.onImportFiles,
    this.onRejectedFiles,
    this.onResolveImportSources,
    this.duplicateChecker = const MediaAssetDuplicateChecker(),
  });

  Future<MediaImportValidationResult> handleImportFiles(
    List<LocalMediaImportSource> files,
  ) async {
    final resolvedFiles = await onResolveImportSources?.call(files) ?? files;
    final service = MediaFileTypeService(config.importConfig.fileTypes);
    final validatedResult = service.validateFiles(resolvedFiles);
    final result = config.importConfig.preventDuplicateImport
        ? duplicateChecker.filterDuplicateFiles(
            result: validatedResult,
            assets: assets,
          )
        : validatedResult;

    if (result.hasRejectedFiles) {
      onRejectedFiles?.call(result.rejectedFiles);
    }
    if (result.hasAcceptedFiles) {
      await onImportFiles?.call(result.acceptedFiles);
    }

    return result;
  }

  Future<MediaImportValidationResult> handleDroppedFiles(
    List<XFile> files,
  ) async {
    final sources = <LocalMediaImportSource>[];
    for (final file in files) {
      sources.add(await _sourceForXFile(file));
    }
    return handleImportFiles(sources);
  }

  Future<LocalMediaImportSource> _sourceForXFile(XFile file) async {
    final exists = File(file.path).existsSync();
    final fileSize = await _safeLength(file);
    return LocalMediaImportSource(
      path: file.path,
      fileSize: fileSize,
      exists: exists,
      isReadable: exists && fileSize != null,
    );
  }

  Future<int?> _safeLength(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }
}
