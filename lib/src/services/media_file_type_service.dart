import '../config/media_asset_config.dart';
import '../models/media_asset_models.dart';

class MediaFileTypeService {
  final MediaAssetFileTypeConfig config;

  const MediaFileTypeService(this.config);

  MediaAssetType? typeForPath(String path) {
    final extension = extensionOf(path);
    if (config.imageExtensions.contains(extension)) {
      return MediaAssetType.image;
    }
    if (config.videoExtensions.contains(extension)) {
      return MediaAssetType.video;
    }
    return null;
  }

  String extensionOf(String path) {
    final normalized = path.split(RegExp(r'[/\\]')).last;
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == normalized.length - 1) {
      return '';
    }
    return normalized.substring(dotIndex + 1).toLowerCase();
  }

  MediaImportValidationResult validateFiles(
    List<LocalMediaImportSource> files,
  ) {
    final accepted = <ValidatedMediaAssetImport>[];
    final rejected = <RejectedMediaFile>[];

    for (final file in files) {
      if (!file.exists) {
        rejected.add(
          RejectedMediaFile(
            path: file.path,
            reason: RejectedMediaFileReason.missing,
          ),
        );
        continue;
      }

      if (!file.isReadable) {
        rejected.add(
          RejectedMediaFile(
            path: file.path,
            reason: RejectedMediaFileReason.unreadable,
          ),
        );
        continue;
      }

      if (file.fileSize == 0) {
        rejected.add(
          RejectedMediaFile(
            path: file.path,
            reason: RejectedMediaFileReason.emptyFile,
          ),
        );
        continue;
      }

      final type = typeForPath(file.path);
      if (type == null) {
        rejected.add(
          RejectedMediaFile(
            path: file.path,
            reason: RejectedMediaFileReason.unsupportedType,
          ),
        );
        continue;
      }

      final fileSize = file.fileSize;
      if (fileSize != null) {
        final imageLimit = config.maxImageFileSize;
        final videoLimit = config.maxVideoFileSize;
        if (type == MediaAssetType.image &&
            imageLimit != null &&
            fileSize > imageLimit) {
          rejected.add(
            RejectedMediaFile(
              path: file.path,
              reason: RejectedMediaFileReason.imageTooLarge,
            ),
          );
          continue;
        }
        if (type == MediaAssetType.video &&
            videoLimit != null &&
            fileSize > videoLimit) {
          rejected.add(
            RejectedMediaFile(
              path: file.path,
              reason: RejectedMediaFileReason.videoTooLarge,
            ),
          );
          continue;
        }
      }

      accepted.add(
        ValidatedMediaAssetImport(
          path: file.path,
          name: fileNameOf(file.path),
          type: type,
          fileSize: file.fileSize ?? 0,
          contentHash: file.contentHash,
        ),
      );
    }

    return MediaImportValidationResult(
      acceptedFiles: accepted,
      rejectedFiles: rejected,
    );
  }

  String fileNameOf(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }
}
