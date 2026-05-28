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
    List<MediaAssetFileCandidate> files,
  ) {
    final accepted = <String>[];
    final rejected = <RejectedMediaFile>[];

    for (final file in files) {
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

      accepted.add(file.path);
    }

    return MediaImportValidationResult(
      acceptedPaths: accepted,
      rejectedFiles: rejected,
    );
  }
}
