import '../models/media_asset_models.dart';

class MediaAssetDuplicateChecker {
  const MediaAssetDuplicateChecker();

  MediaImportValidationResult filterDuplicateFiles({
    required MediaImportValidationResult result,
    required List<MediaAsset> assets,
  }) {
    if (!result.hasAcceptedFiles) {
      return result;
    }

    final existingHashes = <String, List<String>>{};
    for (final asset in assets) {
      final hash = asset.contentHash;
      if (hash != null) {
        existingHashes.putIfAbsent(hash, () => <String>[]).add(asset.id);
      }
    }

    final acceptedFiles = <ValidatedMediaAssetImport>[];
    final duplicatePaths = <String>[];
    final duplicateAssetIds = <String>{};
    final seenHashes = <String>{};

    for (final file in result.acceptedFiles) {
      final hash = file.contentHash;
      if (hash == null) {
        acceptedFiles.add(file);
        continue;
      }

      final existingAssetIds = existingHashes[hash];
      if (existingAssetIds != null || !seenHashes.add(hash)) {
        duplicatePaths.add(file.path);
        if (existingAssetIds != null) {
          duplicateAssetIds.addAll(existingAssetIds);
        }
        continue;
      }

      acceptedFiles.add(file.copyWith(contentHash: hash));
    }

    return MediaImportValidationResult(
      acceptedFiles: acceptedFiles,
      rejectedFiles: result.rejectedFiles,
      duplicatePaths: duplicatePaths,
      duplicateAssetIds: duplicateAssetIds.toList(growable: false),
    );
  }
}
